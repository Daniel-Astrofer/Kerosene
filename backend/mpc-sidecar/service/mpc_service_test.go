package service

import (
	"context"
	"crypto/ed25519"
	"crypto/sha256"
	"encoding/base64"
	"strings"
	"sync"
	"testing"

	pb "mpc-sidecar/proto"
)

func TestMpcKeygenAndSign(t *testing.T) {
	configureTestEnclave(t)
	service := &MpcService{}

	keygen, err := service.Keygen(context.Background(), &pb.KeygenRequest{
		UserId:       "platform-user-42",
		Threshold:    2,
		TotalParties: 3,
	})
	if err != nil {
		t.Fatalf("keygen returned transport error: %v", err)
	}
	if !keygen.Success {
		t.Fatalf("keygen failed: %s", keygen.ErrorMessage)
	}
	if keygen.PublicKey == "" {
		t.Fatal("keygen returned empty public key")
	}

	messageHash := sha256.Sum256([]byte("authorize transaction"))
	sign, err := service.Sign(context.Background(), &pb.SignRequest{
		UserId:      "platform-user-42",
		MessageHash: messageHash[:],
		PublicKey:   keygen.PublicKey,
	})
	if err != nil {
		t.Fatalf("sign returned transport error: %v", err)
	}
	if !sign.Success {
		t.Fatalf("sign failed: %s", sign.ErrorMessage)
	}
	if len(sign.Signature) != ed25519.SignatureSize {
		t.Fatalf("signature length = %d, want %d", len(sign.Signature), ed25519.SignatureSize)
	}

	publicKey, err := base64.StdEncoding.DecodeString(keygen.PublicKey)
	if err != nil {
		t.Fatalf("public key is not valid base64: %v", err)
	}
	if !ed25519.Verify(ed25519.PublicKey(publicKey), messageHash[:], sign.Signature) {
		t.Fatal("signature did not verify against returned public key")
	}
}

func TestMpcSignRejectsWrongPublicKey(t *testing.T) {
	configureTestEnclave(t)
	service := &MpcService{}

	keygen, err := service.Keygen(context.Background(), &pb.KeygenRequest{
		UserId:       "platform-user-99",
		Threshold:    2,
		TotalParties: 3,
	})
	if err != nil || !keygen.Success {
		t.Fatalf("keygen failed: response=%v error=%v", keygen, err)
	}

	messageHash := sha256.Sum256([]byte("authorize transaction"))
	sign, err := service.Sign(context.Background(), &pb.SignRequest{
		UserId:      "platform-user-99",
		MessageHash: messageHash[:],
		PublicKey:   base64.StdEncoding.EncodeToString([]byte("wrong-public-key")),
	})
	if err != nil {
		t.Fatalf("sign returned transport error: %v", err)
	}
	if sign.Success {
		t.Fatal("sign succeeded with wrong public key")
	}
}

func TestMpcThresholdModeFailsClosed(t *testing.T) {
	configureTestEnclave(t)
	t.Setenv("MPC_RUNTIME_MODE", RuntimeModeThresholdMPC)
	service := &MpcService{}

	keygen, err := service.Keygen(context.Background(), &pb.KeygenRequest{
		UserId:       "platform-user-threshold",
		Threshold:    2,
		TotalParties: 3,
	})
	if err != nil {
		t.Fatalf("keygen returned transport error: %v", err)
	}
	if keygen.Success || !strings.Contains(keygen.ErrorMessage, "not implemented") {
		t.Fatalf("keygen response = %+v, want fail-closed not implemented error", keygen)
	}

	messageHash := sha256.Sum256([]byte("authorize transaction"))
	sign, err := service.Sign(context.Background(), &pb.SignRequest{
		UserId:      "platform-user-threshold",
		MessageHash: messageHash[:],
	})
	if err != nil {
		t.Fatalf("sign returned transport error: %v", err)
	}
	if sign.Success || !strings.Contains(sign.ErrorMessage, "not implemented") {
		t.Fatalf("sign response = %+v, want fail-closed not implemented error", sign)
	}
}

func TestMpcRequestsRejectNilWithoutPanic(t *testing.T) {
	service := &MpcService{}

	keygen, err := service.Keygen(context.Background(), nil)
	if err != nil {
		t.Fatalf("keygen returned transport error: %v", err)
	}
	if keygen.Success || keygen.ErrorMessage == "" {
		t.Fatalf("keygen nil request response = %+v, want validation failure", keygen)
	}

	sign, err := service.Sign(context.Background(), nil)
	if err != nil {
		t.Fatalf("sign returned transport error: %v", err)
	}
	if sign.Success || sign.ErrorMessage == "" {
		t.Fatalf("sign nil request response = %+v, want validation failure", sign)
	}
}

func TestShardNameForUserIDDoesNotExposeOrCollapseUserIDs(t *testing.T) {
	userID := "alice@example.com"
	shardName := shardNameForUserID(userID)

	if !strings.HasPrefix(shardName, "user_") {
		t.Fatalf("shard name %q does not use the hashed user prefix", shardName)
	}
	if strings.Contains(shardName, "alice") || strings.Contains(shardName, "example") {
		t.Fatalf("shard name %q exposes the user id", shardName)
	}
	if shardName != shardNameForUserID("  "+userID+"  ") {
		t.Fatal("shard names must remain stable across leading/trailing whitespace")
	}
	if shardNameForUserID("alice/bob") == shardNameForUserID("alice_bob") {
		t.Fatal("hashed shard names must not collapse sanitized user id collisions")
	}
}

func configureTestEnclave(t *testing.T) {
	t.Helper()
	resetMasterKeyForTest()

	t.Setenv("MPC_PERSISTENT_STORAGE_DIR", t.TempDir())
	t.Setenv("MPC_RAM_DISK_DIR", t.TempDir())
	t.Setenv("MPC_REQUIRE_MASTER_KEY", "true")
	t.Setenv("MPC_MASTER_KEY_B64", base64.StdEncoding.EncodeToString(bytesOf(32, 7)))
	t.Setenv("MPC_RUNTIME_MODE", RuntimeModeLocalDevSigner)

	if err := InitSecureEnclave(); err != nil {
		t.Fatalf("InitSecureEnclave failed: %v", err)
	}
}

func resetMasterKeyForTest() {
	if masterKey != nil {
		zeroBytes(masterKey)
	}
	masterKey = nil
	masterKeyErr = nil
	masterKeyOnce = sync.Once{}
}

func bytesOf(length int, value byte) []byte {
	out := make([]byte, length)
	for i := range out {
		out[i] = value
	}
	return out
}

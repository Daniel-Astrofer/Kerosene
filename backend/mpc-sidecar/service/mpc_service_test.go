package service

import (
	"context"
	"crypto/ed25519"
	"crypto/sha256"
	"encoding/base64"
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

func configureTestEnclave(t *testing.T) {
	t.Helper()
	resetMasterKeyForTest()

	t.Setenv("MPC_PERSISTENT_STORAGE_DIR", t.TempDir())
	t.Setenv("MPC_RAM_DISK_DIR", t.TempDir())
	t.Setenv("MPC_REQUIRE_MASTER_KEY", "true")
	t.Setenv("MPC_MASTER_KEY_B64", base64.StdEncoding.EncodeToString(bytesOf(32, 7)))

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

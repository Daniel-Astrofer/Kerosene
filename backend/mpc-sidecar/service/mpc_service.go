package service

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"regexp"
	"strings"
	"time"

	pb "mpc-sidecar/proto"
)

type MpcService struct {
	pb.UnimplementedMpcServiceServer
}

const (
	RuntimeModeLocalDevSigner = "LOCAL_DEV_SIGNER"
	RuntimeModeThresholdMPC   = "THRESHOLD_MPC"
	RuntimeModeProductionMPC  = "PRODUCTION_MPC"

	maxUserIDLength = 256
)

func (s *MpcService) Keygen(_ context.Context, req *pb.KeygenRequest) (*pb.KeygenResponse, error) {
	if err := validateKeygenRequest(req); err != nil {
		return &pb.KeygenResponse{Success: false, ErrorMessage: err.Error()}, nil
	}
	if err := requireLocalDevSigner(); err != nil {
		return &pb.KeygenResponse{Success: false, ErrorMessage: err.Error()}, nil
	}

	userID := normalizedUserID(req.UserId)
	log.Printf("[MPC] Starting local dev signer Keygen for user fingerprint %s (%d/%d)", userFingerprint(userID), req.Threshold, req.TotalParties)

	shardName := shardNameForUserID(userID)
	if existing, existingShardName, err := loadStoredKeyForUser(userID); err == nil {
		return &pb.KeygenResponse{
			PublicKey: existing.PublicKeyB64,
			ShareId:   []byte(existingShardName),
			Success:   true,
		}, nil
	}

	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return &pb.KeygenResponse{Success: false, ErrorMessage: fmt.Sprintf("failed to generate enclave key: %v", err)}, nil
	}
	defer zeroBytes(privateKey)

	stored := storedKeyShare{
		Version:       1,
		UserID:        userID,
		PublicKeyB64:  base64.StdEncoding.EncodeToString(publicKey),
		PrivateKeyB64: base64.StdEncoding.EncodeToString(privateKey),
		Threshold:     req.Threshold,
		TotalParties:  req.TotalParties,
		CreatedAtUTC:  time.Now().UTC().Format(time.RFC3339),
	}
	plaintext, err := json.Marshal(stored)
	if err != nil {
		return &pb.KeygenResponse{Success: false, ErrorMessage: fmt.Sprintf("failed to encode key share: %v", err)}, nil
	}
	defer zeroBytes(plaintext)

	if err := SaveEncryptedShard(shardName, plaintext); err != nil {
		return &pb.KeygenResponse{Success: false, ErrorMessage: fmt.Sprintf("failed to persist encrypted key share: %v", err)}, nil
	}

	log.Printf("[MPC] Enclave key share ready for user fingerprint %s", userFingerprint(userID))
	return &pb.KeygenResponse{
		PublicKey: stored.PublicKeyB64,
		ShareId:   []byte(shardName),
		Success:   true,
	}, nil
}

func (s *MpcService) Sign(_ context.Context, req *pb.SignRequest) (*pb.SignResponse, error) {
	if err := validateSignRequest(req); err != nil {
		return &pb.SignResponse{Success: false, ErrorMessage: err.Error()}, nil
	}
	if err := requireLocalDevSigner(); err != nil {
		return &pb.SignResponse{Success: false, ErrorMessage: err.Error()}, nil
	}

	userID := normalizedUserID(req.UserId)
	log.Printf("[MPC] Starting local dev signer Signing for hash length %d requested by user fingerprint %s", len(req.MessageHash), userFingerprint(userID))

	_, shardData, stored, err := loadStoredKeyDataForUser(userID)
	if err != nil {
		log.Printf("[MPC] Critical Security Failure: Shard for user fingerprint %s not found in volatile RAM! Has the server rebooted or lost power?", userFingerprint(userID))
		return &pb.SignResponse{Success: false, ErrorMessage: fmt.Sprintf("failed to read shard from memory: %v", err)}, nil
	}
	defer zeroBytes(shardData)

	log.Printf("[MPC] Successfully read shard (%d bytes) from volatile RAM (tmpfs) for user fingerprint %s. Continuing with MPC Signing...", len(shardData), userFingerprint(userID))

	if req.PublicKey != "" && req.PublicKey != stored.PublicKeyB64 {
		return &pb.SignResponse{Success: false, ErrorMessage: "public key does not match stored enclave key"}, nil
	}

	privateKeyBytes, err := base64.StdEncoding.DecodeString(stored.PrivateKeyB64)
	if err != nil {
		return &pb.SignResponse{Success: false, ErrorMessage: fmt.Sprintf("stored key share is invalid: %v", err)}, nil
	}
	defer zeroBytes(privateKeyBytes)
	if len(privateKeyBytes) != ed25519.PrivateKeySize {
		return &pb.SignResponse{Success: false, ErrorMessage: fmt.Sprintf("stored private key has invalid length %d", len(privateKeyBytes))}, nil
	}

	signature := ed25519.Sign(ed25519.PrivateKey(privateKeyBytes), req.MessageHash)
	return &pb.SignResponse{Signature: signature, Success: true}, nil
}

type storedKeyShare struct {
	Version       int    `json:"version"`
	UserID        string `json:"user_id"`
	PublicKeyB64  string `json:"public_key_b64"`
	PrivateKeyB64 string `json:"private_key_b64"`
	Threshold     int32  `json:"threshold"`
	TotalParties  int32  `json:"total_parties"`
	CreatedAtUTC  string `json:"created_at_utc"`
}

func loadStoredKeyForUser(userID string) (*storedKeyShare, string, error) {
	shardName, shardData, stored, err := loadStoredKeyDataForUser(userID)
	if err != nil {
		return nil, "", err
	}
	defer zeroBytes(shardData)
	return stored, shardName, nil
}

func loadStoredKeyDataForUser(userID string) (string, []byte, *storedKeyShare, error) {
	for _, shardName := range shardNameCandidates(userID) {
		shardData, err := GetShardFromRam(shardName)
		if err != nil {
			continue
		}

		stored, err := decodeStoredKey(shardData)
		if err != nil {
			zeroBytes(shardData)
			return shardName, nil, nil, err
		}

		if normalizedUserID(stored.UserID) != userID {
			zeroBytes(shardData)
			return shardName, nil, nil, fmt.Errorf("stored key share owner does not match requested user")
		}

		return shardName, shardData, stored, nil
	}
	return "", nil, nil, fmt.Errorf("stored key share for user fingerprint %s was not found", userFingerprint(userID))
}

func decodeStoredKey(shardData []byte) (*storedKeyShare, error) {
	var stored storedKeyShare
	if err := json.Unmarshal(shardData, &stored); err != nil {
		return nil, fmt.Errorf("failed to decode stored key share: %v", err)
	}
	if stored.Version != 1 || stored.PublicKeyB64 == "" || stored.PrivateKeyB64 == "" {
		return nil, fmt.Errorf("stored key share is incomplete")
	}
	return &stored, nil
}

func validateKeygenRequest(req *pb.KeygenRequest) error {
	if req == nil {
		return fmt.Errorf("keygen request is required")
	}
	if strings.TrimSpace(req.UserId) == "" {
		return fmt.Errorf("user_id is required")
	}
	if len(normalizedUserID(req.UserId)) > maxUserIDLength {
		return fmt.Errorf("user_id must be at most %d bytes", maxUserIDLength)
	}
	if req.TotalParties < 1 || req.Threshold < 1 || req.Threshold > req.TotalParties {
		return fmt.Errorf("invalid threshold parameters")
	}
	return nil
}

func validateSignRequest(req *pb.SignRequest) error {
	if req == nil {
		return fmt.Errorf("sign request is required")
	}
	if strings.TrimSpace(req.UserId) == "" {
		return fmt.Errorf("user_id is required")
	}
	if len(normalizedUserID(req.UserId)) > maxUserIDLength {
		return fmt.Errorf("user_id must be at most %d bytes", maxUserIDLength)
	}
	if len(req.MessageHash) != 32 {
		return fmt.Errorf("message_hash must be exactly 32 bytes")
	}
	return nil
}

func RuntimeMode() string {
	mode := strings.ToUpper(strings.TrimSpace(os.Getenv("MPC_RUNTIME_MODE")))
	if mode == "" {
		return RuntimeModeLocalDevSigner
	}
	return mode
}

func requireLocalDevSigner() error {
	switch RuntimeMode() {
	case RuntimeModeLocalDevSigner:
		return nil
	case RuntimeModeThresholdMPC, RuntimeModeProductionMPC:
		return fmt.Errorf("MPC_RUNTIME_MODE=%s is not implemented; refusing to use local Ed25519 signer", RuntimeMode())
	default:
		return fmt.Errorf("unsupported MPC_RUNTIME_MODE=%s; supported mode is %s", RuntimeMode(), RuntimeModeLocalDevSigner)
	}
}

var unsafeShardNameChars = regexp.MustCompile(`[^a-zA-Z0-9_.-]`)

func shardNameForUserID(userID string) string {
	digest := sha256.Sum256([]byte(normalizedUserID(userID)))
	return "user_" + hex.EncodeToString(digest[:])
}

func shardNameCandidates(userID string) []string {
	current := shardNameForUserID(userID)
	legacy := legacyShardName(userID)
	if legacy == current {
		return []string{current}
	}
	return []string{current, legacy}
}

func legacyShardName(userID string) string {
	trimmed := normalizedUserID(userID)
	safe := unsafeShardNameChars.ReplaceAllString(trimmed, "_")
	if safe == "" {
		return "unknown"
	}
	return safe
}

func normalizedUserID(userID string) string {
	return strings.TrimSpace(userID)
}

func userFingerprint(userID string) string {
	digest := sha256.Sum256([]byte(normalizedUserID(userID)))
	return hex.EncodeToString(digest[:8])
}

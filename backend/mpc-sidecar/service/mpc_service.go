package service

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"

	pb "mpc-sidecar/proto"
)

type MpcService struct {
	pb.UnimplementedMpcServiceServer
}

func (s *MpcService) Keygen(ctx context.Context, req *pb.KeygenRequest) (*pb.KeygenResponse, error) {
	log.Printf("[MPC] Starting Keygen for user %s (%d/%d)", req.UserId, req.Threshold, req.TotalParties)

	if err := validateKeygenRequest(req); err != nil {
		return &pb.KeygenResponse{Success: false, ErrorMessage: err.Error()}, nil
	}

	shardName := safeShardName(req.UserId)
	if existing, err := loadStoredKey(shardName); err == nil {
		return &pb.KeygenResponse{
			PublicKey: existing.PublicKeyB64,
			ShareId:   []byte(shardName),
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
		UserID:        req.UserId,
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

	log.Printf("[MPC] Enclave key share ready for user %s", req.UserId)
	return &pb.KeygenResponse{
		PublicKey: stored.PublicKeyB64,
		ShareId:   []byte(shardName),
		Success:   true,
	}, nil
}

func (s *MpcService) Sign(ctx context.Context, req *pb.SignRequest) (*pb.SignResponse, error) {
	log.Printf("[MPC] Starting Signing for hash %x requested by user %s", req.MessageHash, req.UserId)

	if err := validateSignRequest(req); err != nil {
		return &pb.SignResponse{Success: false, ErrorMessage: err.Error()}, nil
	}

	shardName := safeShardName(req.UserId)
	shardData, err := GetShardFromRam(shardName)
	if err != nil {
		log.Printf("[MPC] Critical Security Failure: Shard for user %s not found in volatile RAM! Has the server rebooted or lost power?", req.UserId)
		return &pb.SignResponse{Success: false, ErrorMessage: fmt.Sprintf("failed to read shard from memory: %v", err)}, nil
	}
	defer zeroBytes(shardData)

	stored, err := decodeStoredKey(shardData)
	if err != nil {
		return &pb.SignResponse{Success: false, ErrorMessage: err.Error()}, nil
	}

	log.Printf("[MPC] Successfully read shard (%d bytes) from volatile RAM (tmpfs) for user %s. Continuing with MPC Signing...", len(shardData), req.UserId)

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

func loadStoredKey(shardName string) (*storedKeyShare, error) {
	shardData, err := GetShardFromRam(shardName)
	if err != nil {
		return nil, err
	}
	defer zeroBytes(shardData)
	return decodeStoredKey(shardData)
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
	if len(req.MessageHash) != 32 {
		return fmt.Errorf("message_hash must be exactly 32 bytes")
	}
	return nil
}

var unsafeShardNameChars = regexp.MustCompile(`[^a-zA-Z0-9_.-]`)

func safeShardName(userID string) string {
	trimmed := strings.TrimSpace(userID)
	safe := unsafeShardNameChars.ReplaceAllString(trimmed, "_")
	if safe == "" {
		return "unknown"
	}
	return safe
}

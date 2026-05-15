package service

import (
	"context"
	"fmt"
	"log"

	pb "mpc-sidecar/proto"
)

type MpcService struct {
	pb.UnimplementedMpcServiceServer
}

func (s *MpcService) Keygen(ctx context.Context, req *pb.KeygenRequest) (*pb.KeygenResponse, error) {
	log.Printf("[MPC] Starting Keygen for user %s (%d/%d)", req.UserId, req.Threshold, req.TotalParties)

	// In a real scenario, this would involve P2P communication between nodes.
	// For this sidecar implementation, we initialize the local share parameters.
	
	// Pre-params are heavy to compute, usually cached.
	// _, err := keygen.GeneratePreParams(1 * 60) // 1 minute timeout
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to generate pre-params: %v", err)
	// }

	// This is a simplified placeholder. Real TSS requires a round-based state machine.
	log.Printf("[MPC] Keygen requested for %s", req.UserId)

	// In real use case, this payload is the generated Local_Share structure.
	localShareData := []byte(`{"mock":"this_is_the_sensitive_shard_bytes"}`)
	
	err := SaveEncryptedShard(req.UserId, localShareData)
	if err != nil {
		return nil, fmt.Errorf("failed to save generated shard to secure enclave: %v", err)
	}

	return &pb.KeygenResponse{
		Success:      true,
		PublicKey:    "EXT_PUB_KEY_GENERATED_BY_TSS",
		ShareId:      []byte(req.UserId), // Use UserId as metadata/filename
		ErrorMessage: "",
	}, nil
}

func (s *MpcService) Sign(ctx context.Context, req *pb.SignRequest) (*pb.SignResponse, error) {
	log.Printf("[MPC] Starting Signing for hash %x requested by user %s", req.MessageHash, req.UserId)

	// Threshold signing logic using tss-lib.
	// Requires the local share data from volatile RAM storage.
	
	shardData, err := GetShardFromRam(req.UserId)
	if err != nil {
		log.Printf("[MPC] Critical Security Failure: Shard for user %s not found in volatile RAM! Has the server rebooted or lost power?", req.UserId)
		return nil, fmt.Errorf("failed to read shard from memory: %v", err)
	}

	log.Printf("[MPC] Successfully read shard (%d bytes) from volatile RAM (tmpfs) for user %s. Continuing with MPC Signing...", len(shardData), req.UserId)

	// Feed shardData into the TSS round routines here...

	return &pb.SignResponse{
		Success:      true,
		Signature:    append([]byte("R_VALUE"), []byte("S_VALUE")...),
		ErrorMessage: "",
	}, nil
}

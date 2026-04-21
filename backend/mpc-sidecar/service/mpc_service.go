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

	return nil, fmt.Errorf("threshold keygen is not wired to a round-based TSS coordinator yet")
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

	return nil, fmt.Errorf("threshold signing is not wired to a round-based TSS coordinator yet")
}

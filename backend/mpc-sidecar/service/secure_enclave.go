package service

import (
	"crypto/aes"
	"crypto/cipher"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
)

const (
	// Permanent encrypted storage on disk
	PersistentStorageDir = "/app/encrypted-shards"
	
	// Volatile RAM disk (tmpfs) mapped in docker-compose
	RamDiskDir = "/mnt/mpc-shards"
)

// In a real SGX/TEE setup, this key is provisioned internally and 
// NEVER leaves the enclave memory. We mock it here for the sidecar.
var mockSgxMasterKey = []byte("my_32_byte_super_secure_sgx_key!")

// InitSecureEnclave simulates the Secure Boot / TEE unlocking process.
// It decrypts the shards from persistent storage and writes them to the RAM disk.
func InitSecureEnclave() error {
	log.Println("[ENCLAVE] Starting Secure Boot / SGX Simulation...")

	// Verify if RAM disk exists
	if _, err := os.Stat(RamDiskDir); os.IsNotExist(err) {
		log.Printf("[ENCLAVE] Warning: %s does not exist. Creating local dir, but it MUST be tmpfs in production.", RamDiskDir)
		os.MkdirAll(RamDiskDir, 0700)
	}

	// Verify persistent storage
	if _, err := os.Stat(PersistentStorageDir); os.IsNotExist(err) {
		log.Printf("[ENCLAVE] No existing encrypted shards found at %s. Creating directory.", PersistentStorageDir)
		os.MkdirAll(PersistentStorageDir, 0700)
		return nil // Nothing to decrypt yet
	}

	files, err := ioutil.ReadDir(PersistentStorageDir)
	if err != nil {
		return fmt.Errorf("failed to read persistent storage: %v", err)
	}

	for _, f := range files {
		if f.IsDir() {
			continue
		}

		encryptedPath := filepath.Join(PersistentStorageDir, f.Name())
		ramPath := filepath.Join(RamDiskDir, f.Name()+".decrypted")

		err := decryptShardToRam(encryptedPath, ramPath)
		if err != nil {
			log.Printf("[ENCLAVE] Failed to decrypt shard %s: %v", f.Name(), err)
		} else {
			log.Printf("[ENCLAVE] Successfully unlocked shard %s into volatile RAM.", f.Name())
		}
	}

	log.Println("[ENCLAVE] Secure Boot complete. MPC Services are ready.")
	return nil
}

// Simulates decrypting a file with AES-GCM
func decryptShardToRam(encryptedPath, ramPath string) error {
	ciphertext, err := ioutil.ReadFile(encryptedPath)
	if err != nil {
		return err
	}

	// Simplistic mock check. Real AES-GCM requires nonce management.
	if len(ciphertext) == 0 {
		return nil
	}
	
	block, err := aes.NewCipher(mockSgxMasterKey)
	if err != nil {
		return err
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		return err
	}
	
	// Assuming first 12 bytes are nonce for this mock
	if len(ciphertext) < aesgcm.NonceSize() {
		// Mock: just writing it as is if it's too small/not encrypted properly
		return ioutil.WriteFile(ramPath, ciphertext, 0600)
	}
	
	nonce, ciphertext := ciphertext[:aesgcm.NonceSize()], ciphertext[aesgcm.NonceSize():]
	plaintext, err := aesgcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return fmt.Errorf("decryption failed: %v", err)
	}

	// Write to tmpfs
	return ioutil.WriteFile(ramPath, plaintext, 0600)
}

// SaveEncryptedShard is called when a new user generates a key.
// It encrypts the generated shard and saves it to disk, while keeping plaintext ONLY in RAM.
func SaveEncryptedShard(filename string, plaintextData []byte) error {
	ramPath := filepath.Join(RamDiskDir, filename+".decrypted")
	encryptedPath := filepath.Join(PersistentStorageDir, filename)

	// 1. Save plaintext to RAM
	err := ioutil.WriteFile(ramPath, plaintextData, 0600)
	if err != nil {
		return fmt.Errorf("failed to save shard to RAM: %v", err)
	}

	// 2. Encrypt and save to Disk
	block, err := aes.NewCipher(mockSgxMasterKey)
	if err != nil {
		return err
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		return err
	}

	nonce := make([]byte, aesgcm.NonceSize())
	// In production, use crypto/rand to generate nonce!
	ciphertext := aesgcm.Seal(nonce, nonce, plaintextData, nil)

	err = ioutil.WriteFile(encryptedPath, ciphertext, 0600)
	if err != nil {
		return fmt.Errorf("failed to save encrypted shard to disk: %v", err)
	}

	log.Printf("[ENCLAVE] Shard %s safely encrypted to disk and kept in volatile RAM.", filename)
	return nil
}

// GetShardFromRam reads the shard directly from the tmpfs.
func GetShardFromRam(filename string) ([]byte, error) {
	ramPath := filepath.Join(RamDiskDir, filename+".decrypted")
	return ioutil.ReadFile(ramPath)
}

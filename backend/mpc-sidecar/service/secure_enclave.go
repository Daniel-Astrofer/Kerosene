package service

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

const (
	// Permanent encrypted storage on disk
	PersistentStorageDir = "/app/encrypted-shards"

	// Volatile RAM disk (tmpfs) mapped in docker-compose
	RamDiskDir = "/mnt/mpc-shards"
)

var (
	masterKeyOnce sync.Once
	masterKey     []byte
	masterKeyErr  error
)

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

	files, err := os.ReadDir(PersistentStorageDir)
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

func decryptShardToRam(encryptedPath, ramPath string) error {
	ciphertext, err := os.ReadFile(encryptedPath)
	if err != nil {
		return err
	}

	if len(ciphertext) == 0 {
		return nil
	}

	key, err := enclaveMasterKey()
	if err != nil {
		return err
	}
	defer zeroBytes(key)

	block, err := aes.NewCipher(key)
	if err != nil {
		return err
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		return err
	}

	if len(ciphertext) < aesgcm.NonceSize() {
		return fmt.Errorf("encrypted shard is too short to contain a GCM nonce")
	}

	nonce, ciphertext := ciphertext[:aesgcm.NonceSize()], ciphertext[aesgcm.NonceSize():]
	plaintext, err := aesgcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return fmt.Errorf("decryption failed: %v", err)
	}

	// Write to tmpfs
	return os.WriteFile(ramPath, plaintext, 0600)
}

// SaveEncryptedShard is called when a new user generates a key.
// It encrypts the generated shard and saves it to disk, while keeping plaintext ONLY in RAM.
func SaveEncryptedShard(filename string, plaintextData []byte) error {
	ramPath := filepath.Join(RamDiskDir, filename+".decrypted")
	encryptedPath := filepath.Join(PersistentStorageDir, filename)

	if err := os.MkdirAll(RamDiskDir, 0700); err != nil {
		return fmt.Errorf("failed to create RAM shard dir: %v", err)
	}
	if err := os.MkdirAll(PersistentStorageDir, 0700); err != nil {
		return fmt.Errorf("failed to create encrypted shard dir: %v", err)
	}

	// 1. Save plaintext to RAM
	err := os.WriteFile(ramPath, plaintextData, 0600)
	if err != nil {
		return fmt.Errorf("failed to save shard to RAM: %v", err)
	}

	// 2. Encrypt and save to Disk
	key, err := enclaveMasterKey()
	if err != nil {
		return err
	}
	defer zeroBytes(key)

	block, err := aes.NewCipher(key)
	if err != nil {
		return err
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		return err
	}

	nonce := make([]byte, aesgcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return fmt.Errorf("failed to generate AES-GCM nonce: %v", err)
	}
	ciphertext := aesgcm.Seal(nonce, nonce, plaintextData, nil)

	err = os.WriteFile(encryptedPath, ciphertext, 0600)
	if err != nil {
		return fmt.Errorf("failed to save encrypted shard to disk: %v", err)
	}

	log.Printf("[ENCLAVE] Shard %s safely encrypted to disk and kept in volatile RAM.", filename)
	return nil
}

// GetShardFromRam reads the shard directly from the tmpfs.
func GetShardFromRam(filename string) ([]byte, error) {
	ramPath := filepath.Join(RamDiskDir, filename+".decrypted")
	return os.ReadFile(ramPath)
}

func enclaveMasterKey() ([]byte, error) {
	masterKeyOnce.Do(func() {
		masterKey, masterKeyErr = loadMasterKey()
	})
	if masterKeyErr != nil {
		return nil, masterKeyErr
	}

	copyKey := make([]byte, len(masterKey))
	copy(copyKey, masterKey)
	return copyKey, nil
}

func loadMasterKey() ([]byte, error) {
	if raw := strings.TrimSpace(os.Getenv("MPC_MASTER_KEY_B64")); raw != "" {
		return decodeMasterKey([]byte(raw))
	}

	if path := strings.TrimSpace(os.Getenv("MPC_MASTER_KEY_FILE")); path != "" {
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("failed to read MPC_MASTER_KEY_FILE: %v", err)
		}
		return decodeMasterKey(data)
	}

	return nil, errors.New("MPC master key is not configured; set MPC_MASTER_KEY_B64 or MPC_MASTER_KEY_FILE from Vault/HSM")
}

func decodeMasterKey(data []byte) ([]byte, error) {
	trimmed := []byte(strings.TrimSpace(string(data)))
	if len(trimmed) == 32 {
		key := make([]byte, 32)
		copy(key, trimmed)
		return key, nil
	}

	decoded := make([]byte, base64.StdEncoding.DecodedLen(len(trimmed)))
	n, err := base64.StdEncoding.Decode(decoded, trimmed)
	if err != nil {
		return nil, fmt.Errorf("MPC master key must be 32 raw bytes or base64-encoded AES-256: %v", err)
	}
	decoded = decoded[:n]
	if len(decoded) != 32 {
		zeroBytes(decoded)
		return nil, fmt.Errorf("MPC master key must be 32 bytes, got %d", len(decoded))
	}
	return decoded, nil
}

func zeroBytes(data []byte) {
	for i := range data {
		data[i] = 0
	}
}

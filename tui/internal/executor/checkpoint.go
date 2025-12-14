// Package executor - checkpoint.go handles atomic state persistence for resume capability
package executor

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

const (
	// CheckpointVersion is incremented when checkpoint format changes
	CheckpointVersion = 1
	// CheckpointDir is relative to user's home directory
	CheckpointDir = ".cache/ghostty-installer/pipelines"
)

// StateCheckpoint represents the saved state of a pipeline execution
type StateCheckpoint struct {
	Version         int             `json:"version"`
	ToolID          string          `json:"tool_id"`
	Timestamp       time.Time       `json:"timestamp"`
	CurrentStage    PipelineStage   `json:"current_stage"`
	CompletedStages []PipelineStage `json:"completed_stages"`
	FailedStage     *FailureInfo    `json:"failed_stage,omitempty"`
	IsResumable     bool            `json:"is_resumable"`
	Logs            []ExecutionLog  `json:"logs,omitempty"`
}

// FailureInfo contains details about a pipeline failure
type FailureInfo struct {
	Stage        PipelineStage `json:"stage"`
	ErrorMessage string        `json:"error"`
	ExitCode     int           `json:"exit_code"`
	Recoverable  bool          `json:"recoverable"`
	Timestamp    time.Time     `json:"timestamp"`
}

// ExecutionLog captures a single log entry during execution
type ExecutionLog struct {
	Stage     PipelineStage `json:"stage"`
	Message   string        `json:"message"`
	Timestamp time.Time     `json:"timestamp"`
	IsError   bool          `json:"is_error"`
}

// CheckpointStore manages checkpoint file operations
type CheckpointStore struct {
	mu      sync.RWMutex
	baseDir string
}

// NewCheckpointStore creates a new checkpoint store
func NewCheckpointStore() *CheckpointStore {
	home, _ := os.UserHomeDir()
	baseDir := filepath.Join(home, CheckpointDir)
	return &CheckpointStore{
		baseDir: baseDir,
	}
}

// getPath returns the checkpoint file path for a tool
func (s *CheckpointStore) getPath(toolID string) string {
	return filepath.Join(s.baseDir, toolID+".json")
}

// ensureDir creates the checkpoint directory if it doesn't exist
func (s *CheckpointStore) ensureDir() error {
	return os.MkdirAll(s.baseDir, 0755)
}

// Save atomically writes a checkpoint to disk
// Uses write-to-temp + rename pattern for atomicity
func (s *CheckpointStore) Save(toolID string, checkpoint StateCheckpoint) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Ensure directory exists
	if err := s.ensureDir(); err != nil {
		return fmt.Errorf("failed to create checkpoint directory: %w", err)
	}

	// Set version and timestamp
	checkpoint.Version = CheckpointVersion
	if checkpoint.Timestamp.IsZero() {
		checkpoint.Timestamp = time.Now()
	}

	// Marshal to JSON
	data, err := json.MarshalIndent(checkpoint, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal checkpoint: %w", err)
	}

	// Write to temp file
	finalPath := s.getPath(toolID)
	tempPath := finalPath + ".tmp"

	file, err := os.Create(tempPath)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}

	if _, err := file.Write(data); err != nil {
		file.Close()
		os.Remove(tempPath)
		return fmt.Errorf("failed to write checkpoint: %w", err)
	}

	// Sync to disk before rename
	if err := file.Sync(); err != nil {
		file.Close()
		os.Remove(tempPath)
		return fmt.Errorf("failed to sync checkpoint: %w", err)
	}

	if err := file.Close(); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to close checkpoint: %w", err)
	}

	// Atomic rename
	if err := os.Rename(tempPath, finalPath); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to finalize checkpoint: %w", err)
	}

	return nil
}

// SaveFailure saves a failure checkpoint that can be resumed
func (s *CheckpointStore) SaveFailure(toolID string, stage PipelineStage, err error, exitCode int) error {
	// Load existing checkpoint to preserve completed stages
	existing, _ := s.Load(toolID)

	checkpoint := StateCheckpoint{
		ToolID:       toolID,
		CurrentStage: stage,
		IsResumable:  true,
		FailedStage: &FailureInfo{
			Stage:        stage,
			ErrorMessage: err.Error(),
			ExitCode:     exitCode,
			Recoverable:  isRecoverable(stage, exitCode),
			Timestamp:    time.Now(),
		},
	}

	// Preserve completed stages from existing checkpoint
	if existing != nil {
		checkpoint.CompletedStages = existing.CompletedStages
		checkpoint.Logs = existing.Logs
	}

	return s.Save(toolID, checkpoint)
}

// MarkStageComplete updates the checkpoint to mark a stage as complete
func (s *CheckpointStore) MarkStageComplete(toolID string, stage PipelineStage) error {
	checkpoint, err := s.Load(toolID)
	if err != nil {
		// Create new checkpoint if none exists
		checkpoint = &StateCheckpoint{
			ToolID:          toolID,
			CompletedStages: []PipelineStage{},
		}
	}

	// Add stage to completed list if not already present
	found := false
	for _, cs := range checkpoint.CompletedStages {
		if cs == stage {
			found = true
			break
		}
	}
	if !found {
		checkpoint.CompletedStages = append(checkpoint.CompletedStages, stage)
	}

	// Update current stage to next
	if stage < StageConfirm {
		checkpoint.CurrentStage = stage + 1
	}

	checkpoint.IsResumable = true
	checkpoint.FailedStage = nil // Clear any previous failure

	return s.Save(toolID, *checkpoint)
}

// Load reads a checkpoint from disk
func (s *CheckpointStore) Load(toolID string) (*StateCheckpoint, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	path := s.getPath(toolID)
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil // No checkpoint exists
		}
		return nil, fmt.Errorf("failed to read checkpoint: %w", err)
	}

	var checkpoint StateCheckpoint
	if err := json.Unmarshal(data, &checkpoint); err != nil {
		return nil, fmt.Errorf("failed to parse checkpoint: %w", err)
	}

	// Version migration if needed
	if checkpoint.Version < CheckpointVersion {
		checkpoint = migrateCheckpoint(checkpoint)
	}

	return &checkpoint, nil
}

// Clear removes a checkpoint file (called on successful completion)
func (s *CheckpointStore) Clear(toolID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	path := s.getPath(toolID)
	err := os.Remove(path)
	if os.IsNotExist(err) {
		return nil // Already cleared
	}
	return err
}

// Exists checks if a checkpoint exists for a tool
func (s *CheckpointStore) Exists(toolID string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	path := s.getPath(toolID)
	_, err := os.Stat(path)
	return err == nil
}

// HasResumableCheckpoint returns true if there's a resumable checkpoint
func (s *CheckpointStore) HasResumableCheckpoint(toolID string) bool {
	checkpoint, err := s.Load(toolID)
	if err != nil || checkpoint == nil {
		return false
	}
	return checkpoint.IsResumable
}

// GetResumeStage returns the stage to resume from, if any
func (s *CheckpointStore) GetResumeStage(toolID string) (PipelineStage, bool) {
	checkpoint, err := s.Load(toolID)
	if err != nil || checkpoint == nil || !checkpoint.IsResumable {
		return StageCheck, false
	}

	// If there was a failure, resume from that stage
	if checkpoint.FailedStage != nil {
		return checkpoint.FailedStage.Stage, true
	}

	// Otherwise resume from current stage
	return checkpoint.CurrentStage, true
}

// AddLog appends a log entry to the checkpoint
func (s *CheckpointStore) AddLog(toolID string, stage PipelineStage, message string, isError bool) error {
	checkpoint, err := s.Load(toolID)
	if err != nil || checkpoint == nil {
		checkpoint = &StateCheckpoint{
			ToolID: toolID,
		}
	}

	checkpoint.Logs = append(checkpoint.Logs, ExecutionLog{
		Stage:     stage,
		Message:   message,
		Timestamp: time.Now(),
		IsError:   isError,
	})

	return s.Save(toolID, *checkpoint)
}

// migrateCheckpoint handles version upgrades
func migrateCheckpoint(old StateCheckpoint) StateCheckpoint {
	// Currently no migrations needed
	old.Version = CheckpointVersion
	return old
}

// isRecoverable determines if a failure at a stage can be resumed
func isRecoverable(stage PipelineStage, exitCode int) bool {
	// All stages are recoverable by default
	// Only mark non-recoverable for specific known-bad states
	switch stage {
	case StageInstall:
		// Corrupt build state might not be recoverable
		// Exit code 137 = OOM killed, 130 = Ctrl+C
		return exitCode != 137
	default:
		return true
	}
}

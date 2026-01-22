// Package registry - mcp.go provides the MCP server catalog
package registry

import (
	"os"
	"os/exec"
)

// MCPTransport defines how the server communicates
type MCPTransport string

const (
	TransportHTTP  MCPTransport = "http"
	TransportStdio MCPTransport = "stdio"
)

// MCPPrerequisite defines a requirement for an MCP server
type MCPPrerequisite struct {
	ID              string   // "nodejs", "gh_auth", "apparmor_fix"
	Name            string   // "Node.js via fnm"
	CheckCmd        []string // ["node", "--version"]
	FixInstructions string   // How to fix if missing
	FixScript       string   // Optional: path to fix script
}

// MCPSecret defines a required environment variable
type MCPSecret struct {
	EnvVar      string // "CONTEXT7_API_KEY"
	Name        string // "Context7 API Key"
	Description string // Longer description
	GetURL      string // "https://context7.com"
	Required    bool   // true if server won't work without it
}

// MCPServer defines a single MCP server configuration
type MCPServer struct {
	ID          string
	DisplayName string
	Description string
	Transport   MCPTransport

	// For HTTP transport
	URL     string            // Full URL
	Headers map[string]string // Header name -> env var name

	// For stdio transport
	Command string // Full command to execute

	// Dependencies
	Prerequisites []MCPPrerequisite
	Secrets       []MCPSecret
}

// PrerequisiteResult holds the result of checking a prerequisite
type PrerequisiteResult struct {
	Prerequisite    MCPPrerequisite
	Passed          bool
	FixInstructions string
}

// SecretResult holds the result of checking a secret
type SecretResult struct {
	Secret  MCPSecret
	Present bool
}

// mcpServers is the internal registry
var mcpServers = map[string]*MCPServer{
	"context7": {
		ID:          "context7",
		DisplayName: "Context7",
		Description: "Up-to-date library documentation",
		Transport:   TransportHTTP,
		URL:         "https://mcp.context7.com/mcp",
		Headers:     map[string]string{"CONTEXT7_API_KEY": "CONTEXT7_API_KEY"},
		Secrets: []MCPSecret{{
			EnvVar:      "CONTEXT7_API_KEY",
			Name:        "Context7 API Key",
			Description: "API key for Context7 documentation service",
			GetURL:      "https://context7.com",
			Required:    true,
		}},
	},
	"github": {
		ID:          "github",
		DisplayName: "GitHub",
		Description: "Repository operations, issues, PRs",
		Transport:   TransportStdio,
		Command:     `export PATH="$HOME/.local/bin:$PATH"; eval "$(fnm env 2>/dev/null)" 2>/dev/null; GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github`,
		Prerequisites: []MCPPrerequisite{
			{
				ID:              "nodejs",
				Name:            "Node.js",
				CheckCmd:        []string{"node", "--version"},
				FixInstructions: "Install Node.js: fnm install --lts",
			},
			{
				ID:              "gh_auth",
				Name:            "GitHub CLI Auth",
				CheckCmd:        []string{"gh", "auth", "status"},
				FixInstructions: "Run: gh auth login",
			},
		},
	},
	"markitdown": {
		ID:          "markitdown",
		DisplayName: "MarkItDown",
		Description: "Document format conversion",
		Transport:   TransportStdio,
		Command:     "uvx markitdown-mcp",
		Prerequisites: []MCPPrerequisite{
			{
				ID:              "uvx",
				Name:            "Python UV (uvx)",
				CheckCmd:        []string{"uvx", "--version"},
				FixInstructions: "Install UV: curl -LsSf https://astral.sh/uv/install.sh | sh",
			},
		},
	},
	"playwright": {
		ID:          "playwright",
		DisplayName: "Playwright",
		Description: "Browser automation, screenshots",
		Transport:   TransportStdio,
		Command:     "~/.local/bin/playwright-mcp-wrapper.sh",
		Prerequisites: []MCPPrerequisite{
			{
				ID:              "nodejs",
				Name:            "Node.js",
				CheckCmd:        []string{"node", "--version"},
				FixInstructions: "Install Node.js: fnm install --lts",
			},
			{
				ID:              "playwright_wrapper",
				Name:            "Playwright Wrapper",
				CheckCmd:        []string{"test", "-x", os.ExpandEnv("$HOME/.local/bin/playwright-mcp-wrapper.sh")},
				FixInstructions: "Create wrapper script at ~/.local/bin/playwright-mcp-wrapper.sh",
			},
		},
	},
	"hf-mcp-server": {
		ID:          "hf-mcp-server",
		DisplayName: "HuggingFace",
		Description: "Model hub access",
		Transport:   TransportHTTP,
		URL:         "https://huggingface.co/mcp",
		Secrets: []MCPSecret{{
			EnvVar:      "HUGGINGFACE_TOKEN",
			Name:        "HuggingFace Token",
			Description: "Access token for HuggingFace model hub",
			GetURL:      "https://huggingface.co/settings/tokens",
			Required:    true,
		}},
	},
	"shadcn": {
		ID:          "shadcn",
		DisplayName: "shadcn",
		Description: "Official shadcn/ui CLI MCP",
		Transport:   TransportStdio,
		Command:     "npx shadcn@latest mcp",
		Prerequisites: []MCPPrerequisite{
			{
				ID:              "nodejs",
				Name:            "Node.js",
				CheckCmd:        []string{"node", "--version"},
				FixInstructions: "Install Node.js: fnm install --lts",
			},
		},
	},
	"shadcn-ui": {
		ID:          "shadcn-ui",
		DisplayName: "shadcn-ui",
		Description: "shadcn component tools",
		Transport:   TransportStdio,
		Command:     `export PATH="$HOME/.local/bin:$PATH"; eval "$(fnm env 2>/dev/null)" 2>/dev/null; GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @jpisnice/shadcn-ui-mcp-server`,
		Prerequisites: []MCPPrerequisite{
			{
				ID:              "nodejs",
				Name:            "Node.js",
				CheckCmd:        []string{"node", "--version"},
				FixInstructions: "Install Node.js: fnm install --lts",
			},
			{
				ID:              "gh_auth",
				Name:            "GitHub CLI Auth",
				CheckCmd:        []string{"gh", "auth", "status"},
				FixInstructions: "Run: gh auth login",
			},
		},
	},
}

// mcpServerIDs defines display order
var mcpServerIDs = []string{
	"context7",
	"github",
	"markitdown",
	"playwright",
	"hf-mcp-server",
	"shadcn",
	"shadcn-ui",
}

// GetMCPServer returns an MCP server by ID
func GetMCPServer(id string) (*MCPServer, bool) {
	s, ok := mcpServers[id]
	return s, ok
}

// GetAllMCPServers returns all servers in display order
func GetAllMCPServers() []*MCPServer {
	result := make([]*MCPServer, 0, len(mcpServerIDs))
	for _, id := range mcpServerIDs {
		if s, ok := mcpServers[id]; ok {
			result = append(result, s)
		}
	}
	return result
}

// MCPServerCount returns count for UI display
func MCPServerCount() int {
	return len(mcpServerIDs)
}

// CheckPrerequisite verifies a single prerequisite
func CheckPrerequisite(prereq MCPPrerequisite) (bool, string) {
	if len(prereq.CheckCmd) == 0 {
		return true, ""
	}

	cmd := exec.Command(prereq.CheckCmd[0], prereq.CheckCmd[1:]...)
	err := cmd.Run()
	if err != nil {
		return false, prereq.FixInstructions
	}
	return true, ""
}

// CheckAllPrerequisites checks all prerequisites for a server
func (s *MCPServer) CheckAllPrerequisites() []PrerequisiteResult {
	results := make([]PrerequisiteResult, len(s.Prerequisites))
	for i, prereq := range s.Prerequisites {
		passed, fix := CheckPrerequisite(prereq)
		results[i] = PrerequisiteResult{
			Prerequisite:    prereq,
			Passed:          passed,
			FixInstructions: fix,
		}
	}
	return results
}

// CheckSecrets verifies required secrets are set
func (s *MCPServer) CheckSecrets() []SecretResult {
	results := make([]SecretResult, len(s.Secrets))
	for i, secret := range s.Secrets {
		value := os.Getenv(secret.EnvVar)
		results[i] = SecretResult{
			Secret:  secret,
			Present: value != "",
		}
	}
	return results
}

// AllPrerequisitesPassed returns true if all prerequisites pass
func (s *MCPServer) AllPrerequisitesPassed() bool {
	for _, result := range s.CheckAllPrerequisites() {
		if !result.Passed {
			return false
		}
	}
	return true
}

// AllSecretsPresent returns true if all required secrets are set
func (s *MCPServer) AllSecretsPresent() bool {
	for _, result := range s.CheckSecrets() {
		if result.Secret.Required && !result.Present {
			return false
		}
	}
	return true
}

// GetAddCommand returns the claude mcp add arguments for this server
func (s *MCPServer) GetAddCommand() []string {
	args := []string{"mcp", "add", "--scope", "user"}

	if s.Transport == TransportHTTP {
		args = append(args, "--transport", "http", s.ID, s.URL)
		// Add headers for secrets
		for headerName, envVar := range s.Headers {
			value := os.Getenv(envVar)
			if value != "" {
				args = append(args, "--header", headerName+": "+value)
			}
		}
	} else {
		// stdio transport
		args = append(args, s.ID, "--", "bash", "-c", s.Command)
	}

	return args
}

// GetRemoveCommand returns the claude mcp remove arguments for this server
func (s *MCPServer) GetRemoveCommand() []string {
	return []string{"mcp", "remove", "--scope", "user", s.ID}
}

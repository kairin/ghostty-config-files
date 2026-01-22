#!/usr/bin/env bash
# Status script for Claude Config (SpecKit skills + agents)
# Output format: STATUS|VERSION|METHOD|LOCATION|LATEST

CLAUDE_DIR="${HOME}/.claude"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
AGENTS_DIR="${CLAUDE_DIR}/agents"

# Check if skills are installed (commands directory with .md files)
skills_count=0
if [[ -d "$COMMANDS_DIR" ]]; then
    skills_count=$(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
fi

# Check if agents are installed
agents_count=0
if [[ -d "$AGENTS_DIR" ]]; then
    agents_count=$(ls -1 "$AGENTS_DIR" 2>/dev/null | wc -l)
fi

# Consider installed if we have at least 1 skill AND at least 1 agent
if [[ "$skills_count" -ge 1 ]] && [[ "$agents_count" -ge 1 ]]; then
    # Format: STATUS|VERSION|METHOD|LOCATION|LATEST
    # Use ^ delimiter for sub-details in location
    version="${skills_count} skills, ${agents_count} agents"
    method="symlink"
    location="Skills: ${COMMANDS_DIR}^Agents: ${AGENTS_DIR}"
    echo "INSTALLED|${version}|${method}|${location}|-"
    exit 0
fi

# Not installed
echo "NOT_INSTALLED|-|-|-|-"
exit 0

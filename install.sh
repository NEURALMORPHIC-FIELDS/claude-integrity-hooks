#!/bin/bash
# ==========================================================================
# Claude Integrity Hooks — Installer
# Copyright (c) 2024-2026 Vasile Lucian Borbeleac / FRAGMERGENT TECHNOLOGY S.R.L.
# Cluj-Napoca, Romania
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/NEURALMORPHIC-FIELDS/claude-integrity-hooks/main/install.sh | bash
#
# Or run locally:
#   bash install.sh
#
# Options:
#   --global    Install to ~/.claude/ (applies to all projects)
#   --project   Install to ./.claude/ (default, applies to current project)
# ==========================================================================

set -e

SCOPE="project"
if [ "$1" = "--global" ]; then
    SCOPE="global"
fi

if [ "$SCOPE" = "global" ]; then
    TARGET_DIR="$HOME/.claude"
    echo "[INFO] Installing Claude Integrity Hooks GLOBALLY to $TARGET_DIR"
else
    TARGET_DIR=".claude"
    echo "[INFO] Installing Claude Integrity Hooks to $TARGET_DIR (project scope)"
fi

# Create directories
mkdir -p "$TARGET_DIR/hooks"

# Download hook scripts
REPO_URL="https://raw.githubusercontent.com/NEURALMORPHIC-FIELDS/claude-integrity-hooks/main"

echo "[INFO] Downloading hook scripts..."

curl -sSL "$REPO_URL/hooks/inject_checklist.sh" -o "$TARGET_DIR/hooks/inject_checklist.sh"
curl -sSL "$REPO_URL/hooks/audit_response.sh" -o "$TARGET_DIR/hooks/audit_response.sh"

chmod +x "$TARGET_DIR/hooks/inject_checklist.sh"
chmod +x "$TARGET_DIR/hooks/audit_response.sh"

echo "[INFO] Hook scripts installed."

# Check if settings.json already exists
SETTINGS_FILE="$TARGET_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo ""
    echo "[WARN] $SETTINGS_FILE already exists."
    echo "[WARN] You need to MANUALLY merge the hooks configuration."
    echo "[WARN] Download the template with:"
    echo "       curl -sSL $REPO_URL/settings.json"
    echo ""
    echo "[INFO] Add the 'hooks' section from the template to your existing settings.json"
else
    curl -sSL "$REPO_URL/settings.json" -o "$SETTINGS_FILE"
    echo "[INFO] settings.json created with hook configuration."
fi

echo ""
echo "============================================================"
echo " Claude Integrity Hooks — INSTALLED"
echo "============================================================"
echo ""
echo " Three layers of enforcement active:"
echo "   1. Integrity checklist injected before every prompt"
echo "   2. Haiku auditor checks every response for violations"
echo "   3. Filesystem audit warns on stale project logs"
echo ""
echo " Restart Claude Code for hooks to take effect."
echo ""
echo " Docs: https://github.com/NEURALMORPHIC-FIELDS/claude-integrity-hooks"
echo "============================================================"

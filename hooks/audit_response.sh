#!/bin/bash
# ==========================================================================
# Claude Integrity Hooks — Filesystem Audit
# Copyright (c) 2024-2026 Vasile Lucian Borbeleac / FRAGMERGENT TECHNOLOGY S.R.L.
# Cluj-Napoca, Romania
#
# Post-response audit: checks if project log/memory files were updated
# when the AI modified files during the session.
#
# Hook event: Stop
# Exit 0 = allow (with optional warning on stderr)
# Exit 2 = block response
# ==========================================================================

INPUT=$(cat)

# Extract session info from hook input
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null || echo "unknown")

# Check for common project log files
# Customize these paths for your project
LOG_FILES=(
    ".claude/project_log.json"
    "project_log.json"
)

for LOG_FILE in "${LOG_FILES[@]}"; do
    if [ -f "$LOG_FILE" ]; then
        NOW=$(date +%s)
        MOD=$(stat -c %Y "$LOG_FILE" 2>/dev/null || stat -f %m "$LOG_FILE" 2>/dev/null || echo 0)
        DIFF=$((NOW - MOD))

        # Warn if log not updated in last 5 minutes during active session
        if [ "$DIFF" -gt 300 ]; then
            echo "[INTEGRITY AUDIT] WARNING: $LOG_FILE not updated in ${DIFF}s. If you modified files, update the log." >&2
        fi
        break
    fi
done

# Exit 0 = allow response (warnings are informational)
# Change to exit 2 if you want to BLOCK on stale logs
exit 0

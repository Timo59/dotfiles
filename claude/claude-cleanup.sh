#!/bin/bash
# =============================================================================
# cleanup.sh - Remove stale Claude Code session files
# =============================================================================
# Workaround for cleanupPeriodDays being ignored in Claude Code < v2.1.101.
# Deletes files and directories in ~/.claude/projects/ older than N days.
# Intended to be run at login via LaunchAgent.
# =============================================================================

CLEANUP_DAYS=5
PROJECTS_DIR="$HOME/.claude/projects"

if [ ! -d "$PROJECTS_DIR" ]; then
  echo "[INFO] $PROJECTS_DIR does not exist, nothing to clean"
  exit 0
fi

find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -mtime +"$CLEANUP_DAYS" -exec rm -rf {} +
echo "[DONE] Cleaned Claude session files older than $CLEANUP_DAYS days"

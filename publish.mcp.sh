#!/usr/bin/env bash
set -euo pipefail

# Publish MCP metadata only (no npm publish, no version bump).
# Usage: ./publish.mcp.sh [version]
# Optional env:
#   NPM_WAIT_ATTEMPTS=60
#   NPM_WAIT_SECONDS=20
#   MCP_PUBLISH_ATTEMPTS=20
#   MCP_PUBLISH_WAIT_SECONDS=20

ROOT="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$ROOT/packages/mcp-server"
SERVER_JSON="$SERVER_DIR/server.json"
VERSION_ARG="${1:-}"
NPM_WAIT_ATTEMPTS="${NPM_WAIT_ATTEMPTS:-60}"
NPM_WAIT_SECONDS="${NPM_WAIT_SECONDS:-20}"
MCP_PUBLISH_ATTEMPTS="${MCP_PUBLISH_ATTEMPTS:-20}"
MCP_PUBLISH_WAIT_SECONDS="${MCP_PUBLISH_WAIT_SECONDS:-20}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    exit 1
  fi
}

open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  fi
}

find_mcp_publisher() {
  if [[ -x "$ROOT/mcp-publisher" ]]; then
    echo "$ROOT/mcp-publisher"
    return 0
  fi
  if command -v mcp-publisher >/dev/null 2>&1; then
    command -v mcp-publisher
    return 0
  fi
  if [[ -x "$HOME/.local/bin/mcp-publisher" ]]; then
    echo "$HOME/.local/bin/mcp-publisher"
    return 0
  fi
  return 1
}

read_versions() {
  SERVER_VERSION="$(node -p "require('$SERVER_DIR/package.json').version")"
  SERVER_JSON_VERSION="$(node -p "require('$SERVER_JSON').version")"
}

ensure_version_alignment() {
  if [[ "$SERVER_VERSION" != "$SERVER_JSON_VERSION" ]]; then
    echo "Version mismatch:"
    echo "  packages/mcp-server/package.json: $SERVER_VERSION"
    echo "  packages/mcp-server/server.json:   $SERVER_JSON_VERSION"
    echo "Run ./publish.sh first to align versions."
    exit 1
  fi

  if [[ -n "$VERSION_ARG" && "$VERSION_ARG" != "$SERVER_VERSION" ]]; then
    echo "Requested version $VERSION_ARG does not match repo version $SERVER_VERSION."
    echo "Run ./publish.sh to bump/tag first, or pass no argument."
    exit 1
  fi

  VERSION="$SERVER_VERSION"
}

wait_for_npm_version() {
  local pkg="@newsmcp/server"
  for attempt in $(seq 1 "$NPM_WAIT_ATTEMPTS"); do
    if npm view "$pkg@$VERSION" version >/dev/null 2>&1; then
      echo "$pkg@$VERSION is visible on npm."
      return 0
    fi
    echo "Waiting for npm visibility: $pkg@$VERSION (attempt $attempt/$NPM_WAIT_ATTEMPTS)..."
    sleep "$NPM_WAIT_SECONDS"
  done

  echo "Timed out waiting for $pkg@$VERSION to appear on npm."
  return 1
}

login_mcp() {
  echo "Authenticating mcp-publisher with GitHub..."
  open_url "https://github.com/login/device"
  (cd "$SERVER_DIR" && "$MCP_PUBLISHER" login github)
}

publish_mcp() {
  local output=""
  local status=0

  for attempt in $(seq 1 "$MCP_PUBLISH_ATTEMPTS"); do
    set +e
    output="$(cd "$SERVER_DIR" && "$MCP_PUBLISHER" publish server.json 2>&1)"
    status=$?
    set -e

    echo "$output"

    if [[ "$status" -eq 0 ]]; then
      echo "MCP metadata published for version $VERSION."
      return 0
    fi

    if grep -qiE "already exists|already published|conflict" <<<"$output"; then
      echo "MCP metadata already published for version $VERSION."
      return 0
    fi

    if grep -qiE "401|unauthorized|expired|invalid.*token|not authenticated" <<<"$output"; then
      echo "MCP auth expired/invalid. Re-authenticating..."
      login_mcp
      continue
    fi

    if grep -qiE "not found \(status: 404\)|validation failed" <<<"$output"; then
      echo "MCP validation still failing (likely npm replication delay)."
      echo "Retrying in ${MCP_PUBLISH_WAIT_SECONDS}s (attempt $attempt/$MCP_PUBLISH_ATTEMPTS)..."
      sleep "$MCP_PUBLISH_WAIT_SECONDS"
      continue
    fi

    echo "MCP publish failed with a non-retryable error."
    return "$status"
  done

  echo "MCP publish failed after $MCP_PUBLISH_ATTEMPTS attempts."
  return 1
}

require_cmd npm
require_cmd node
MCP_PUBLISHER="$(find_mcp_publisher || true)"
if [[ -z "$MCP_PUBLISHER" ]]; then
  echo "Could not find mcp-publisher binary."
  echo "Expected one of: ./mcp-publisher, mcp-publisher in PATH, ~/.local/bin/mcp-publisher"
  exit 1
fi

read_versions
ensure_version_alignment
wait_for_npm_version
login_mcp
publish_mcp

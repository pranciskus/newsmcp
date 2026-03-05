#!/usr/bin/env bash
set -euo pipefail

# Publish newsmcp packages to npm + MCP Registry and create a GitHub release.
# Usage: ./publish.sh [patch|minor|major]

BUMP="${1:-patch}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$ROOT/packages/mcp-server"
OPENCLAW_DIR="$ROOT/packages/openclaw-plugin"
SERVER_JSON="$SERVER_DIR/server.json"
BRANCH="$(git -C "$ROOT" branch --show-current)"

if [[ ! "$BUMP" =~ ^(patch|minor|major)$ ]]; then
  echo "Usage: ./publish.sh [patch|minor|major]"
  exit 1
fi

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

ensure_clean_worktree() {
  if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    echo "Working tree is not clean. Commit/stash changes before publishing."
    git -C "$ROOT" status --short
    exit 1
  fi
}

ensure_npm_auth() {
  if npm whoami >/dev/null 2>&1; then
    return 0
  fi
  echo "npm auth required. Opening browser for login..."
  open_url "https://www.npmjs.com/login"
  npm login --auth-type=web
  npm whoami >/dev/null
}

ensure_gh_auth() {
  if gh auth status -h github.com >/dev/null 2>&1; then
    return 0
  fi
  echo "GitHub CLI auth required. Opening browser for login..."
  open_url "https://github.com/login"
  gh auth login -h github.com --web -s repo
}

npm_publish_with_retry() {
  local dir="$1"
  local pkg="$2"
  local otp=""
  local output=""
  local status=0

  while true; do
    set +e
    if [[ -n "$otp" ]]; then
      output="$(cd "$dir" && npm publish --access public --otp "$otp" 2>&1)"
    else
      output="$(cd "$dir" && npm publish --access public 2>&1)"
    fi
    status=$?
    set -e
    echo "$output"

    if [[ $status -eq 0 ]]; then
      return 0
    fi

    if grep -q "code EOTP" <<<"$output"; then
      read -r -p "Enter npm OTP for $pkg: " otp
      continue
    fi

    if grep -qiE "E401|access token expired|revoked|Unauthorized" <<<"$output"; then
      echo "Refreshing npm auth..."
      open_url "https://www.npmjs.com/login"
      npm login --auth-type=web
      otp=""
      continue
    fi

    echo "npm publish failed for $pkg."
    return $status
  done
}

update_server_json_version() {
  local version="$1"
  node - "$SERVER_JSON" "$version" <<'NODE'
const fs = require("fs");
const file = process.argv[2];
const version = process.argv[3];
const data = JSON.parse(fs.readFileSync(file, "utf8"));
data.version = version;
if (Array.isArray(data.packages)) {
  for (const pkg of data.packages) {
    if (pkg && pkg.registryType === "npm" && pkg.identifier === "@newsmcp/server") {
      pkg.version = version;
    }
  }
}
fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
NODE
}

mcp_publish_with_retry() {
  local publisher="$1"
  local output=""
  local status=0

  while true; do
    set +e
    output="$(cd "$SERVER_DIR" && "$publisher" publish 2>&1)"
    status=$?
    set -e
    echo "$output"

    if [[ $status -eq 0 ]]; then
      return 0
    fi

    if grep -qiE "401|unauthorized|expired|invalid.*token|not authenticated" <<<"$output"; then
      echo "Refreshing MCP Registry auth..."
      open_url "https://github.com/login/device"
      (cd "$SERVER_DIR" && "$publisher" login github)
      continue
    fi

    echo "MCP Registry publish failed."
    return $status
  done
}

create_git_commit_tag_and_release() {
  local version="$1"
  local tag="v$version"

  git -C "$ROOT" add \
    package-lock.json \
    packages/mcp-server/package.json \
    packages/openclaw-plugin/package.json \
    packages/mcp-server/server.json
  git -C "$ROOT" commit -m "Release $tag"

  if git -C "$ROOT" rev-parse "$tag" >/dev/null 2>&1; then
    echo "Tag $tag already exists, skipping tag creation."
  else
    git -C "$ROOT" tag -a "$tag" -m "$tag"
  fi

  git -C "$ROOT" push origin "$BRANCH"
  git -C "$ROOT" push origin "$tag"

  if gh release view "$tag" >/dev/null 2>&1; then
    echo "GitHub release $tag already exists, skipping."
  else
    gh release create "$tag" --title "$tag" --generate-notes
  fi
}

require_cmd git
require_cmd npm
require_cmd node
require_cmd gh
MCP_PUBLISHER="$(find_mcp_publisher || true)"
if [[ -z "$MCP_PUBLISHER" ]]; then
  echo "Could not find mcp-publisher binary."
  echo "Expected one of: ./mcp-publisher, mcp-publisher in PATH, ~/.local/bin/mcp-publisher"
  exit 1
fi

ensure_clean_worktree
ensure_npm_auth
ensure_gh_auth

echo "=== Building ==="
(cd "$SERVER_DIR" && npm run build)
(cd "$OPENCLAW_DIR" && npm run typecheck)

echo ""
echo "=== Publishing @newsmcp/server to npm ==="
(cd "$SERVER_DIR" && npm version "$BUMP" --no-git-tag-version)
VERSION="$(node -p "require('$SERVER_DIR/package.json').version")"
npm_publish_with_retry "$SERVER_DIR" "@newsmcp/server"
echo "Published @newsmcp/server@$VERSION"

echo ""
echo "=== Publishing @newsmcp/openclaw to npm ==="
(cd "$OPENCLAW_DIR" && npm version "$VERSION" --no-git-tag-version --allow-same-version)
npm_publish_with_retry "$OPENCLAW_DIR" "@newsmcp/openclaw"
echo "Published @newsmcp/openclaw@$VERSION"

echo ""
echo "=== Publishing to MCP Registry ==="
update_server_json_version "$VERSION"
mcp_publish_with_retry "$MCP_PUBLISHER"
echo "Published to MCP Registry"

echo ""
echo "=== Creating commit, tag, push, and GitHub release ==="
create_git_commit_tag_and_release "$VERSION"

echo ""
echo "=== Done ==="
echo "Published version $VERSION to npm + MCP Registry and created GitHub release."

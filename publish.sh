#!/usr/bin/env bash
set -euo pipefail

# Prepare and push a release tag that triggers .github/workflows/release.yml.
# Usage: ./publish.sh [patch|minor|major]
# Optional: SKIP_CHECKS=1 ./publish.sh patch

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

ensure_clean_worktree() {
  if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    echo "Working tree is not clean. Commit/stash changes before publishing."
    git -C "$ROOT" status --short
    exit 1
  fi
}

ensure_branch() {
  if [[ -z "$BRANCH" ]]; then
    echo "Detached HEAD is not supported for releases."
    exit 1
  fi
}

ensure_remote_tag_absent() {
  local tag="$1"
  if git -C "$ROOT" rev-parse "$tag" >/dev/null 2>&1; then
    echo "Tag $tag already exists locally."
    exit 1
  fi
  if git -C "$ROOT" ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
    echo "Tag $tag already exists on origin."
    exit 1
  fi
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

github_repo_slug() {
  local remote
  remote="$(git -C "$ROOT" config --get remote.origin.url || true)"
  if [[ "$remote" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

commit_tag_and_push() {
  local version="$1"
  local tag="v$version"

  ensure_remote_tag_absent "$tag"

  git -C "$ROOT" add \
    package-lock.json \
    packages/mcp-server/package.json \
    packages/openclaw-plugin/package.json \
    packages/mcp-server/server.json
  git -C "$ROOT" commit -m "Release $tag"
  git -C "$ROOT" tag -a "$tag" -m "$tag"
  git -C "$ROOT" push origin "$BRANCH"
  git -C "$ROOT" push origin "$tag"
}

require_cmd git
require_cmd npm
require_cmd node
ensure_branch
ensure_clean_worktree

echo "=== Bumping versions ==="
(cd "$SERVER_DIR" && npm version "$BUMP" --no-git-tag-version)
VERSION="$(node -p "require('$SERVER_DIR/package.json').version")"
(cd "$OPENCLAW_DIR" && npm version "$VERSION" --no-git-tag-version --allow-same-version)
update_server_json_version "$VERSION"

echo ""
echo "=== Updating lockfile ==="
(cd "$ROOT" && npm install --package-lock-only)

if [[ "${SKIP_CHECKS:-0}" != "1" ]]; then
  echo ""
  echo "=== Running checks ==="
  (cd "$SERVER_DIR" && npm run build)
  (cd "$OPENCLAW_DIR" && npm run typecheck)
fi

echo ""
echo "=== Committing and pushing release tag ==="
commit_tag_and_push "$VERSION"

echo ""
echo "=== Done ==="
echo "Pushed release commit and tag v$VERSION."
echo "GitHub Actions release workflow should start automatically."

REPO_SLUG="$(github_repo_slug || true)"
if [[ -n "$REPO_SLUG" ]]; then
  echo "Watch run: https://github.com/$REPO_SLUG/actions/workflows/release.yml"
  echo "Tag page:  https://github.com/$REPO_SLUG/releases/tag/v$VERSION"
fi

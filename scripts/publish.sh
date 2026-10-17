#!/usr/bin/env bash
# Publish the vendored tantivy fork (root package and its sub-crates) to
# crates.io under `kkkqkx-*` package names.
#
# The upstream `tantivy` family names are taken on crates.io, and this fork
# tracks upstream `main` where sub-crate content can be newer than the last
# published version at the same version number. The whole family is
# therefore renamed and published together; every package keeps its
# original library name so `use tantivy::` style imports are unaffected.
#
# Usage:
#   ./scripts/publish.sh           # real publish
#   ./scripts/publish.sh --dry-run # cargo publish --dry-run
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Dependency order: leaves first, the root `kkkqkx-tantivy` package last.
CRATES=(
    "ownedbytes"
    "bitpacker"
    "query-grammar"
    "tokenizer-api"
    "common"
    "jitexpr"
    "stacker"
    "sstable"
    "columnar"
    "."
)

for crate in "${CRATES[@]}"; do
    manifest="$REPO_ROOT/$crate/Cargo.toml"
    name=$(sed -n 's/^name *= *"\(.*\)".*/\1/p' "$manifest" | head -1)
    version=$(sed -n 's/^version *= *"\(.*\)".*/\1/p' "$manifest" | head -1)
    if [[ -z "$name" || -z "$version" ]]; then
        echo "ERROR: could not determine package name/version for $crate." >&2
        exit 1
    fi
    echo "=== Publishing $name v$version ==="
    # Skip if this version is already on crates.io (User-Agent is
    # required by the crates.io API).
    if curl -sf -A "tantivy-publish-script" -o /dev/null "https://crates.io/api/v1/crates/$name/$version"; then
        echo "Skipping $name v$version: already published."
        echo ""
        continue
    fi
    set +e
    if $DRY_RUN; then
        (cd "$REPO_ROOT/$crate" && cargo publish --dry-run --allow-dirty --registry crates-io)
    else
        (cd "$REPO_ROOT/$crate" && cargo publish --allow-dirty --registry crates-io)
    fi
    rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
        # In dry-run mode, unpublished family members cannot be resolved
        # from the real index yet; warn instead of aborting.
        if $DRY_RUN; then
            echo "WARNING: dry-run failed for $name (likely unpublished family deps); continuing."
        else
            exit $rc
        fi
    fi
    echo ""
done

echo "All crates published successfully."

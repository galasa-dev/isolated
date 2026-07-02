#! /usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------
#
# Objectives: Fix the Maven repository layout left by maven-dependency-plugin:copy-dependencies.
#
# copy-dependencies copies files from the local ~/.m2 cache rather than downloading from
# a remote. This means it places:
#   - _remote.repositories  (Maven Resolver internal cache bookkeeping — must not be distributed)
#   - maven-metadata-local.xml  (local-cache metadata — not recognised by Gradle as maven-metadata.xml)
#   - artifact files WITHOUT .md5 / .sha1 checksums
#
# This script fixes the target repo directory by:
#   1. Removing all _remote.repositories files.
#   2. Renaming maven-metadata-local.xml to maven-metadata.xml where no maven-metadata.xml
#      already exists (created by galasastaging-maven-plugin:deployartifacts2), then generating
#      its .md5 and .sha1 checksums. Where maven-metadata.xml already exists, just deletes
#      the local variant.
#   3. Generating .md5 and .sha1 checksum files for every artifact file that is missing them.
#
# Usage: fix-copy-dep-repo.sh <repo-dir>
#   repo-dir: path to the Maven repository root (e.g. full/target/isolated/maven)
#
#-----------------------------------------------------------------------------------------

set -e

if [[ -z "$1" ]]; then
    echo "Usage: $0 <repo-dir>"
    exit 1
fi

REPO_DIR="$1"

if [[ ! -d "${REPO_DIR}" ]]; then
    echo "Error: repo directory does not exist: ${REPO_DIR}"
    exit 1
fi

md5_of() {
    md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1
}

sha1_of() {
    shasum -a 1 "$1" 2>/dev/null | cut -d' ' -f1 || sha1sum "$1" | cut -d' ' -f1
}

echo "[fix-copy-dep-repo] Fixing repo at: ${REPO_DIR}"

# 1. Remove _remote.repositories files.
remote_repo_count=0
while IFS= read -r f; do
    rm -f "${f}"
    remote_repo_count=$((remote_repo_count + 1))
done < <(find "${REPO_DIR}" -name "_remote.repositories" -type f)
echo "[fix-copy-dep-repo] Removed ${remote_repo_count} _remote.repositories files."

# 2. Handle maven-metadata-local.xml files.
local_meta_count=0
renamed_meta_count=0
while IFS= read -r local_meta; do
    dir=$(dirname "${local_meta}")
    proper_meta="${dir}/maven-metadata.xml"
    if [[ -f "${proper_meta}" ]]; then
        # deployartifacts2 already wrote a proper maven-metadata.xml here — discard the local copy.
        rm -f "${local_meta}"
        local_meta_count=$((local_meta_count + 1))
    else
        # No proper metadata exists yet — promote the local copy.
        mv "${local_meta}" "${proper_meta}"
        md5_of "${proper_meta}" > "${proper_meta}.md5"
        sha1_of "${proper_meta}" > "${proper_meta}.sha1"
        renamed_meta_count=$((renamed_meta_count + 1))
    fi
done < <(find "${REPO_DIR}" -name "maven-metadata-local.xml" -type f)
echo "[fix-copy-dep-repo] Deleted ${local_meta_count} redundant maven-metadata-local.xml files."
echo "[fix-copy-dep-repo] Promoted ${renamed_meta_count} maven-metadata-local.xml -> maven-metadata.xml."

# 3. Generate missing .md5 and .sha1 checksums for artifact files.
checksum_count=0
while IFS= read -r f; do
    if [[ ! -f "${f}.md5" ]]; then
        md5_of "${f}" > "${f}.md5"
        checksum_count=$((checksum_count + 1))
    fi
    if [[ ! -f "${f}.sha1" ]]; then
        sha1_of "${f}" > "${f}.sha1"
        checksum_count=$((checksum_count + 1))
    fi
done < <(find "${REPO_DIR}" -type f \
    ! -name "*.md5" \
    ! -name "*.sha1" \
    ! -name "_remote.repositories" \
    ! -name "maven-metadata-local.xml" \
    ! -name "maven-metadata.xml")
echo "[fix-copy-dep-repo] Generated ${checksum_count} missing checksum files."

echo "[fix-copy-dep-repo] Done."

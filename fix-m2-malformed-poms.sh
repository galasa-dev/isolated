#! /usr/bin/env bash

#
# Copyright contributors to the Galasa project
#
# SPDX-License-Identifier: EPL-2.0
#

#-----------------------------------------------------------------------------------------
#
# Objectives: Fix malformed POM files in Maven repositories.
#
# Some third-party POMs (e.g. javax.jms:javax.jms-api:2.0.1) contain duplicate
# build.plugins.plugin declarations. Maven 3.9+ treats this as a FATAL error when
# building the effective model during dependency resolution, causing builds that use
# maven-dependency-plugin:copy-dependencies with addParentPoms=true to fail.
#
# This script scans one or more Maven repository directories for such POMs and
# deduplicates the plugin blocks in-place (keeping the first occurrence of each
# groupId:artifactId pair), so the build can proceed without artifact-specific
# workarounds.
#
# Usage: fix-m2-malformed-poms.sh [repo-dir ...]
#   repo-dir: one or more paths to scan. When no arguments are given the Maven
#             local cache is resolved via 'mvn help:evaluate', falling back to
#             ~/.m2/repository.
#
#-----------------------------------------------------------------------------------------

# Build the list of directories to scan.
if [[ $# -gt 0 ]]; then
    scan_dirs=("$@")
else
    # No arguments — resolve the Maven local cache path.
    if command -v mvn &>/dev/null; then
        m2_repo=$(mvn help:evaluate -Dexpression=settings.localRepository -q --batch-mode -DforceStdout 2>/dev/null || true)
    fi
    if [[ -z "${m2_repo}" ]]; then
        m2_repo="${HOME}/.m2/repository"
    fi
    scan_dirs=("${m2_repo}")
fi

fixed=0

fix_poms_in_dir() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        echo "[fix-m2-malformed-poms] Skipping ${dir} — directory not found."
        return 0
    fi
    echo "[fix-m2-malformed-poms] Scanning ${dir} for malformed POMs..."

    while IFS= read -r pom_file; do
        # Quick pre-filter: skip POMs with no chance of duplicate plugins.
        plugin_count=$(grep -c "<plugin>" "${pom_file}" 2>/dev/null || true)
        if [[ "${plugin_count}" -lt 2 ]]; then
            continue
        fi

        # Use awk to deduplicate <plugin>...</plugin> blocks by groupId:artifactId.
        # awk exits 1 if duplicates were found and removed, 0 otherwise.
        tmp_file=$(mktemp)
        awk '
            /<plugin>/ && plugin_depth == 0 {
                in_plugin = 1
                plugin_depth = 1
                plugin_buf = $0 "\n"
                group_id = ""
                artifact_id = ""
                next
            }
            in_plugin {
                plugin_buf = plugin_buf $0 "\n"
                if ($0 ~ /<plugin>/) plugin_depth++
                if ($0 ~ /<\/plugin>/) plugin_depth--

                if (group_id == "" && $0 ~ /<groupId>/) {
                    val = $0
                    sub(/.*<groupId>[[:space:]]*/, "", val)
                    sub(/[[:space:]]*<\/groupId>.*/, "", val)
                    group_id = val
                }
                if (artifact_id == "" && $0 ~ /<artifactId>/) {
                    val = $0
                    sub(/.*<artifactId>[[:space:]]*/, "", val)
                    sub(/[[:space:]]*<\/artifactId>.*/, "", val)
                    artifact_id = val
                }

                if (plugin_depth == 0) {
                    key = group_id ":" artifact_id
                    if (key != ":" && (key in seen)) {
                        changed = 1
                    } else {
                        seen[key] = 1
                        printf "%s", plugin_buf
                    }
                    in_plugin = 0
                    plugin_buf = ""
                    group_id = ""
                    artifact_id = ""
                }
                next
            }
            /<\/plugins>/ {
                delete seen
                print
                next
            }
            { print }
            END { exit (changed ? 1 : 0) }
        ' "${pom_file}" > "${tmp_file}"
        awk_rc=$?
        if [[ "${awk_rc}" -eq 1 ]]; then
            mv "${tmp_file}" "${pom_file}"
            fixed=$((fixed + 1))
            echo "[fix-m2-malformed-poms] Fixed duplicate plugins in: ${pom_file}"
        else
            rm -f "${tmp_file}"
        fi
    done < <(find "${dir}" -name "*.pom" -type f)
}

for scan_dir in "${scan_dirs[@]}"; do
    fix_poms_in_dir "${scan_dir}"
done

echo "[fix-m2-malformed-poms] Done. Fixed ${fixed} POM(s)."

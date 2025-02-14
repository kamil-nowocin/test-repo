#!/usr/bin/env bash
set -e

# 1. Make sure we have the latest 'main' branch so we can compare.
git fetch origin main

# 2. Get the list of changed files relative to 'main'.
CHANGED_FILES=$(git diff --name-only origin/main...HEAD)
echo "Changed files:"
echo "$CHANGED_FILES"
echo

# 3. Define modules (no hardcoded test class names)
MODULES=("WFE_service-okta-auth" "WFE_service-mastercard")

# 4. Function to detect and run impacted tests dynamically
run_impacted_tests_for_module() {
  local module_dir="$1"
  local -a gradle_test_args=()

  # Find all changed test files in this module
  for file in $CHANGED_FILES; do
    if [[ "$file" == "${module_dir}/src/test/java/core/tests/"*".java" ]]; then
      # Convert file path to fully qualified test class name
      test_class=$(echo "$file" | sed -E "s|${module_dir}/src/test/java/||" | sed 's|/|.|g' | sed 's|.java||')
      gradle_test_args+=(--tests "$test_class")
    fi
  done

  # If we found any impacted test files, run them in a single Gradle command
  if [ ${#gradle_test_args[@]} -gt 0 ]; then
    echo "Impacted test classes for '${module_dir}':"
    for test in "${gradle_test_args[@]}"; do
      echo "  $test"
    done
    echo

    # Run one Gradle command with multiple "--tests" arguments
    ./gradlew "${module_dir}:test" "${gradle_test_args[@]}"
    echo
  else
    echo "No impacted test classes found in '${module_dir}'. Skipping."
    echo
  fi
}

# 5. Check and run tests for each module:
for module in "${MODULES[@]}"; do
  run_impacted_tests_for_module "$module"
done

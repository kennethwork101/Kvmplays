#!/bin/bash
# Enhanced test report generation script with versioning support

# The first argument is the project directory
PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
    echo "Error: Project directory not specified."
    echo "Usage: $0 <project_directory>"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# Create a reports directory if it doesn't exist
REPORTS_DIR="test_reports"
mkdir -p "$REPORTS_DIR"

# Create a timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Determine the run index by checking existing reports
if [ -f "$REPORTS_DIR/run_counter.txt" ]; then
    RUN_INDEX=$(<"$REPORTS_DIR/run_counter.txt")
    RUN_INDEX=$((RUN_INDEX + 1))
else
    RUN_INDEX=1
fi
echo "$RUN_INDEX" > "$REPORTS_DIR/run_counter.txt"

# Create a unique directory for this run
RUN_DIR="$REPORTS_DIR/run_${RUN_INDEX}_${TIMESTAMP}"
mkdir -p "$RUN_DIR"

echo "Working in directory: $(pwd)" > "$RUN_DIR/debug_report.txt"
echo "Run Index: $RUN_INDEX" >> "$RUN_DIR/debug_report.txt"
echo "Timestamp: $TIMESTAMP" >> "$RUN_DIR/debug_report.txt"
echo "Files in directory:" >> "$RUN_DIR/debug_report.txt"
ls -la >> "$RUN_DIR/debug_report.txt"

# Find all subdirectories containing a test_results.xml file
echo "Searching for test_results.xml files..." >> "$RUN_DIR/debug_report.txt"
FOUND_XML_FILES=0

# Create Markdown report
REPORT_MD="$RUN_DIR/test_report_${RUN_INDEX}.md"
echo "# Test Report #$RUN_INDEX" > "$REPORT_MD"
echo "Generated: $(date)" >> "$REPORT_MD"
echo "" >> "$REPORT_MD"

echo "## Test Results Summary" >> "$REPORT_MD"
echo "" >> "$REPORT_MD"
echo "| Tests | Passed | Failed | Errors | Skipped | Time (s) | Repository |" >> "$REPORT_MD"
echo "|-------|--------|--------|--------|---------|----------|------------|" >> "$REPORT_MD"

# Variables to store overall statistics
OVERALL_TOTAL=0
OVERALL_PASSED=0
OVERALL_FAILED=0
OVERALL_ERRORS=0
OVERALL_SKIPPED=0
OVERALL_TIME=0

# Array to store repository results for comparison
declare -a REPOS_ARRAY

# Look for test_results.xml in the current directory and all subdirectories
for xml_file in $(find . -name "test_results.xml" -type f); do
    echo "Found XML file: $xml_file" >> "$RUN_DIR/debug_report.txt"
    FOUND_XML_FILES=$((FOUND_XML_FILES+1))

    # Get the directory name (repo)
    repo_dir=$(dirname "$xml_file" | sed 's|^\./||')
    if [ "$repo_dir" = "." ]; then
        repo_dir="root"
    fi

    echo "Processing repository: $repo_dir" >> "$RUN_DIR/debug_report.txt"

    # Extract basic statistics using grep and sed
    total_tests=$(grep -o 'tests="[0-9]*"' "$xml_file" | head -1 | sed 's/tests="\([0-9]*\)"/\1/')
    failures=$(grep -o 'failures="[0-9]*"' "$xml_file" | head -1 | sed 's/failures="\([0-9]*\)"/\1/')
    errors=$(grep -o 'errors="[0-9]*"' "$xml_file" | head -1 | sed 's/errors="\([0-9]*\)"/\1/')
    skipped=$(grep -o 'skipped="[0-9]*"' "$xml_file" | head -1 | sed 's/skipped="\([0-9]*\)"/\1/')
    time=$(grep -o 'time="[0-9.]*"' "$xml_file" | head -1 | sed 's/time="\([0-9.]*\)"/\1/')

    # Calculate passed tests
    passed=$((total_tests - failures - errors - skipped))

    # Add to overall statistics
    OVERALL_TOTAL=$((OVERALL_TOTAL + total_tests))
    OVERALL_PASSED=$((OVERALL_PASSED + passed))
    OVERALL_FAILED=$((OVERALL_FAILED + failures))
    OVERALL_ERRORS=$((OVERALL_ERRORS + errors))
    OVERALL_SKIPPED=$((OVERALL_SKIPPED + skipped))
    OVERALL_TIME=$(echo "$OVERALL_TIME + $time" | bc)

    # Store for comparison
    REPOS_ARRAY+=("$repo_dir,$total_tests,$passed,$failures,$errors,$skipped,$time")

    # Add to the summary table with proper spacing to match header
    printf "| %-5s | %-6s | %-6s | %-6s | %-7s | %-8s | %-10s |\n" "$total_tests" "$passed" "$failures" "$errors" "$skipped" "$time" "$repo_dir" >> "$REPORT_MD"
done

if [ $FOUND_XML_FILES -eq 0 ]; then
    echo "No test_results.xml files found" >> "$RUN_DIR/debug_report.txt"
    echo "| - | - | - | - | - | - | No test results found |" >> "$REPORT_MD"
fi

# Add overall statistics
echo "" >> "$REPORT_MD"
echo "### Overall Statistics" >> "$REPORT_MD"
echo "" >> "$REPORT_MD"
echo "| Metric | Value |" >> "$REPORT_MD"
echo "|--------|-------|" >> "$REPORT_MD"
echo "| Total Tests | $OVERALL_TOTAL |" >> "$REPORT_MD"
echo "| Passed | $OVERALL_PASSED |" >> "$REPORT_MD"
echo "| Failed | $OVERALL_FAILED |" >> "$REPORT_MD"
echo "| Errors | $OVERALL_ERRORS |" >> "$REPORT_MD"
echo "| Skipped | $OVERALL_SKIPPED |" >> "$REPORT_MD"
echo "| Total Time | $OVERALL_TIME s |" >> "$REPORT_MD"
echo "| Repositories Tested | $FOUND_XML_FILES |" >> "$REPORT_MD"
echo "" >> "$REPORT_MD"

# Compare with previous run if available
if [ $RUN_INDEX -gt 1 ]; then
    PREV_INDEX=$((RUN_INDEX - 1))
    PREV_REPORTS=$(find "$REPORTS_DIR" -name "run_${PREV_INDEX}_*" -type d | sort -r | head -1)

    if [ -n "$PREV_REPORTS" ] && [ -f "$PREV_REPORTS/repos_data.csv" ]; then
        echo "## Comparison with Previous Run (#$PREV_INDEX)" >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"
        echo "| Repository | Status | Tests Δ | Passed Δ | Failed Δ | Time Δ |" >> "$REPORT_MD"
        echo "|------------|--------|---------|----------|----------|--------|" >> "$REPORT_MD"

        while IFS= read -r prev_line; do
            IFS=',' read -r prev_repo prev_total prev_passed prev_failed prev_errors prev_skipped prev_time <<< "$prev_line"

            # Find matching repo in current run
            for current in "${REPOS_ARRAY[@]}"; do
                IFS=',' read -r curr_repo curr_total curr_passed curr_failed curr_errors curr_skipped curr_time <<< "$current"

                if [ "$prev_repo" = "$curr_repo" ]; then
                    # Calculate deltas
                    tests_delta=$((curr_total - prev_total))
                    passed_delta=$((curr_passed - prev_passed))
                    failed_delta=$((curr_failed - prev_failed + curr_errors - prev_errors))  # Combine failures and errors for simplicity
                    time_delta=$(echo "$curr_time - $prev_time" | bc)

                    # Determine status
                    if [ $failed_delta -lt 0 ]; then
                        status="✅ Improved"
                    elif [ $failed_delta -gt 0 ]; then
                        status="❌ Regressed"
                    elif [ $passed_delta -gt 0 ]; then
                        status="✅ More tests"
                    elif [ $passed_delta -lt 0 ]; then
                        status="⚠️ Fewer tests"
                    else
                        status="✓ Unchanged"
                    fi

                    # Format deltas with +/- signs
                    if [ $tests_delta -gt 0 ]; then
                        tests_delta_fmt="+$tests_delta"
                    else
                        tests_delta_fmt="$tests_delta"
                    fi

                    if [ $passed_delta -gt 0 ]; then
                        passed_delta_fmt="+$passed_delta"
                    else
                        passed_delta_fmt="$passed_delta"
                    fi

                    if [ $failed_delta -gt 0 ]; then
                        failed_delta_fmt="+$failed_delta"
                    else
                        failed_delta_fmt="$failed_delta"
                    fi

                    time_delta=$(printf "%.3f" "$time_delta")
                    if (( $(echo "$time_delta > 0" | bc -l) )); then
                        time_delta_fmt="+$time_delta"
                    else
                        time_delta_fmt="$time_delta"
                    fi

                    printf "| %-8s | %-7s | %-8s | %-8s | %-6s | %-10s |\n" "$status" "$tests_delta_fmt" "$passed_delta_fmt" "$failed_delta_fmt" "$time_delta_fmt" "$curr_repo" >> "$REPORT_MD"
                    break
                fi
            done
        done < "$PREV_REPORTS/repos_data.csv"

        echo "" >> "$REPORT_MD"
    fi
fi

# Save repository data for future comparisons
REPOS_CSV="$RUN_DIR/repos_data.csv"
for repo in "${REPOS_ARRAY[@]}"; do
    echo "$repo" >> "$REPOS_CSV"
done

echo "" >> "$REPORT_MD"

# Process each repository's XML file in detail
for xml_file in $(find . -name "test_results.xml" -type f); do
    repo_dir=$(dirname "$xml_file" | sed 's|^\./||')
    if [ "$repo_dir" = "." ]; then
        repo_dir="root"
    fi

    echo "## Detailed Results: $repo_dir" >> "$REPORT_MD"
    echo "" >> "$REPORT_MD"

    # Extract statistics
    total_tests=$(grep -o 'tests="[0-9]*"' "$xml_file" | head -1 | sed 's/tests="\([0-9]*\)"/\1/')
    failures=$(grep -o 'failures="[0-9]*"' "$xml_file" | head -1 | sed 's/failures="\([0-9]*\)"/\1/')
    errors=$(grep -o 'errors="[0-9]*"' "$xml_file" | head -1 | sed 's/errors="\([0-9]*\)"/\1/')
    skipped=$(grep -o 'skipped="[0-9]*"' "$xml_file" | head -1 | sed 's/skipped="\([0-9]*\)"/\1/')
    time=$(grep -o 'time="[0-9.]*"' "$xml_file" | head -1 | sed 's/time="\([0-9.]*\)"/\1/')
    timestamp=$(grep -o 'timestamp="[^"]*"' "$xml_file" | head -1 | sed 's/timestamp="\([^"]*\)"/\1/')

    # Write details
    echo "### Summary" >> "$REPORT_MD"
    echo "" >> "$REPORT_MD"
    echo "- **Timestamp:** $timestamp" >> "$REPORT_MD"
    echo "- **Total Tests:** $total_tests" >> "$REPORT_MD"
    echo "- **Passed:** $((total_tests - failures - errors - skipped))" >> "$REPORT_MD"
    echo "- **Failed:** $failures" >> "$REPORT_MD"
    echo "- **Errors:** $errors" >> "$REPORT_MD"
    echo "- **Skipped:** $skipped" >> "$REPORT_MD"
    echo "- **Time:** ${time}s" >> "$REPORT_MD"
    echo "" >> "$REPORT_MD"

    # Extract test cases
    echo "### Test Cases" >> "$REPORT_MD"
    echo "" >> "$REPORT_MD"
    echo "| Result | Time (s) | Test |" >> "$REPORT_MD"
    echo "|--------|----------|------|" >> "$REPORT_MD"

    # Use xmllint or grep to extract testcase information
    if command -v xmllint > /dev/null; then
        # Using xmllint if available
        test_cases=$(xmllint --xpath "//testcase" "$xml_file" 2>/dev/null)
        echo "$test_cases" | grep -o 'classname="[^"]*"[^>]*name="[^"]*"[^>]*time="[0-9.]*"' |
        while read -r line; do
            classname=$(echo "$line" | grep -o 'classname="[^"]*"' | sed 's/classname="\([^"]*\)"/\1/')
            name=$(echo "$line" | grep -o 'name="[^"]*"' | sed 's/name="\([^"]*\)"/\1/')
            time=$(echo "$line" | grep -o 'time="[0-9.]*"' | sed 's/time="\([0-9.]*\)"/\1/')

            # Check if it has a failure/error
            result="Pass"
            if grep -q "<failure.*$name" "$xml_file"; then
                result="Fail"
            elif grep -q "<error.*$name" "$xml_file"; then
                result="Error"
            fi

            # Print with proper spacing - Test at the end
            printf "| %-6s | %-8s | %-50s |\n" "$result" "$time" "$classname::$name" >> "$REPORT_MD"
        done
    else
        # Fallback to basic grep and sed
        grep -o '<testcase[^>]*' "$xml_file" |
        while read -r line; do
            classname=$(echo "$line" | grep -o 'classname="[^"]*"' | sed 's/classname="\([^"]*\)"/\1/')
            name=$(echo "$line" | grep -o 'name="[^"]*"' | sed 's/name="\([^"]*\)"/\1/')
            time=$(echo "$line" | grep -o 'time="[0-9.]*"' | sed 's/time="\([0-9.]*\)"/\1/')

            # Check if it's in a failure section
            full_name="${classname}::${name}"
            if grep -A5 '<failure' "$xml_file" | grep -q "$name"; then
                result="Fail"
            else
                result="Pass"
            fi

            # Print with proper spacing - Test at the end
            printf "| %-6s | %-8s | %-50s |\n" "$result" "$time" "$full_name" >> "$REPORT_MD"
        done
    fi

    echo "" >> "$REPORT_MD"

    # Check if there are any test failures and include details
    if [ "$failures" -gt 0 ] || [ "$errors" -gt 0 ]; then
        echo "### Failed Tests" >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"

        grep -A10 '<failure' "$xml_file" | sed 's/^/    /' >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"
    fi
done

# Check for pytest_output.log
if [ -f "pytest_output.log" ]; then
    # Copy the log to the run directory with proper naming
    cp "pytest_output.log" "$RUN_DIR/pytest_output_${RUN_INDEX}.log"

    echo "## Pytest Console Output" >> "$REPORT_MD"
    echo "" >> "$REPORT_MD"

    # Extract summary
    summary=$(grep "= .* failed, .* passed" pytest_output.log | tail -1)
    if [ -n "$summary" ]; then
        echo "### Summary" >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"
        echo "```" >> "$REPORT_MD"
        echo "$summary" >> "$REPORT_MD"
        echo "```" >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"
    fi

    # Extract failures
    failures=$(grep -A20 "= FAILURES =" pytest_output.log)
    if [ -n "$failures" ]; then
        echo "### Failures" >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"
        echo "```" >> "$REPORT_MD"
        echo "$failures" >> "$REPORT_MD"
        echo "```" >> "$REPORT_MD"
        echo "" >> "$REPORT_MD"
    fi
fi

echo "Found $FOUND_XML_FILES test_results.xml files" >> "$RUN_DIR/debug_report.txt"

# Create JSON report
REPORT_JSON="$RUN_DIR/test_report_${RUN_INDEX}.json"
cat > "$REPORT_JSON" << EOF
{
  "run_index": $RUN_INDEX,
  "generated": "$(date)",
  "timestamp": "$TIMESTAMP",
  "summary": {
    "repositories_tested": $FOUND_XML_FILES,
    "total_tests": $OVERALL_TOTAL,
    "passed": $OVERALL_PASSED,
    "failed": $OVERALL_FAILED,
    "errors": $OVERALL_ERRORS,
    "skipped": $OVERALL_SKIPPED,
    "time": $OVERALL_TIME
  }
}
EOF

# Create CSV report
REPORT_CSV="$RUN_DIR/test_report_${RUN_INDEX}.csv"
echo "Metric,Value" > "$REPORT_CSV"
echo "Run Index,$RUN_INDEX" >> "$REPORT_CSV"
echo "Timestamp,$TIMESTAMP" >> "$REPORT_CSV"
echo "Repositories Tested,$FOUND_XML_FILES" >> "$REPORT_CSV"
echo "Total Tests,$OVERALL_TOTAL" >> "$REPORT_CSV"
echo "Passed,$OVERALL_PASSED" >> "$REPORT_CSV"
echo "Failed,$OVERALL_FAILED" >> "$REPORT_CSV"
echo "Errors,$OVERALL_ERRORS" >> "$REPORT_CSV"
echo "Skipped,$OVERALL_SKIPPED" >> "$REPORT_CSV"
echo "Total Time,$OVERALL_TIME" >> "$REPORT_CSV"

# Create/update the index file
INDEX_FILE="$REPORTS_DIR/index.md"

# If this is the first run, create the index file header
if [ $RUN_INDEX -eq 1 ]; then
    echo "# Test Reports Index" > "$INDEX_FILE"
    echo "" >> "$INDEX_FILE"
    echo "| Run # | Date | Tests | Pass Rate | Failed | Status |" >> "$INDEX_FILE"
    echo "|-------|------|-------|-----------|--------|--------|" >> "$INDEX_FILE"
fi

# Calculate pass rate
if [ $OVERALL_TOTAL -gt 0 ]; then
    PASS_RATE=$(echo "scale=2; $OVERALL_PASSED * 100 / $OVERALL_TOTAL" | bc)
else
    PASS_RATE=0
fi

# Determine status based on failures
if [ $OVERALL_FAILED -eq 0 ] && [ $OVERALL_ERRORS -eq 0 ]; then
    if [ $OVERALL_TOTAL -eq 0 ]; then
        STATUS="⚠️ No Tests"
    else
        STATUS="✅ All Passed"
    fi
elif [ $OVERALL_FAILED -gt 0 ] || [ $OVERALL_ERRORS -gt 0 ]; then
    FAIL_PERCENT=$(echo "scale=2; ($OVERALL_FAILED + $OVERALL_ERRORS) * 100 / $OVERALL_TOTAL" | bc)
    if (( $(echo "$FAIL_PERCENT > 20" | bc -l) )); then
        STATUS="❌ Major Issues"
    else
        STATUS="⚠️ Minor Issues"
    fi
fi

# Add entry to index with relative link
RUN_DATE=$(date +"%Y-%m-%d %H:%M")
RELATIVE_PATH="run_${RUN_INDEX}_${TIMESTAMP}/test_report_${RUN_INDEX}.md"
printf "| %-5s | %-19s | %-5s | %-9s%% | %-6s | %-9s | %-12s |\n" \
    "$RUN_INDEX" "$RUN_DATE" "$OVERALL_TOTAL" "$PASS_RATE" "$((OVERALL_FAILED + OVERALL_ERRORS))" "[View]($RELATIVE_PATH)" "$STATUS" >> "$INDEX_FILE"

# Create HTML index for easier viewing
HTML_INDEX="$REPORTS_DIR/index.html"
cat > "$HTML_INDEX" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Reports Index</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr:hover {background-color: #f5f5f5;}
        .pass { color: green; }
        .fail { color: red; }
        .warn { color: orange; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Test Reports Index</h1>
    <p>Last updated: $(date)</p>
    <table>
        <tr>
            <th>Run #</th>
            <th>Date</th>
            <th>Tests</th>
            <th>Pass Rate</th>
            <th>Failed</th>
            <th>Actions</th>
            <th>Status</th>
        </tr>
EOF

# Add entries for all runs (newest first)
for idx in $(seq $RUN_INDEX -1 1); do
    # Find the run directory
    run_dir=$(find "$REPORTS_DIR" -name "run_${idx}_*" -type d | sort -r | head -1)
    if [ -n "$run_dir" ] && [ -f "$run_dir/test_report_${idx}.json" ]; then
        # Extract data from JSON
        run_date=$(jq -r '.generated' "$run_dir/test_report_${idx}.json" 2>/dev/null)
        total=$(jq -r '.summary.total_tests' "$run_dir/test_report_${idx}.json" 2>/dev/null)
        passed=$(jq -r '.summary.passed' "$run_dir/test_report_${idx}.json" 2>/dev/null)
        failed=$(jq -r '.summary.failed' "$run_dir/test_report_${idx}.json" 2>/dev/null)
        errors=$(jq -r '.summary.errors' "$run_dir/test_report_${idx}.json" 2>/dev/null)

        # Calculate pass rate
        if [ "$total" != "null" ] && [ "$total" -gt 0 ]; then
            pass_rate=$(echo "scale=2; $passed * 100 / $total" | bc)
        else
            pass_rate=0
            total=0
        fi

        # Determine status class for coloring
        if [ "$failed" = "null" ]; then failed=0; fi
        if [ "$errors" = "null" ]; then errors=0; fi

        total_issues=$((failed + errors))
        if [ $total_issues -eq 0 ]; then
            if [ $total -eq 0 ]; then
                status_class="warn"
                status="No Tests"
            else
                status_class="pass"
                status="All Passed"
            fi
        else
            fail_percent=$(echo "scale=2; $total_issues * 100 / $total" | bc)
            if (( $(echo "$fail_percent > 20" | bc -l) )); then
                status_class="fail"
                status="Major Issues"
            else
                status_class="warn"
                status="Minor Issues"
            fi
        fi

        # Add to HTML
        rel_path=$(basename "$run_dir")/test_report_${idx}.md
        cat >> "$HTML_INDEX" << EOF
        <tr>
            <td>${idx}</td>
            <td>${run_date}</td>
            <td>${total}</td>
            <td>${pass_rate}%</td>
            <td>${total_issues}</td>
            <td><a href="${rel_path}">View Report</a></td>
            <td class="${status_class}">${status}</td>
        </tr>
EOF
    fi
done

# Close the HTML
cat >> "$HTML_INDEX" << EOF
    </table>
</body>
</html>
EOF

# Create symbolic links to latest reports for easy access
ln -sf "$RUN_DIR/test_report_${RUN_INDEX}.md" "$REPORTS_DIR/latest_report.md"
ln -sf "$RUN_DIR/test_report_${RUN_INDEX}.json" "$REPORTS_DIR/latest_report.json"
ln -sf "$RUN_DIR/test_report_${RUN_INDEX}.csv" "$REPORTS_DIR/latest_report.csv"

echo "Reports generated successfully in $RUN_DIR"
echo "View the index at $REPORTS_DIR/index.html"

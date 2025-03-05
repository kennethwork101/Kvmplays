#!/bin/bash
# Enhanced test report generation script

# The first argument is the project directory
PROJECT_DIR="$1"
if [ -z "$PROJECT_DIR" ]; then
    echo "Error: Project directory not specified."
    echo "Usage: $0 <project_directory>"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

echo "Working in directory: $(pwd)" > debug_report.txt
echo "Files in directory:" >> debug_report.txt
ls -la >> debug_report.txt

# Find all subdirectories containing a test_results.xml file
echo "Searching for test_results.xml files..." >> debug_report.txt
FOUND_XML_FILES=0

# Create Markdown report
echo "# Test Report" > test_report.md
echo "Generated: $(date)" >> test_report.md
echo "" >> test_report.md

echo "## Test Results Summary" >> test_report.md
echo "" >> test_report.md
echo "| Repository | Tests | Passed | Failed | Errors | Skipped | Time (s) |" >> test_report.md
echo "|------------|-------|--------|--------|--------|---------|----------|" >> test_report.md

# Look for test_results.xml in the current directory and all subdirectories
for xml_file in $(find . -name "test_results.xml" -type f); do
    echo "Found XML file: $xml_file" >> debug_report.txt
    FOUND_XML_FILES=$((FOUND_XML_FILES+1))

    # Get the directory name (repo)
    repo_dir=$(dirname "$xml_file" | sed 's|^\./||')
    if [ "$repo_dir" = "." ]; then
        repo_dir="root"
    fi

    echo "Processing repository: $repo_dir" >> debug_report.txt

    # Extract basic statistics using grep and sed
    total_tests=$(grep -o 'tests="[0-9]*"' "$xml_file" | head -1 | sed 's/tests="\([0-9]*\)"/\1/')
    failures=$(grep -o 'failures="[0-9]*"' "$xml_file" | head -1 | sed 's/failures="\([0-9]*\)"/\1/')
    errors=$(grep -o 'errors="[0-9]*"' "$xml_file" | head -1 | sed 's/errors="\([0-9]*\)"/\1/')
    skipped=$(grep -o 'skipped="[0-9]*"' "$xml_file" | head -1 | sed 's/skipped="\([0-9]*\)"/\1/')
    time=$(grep -o 'time="[0-9.]*"' "$xml_file" | head -1 | sed 's/time="\([0-9.]*\)"/\1/')

    # Calculate passed tests
    passed=$((total_tests - failures - errors - skipped))

    # Add to the summary table
    echo "| $repo_dir | $total_tests | $passed | $failures | $errors | $skipped | $time |" >> test_report.md
done

if [ $FOUND_XML_FILES -eq 0 ]; then
    echo "No test_results.xml files found" >> debug_report.txt
    echo "| No test results found | - | - | - | - | - | - |" >> test_report.md
fi

echo "" >> test_report.md

# Process each repository's XML file in detail
for xml_file in $(find . -name "test_results.xml" -type f); do
    repo_dir=$(dirname "$xml_file" | sed 's|^\./||')
    if [ "$repo_dir" = "." ]; then
        repo_dir="root"
    fi

    echo "## Detailed Results: $repo_dir" >> test_report.md
    echo "" >> test_report.md

    # Extract statistics
    total_tests=$(grep -o 'tests="[0-9]*"' "$xml_file" | head -1 | sed 's/tests="\([0-9]*\)"/\1/')
    failures=$(grep -o 'failures="[0-9]*"' "$xml_file" | head -1 | sed 's/failures="\([0-9]*\)"/\1/')
    errors=$(grep -o 'errors="[0-9]*"' "$xml_file" | head -1 | sed 's/errors="\([0-9]*\)"/\1/')
    skipped=$(grep -o 'skipped="[0-9]*"' "$xml_file" | head -1 | sed 's/skipped="\([0-9]*\)"/\1/')
    time=$(grep -o 'time="[0-9.]*"' "$xml_file" | head -1 | sed 's/time="\([0-9.]*\)"/\1/')
    timestamp=$(grep -o 'timestamp="[^"]*"' "$xml_file" | head -1 | sed 's/timestamp="\([^"]*\)"/\1/')

    # Write details
    echo "### Summary" >> test_report.md
    echo "" >> test_report.md
    echo "- **Timestamp:** $timestamp" >> test_report.md
    echo "- **Total Tests:** $total_tests" >> test_report.md
    echo "- **Passed:** $((total_tests - failures - errors - skipped))" >> test_report.md
    echo "- **Failed:** $failures" >> test_report.md
    echo "- **Errors:** $errors" >> test_report.md
    echo "- **Skipped:** $skipped" >> test_report.md
    echo "- **Time:** ${time}s" >> test_report.md
    echo "" >> test_report.md

    # Extract test cases
    echo "### Test Cases" >> test_report.md
    echo "" >> test_report.md
    echo "| Test | Result | Time (s) |" >> test_report.md
    echo "|------|--------|----------|" >> test_report.md

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

            echo "| $classname::$name | $result | $time |" >> test_report.md
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

            echo "| $full_name | $result | $time |" >> test_report.md
        done
    fi

    echo "" >> test_report.md

    # Check if there are any test failures and include details
    if [ "$failures" -gt 0 ] || [ "$errors" -gt 0 ]; then
        echo "### Failed Tests" >> test_report.md
        echo "" >> test_report.md

        grep -A10 '<failure' "$xml_file" | sed 's/^/    /' >> test_report.md
        echo "" >> test_report.md
    fi
done

# Check for pytest_output.log
if [ -f "pytest_output.log" ]; then
    echo "## Pytest Console Output" >> test_report.md
    echo "" >> test_report.md

    # Extract summary
    summary=$(grep "= .* failed, .* passed" pytest_output.log | tail -1)
    if [ -n "$summary" ]; then
        echo "### Summary" >> test_report.md
        echo "" >> test_report.md
        echo "```" >> test_report.md
        echo "$summary" >> test_report.md
        echo "```" >> test_report.md
        echo "" >> test_report.md
    fi

    # Extract failures
    failures=$(grep -A20 "= FAILURES =" pytest_output.log)
    if [ -n "$failures" ]; then
        echo "### Failures" >> test_report.md
        echo "" >> test_report.md
        echo "```" >> test_report.md
        echo "$failures" >> test_report.md
        echo "```" >> test_report.md
        echo "" >> test_report.md
    fi
fi

echo "Found $FOUND_XML_FILES test_results.xml files" >> debug_report.txt

# Create JSON report
cat > test_report.json << EOF
{
  "generated": "$(date)",
  "summary": {
    "repositories_tested": $FOUND_XML_FILES,
    "total_tests": ${total_tests:-0},
    "passed": $((${total_tests:-0} - ${failures:-0} - ${errors:-0} - ${skipped:-0})),
    "failed": ${failures:-0},
    "errors": ${errors:-0},
    "skipped": ${skipped:-0},
    "time": ${time:-0}
  }
}
EOF

# Create CSV report
echo "Metric,Value" > test_report.csv
echo "Repositories Tested,$FOUND_XML_FILES" >> test_report.csv
echo "Total Tests,${total_tests:-0}" >> test_report.csv
echo "Passed,$((${total_tests:-0} - ${failures:-0} - ${errors:-0} - ${skipped:-0}))" >> test_report.csv
echo "Failed,${failures:-0}" >> test_report.csv
echo "Errors,${errors:-0}" >> test_report.csv
echo "Skipped,${skipped:-0}" >> test_report.csv
echo "Time,${time:-0}" >> test_report.csv

echo "Reports generated successfully."

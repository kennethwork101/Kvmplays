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

# Create Markdown report
echo "# Test Report" > test_report.md
echo "Generated: $(date)" >> test_report.md
echo "" >> test_report.md

# Check if test_results.xml exists
if [ -f "test_results.xml" ]; then
    echo "## XML Test Results" >> test_report.md
    echo "" >> test_report.md
    
    # Extract basic statistics using grep and sed
    total_tests=$(grep -o 'tests="[0-9]*"' test_results.xml | head -1 | sed 's/tests="\([0-9]*\)"/\1/')
    failures=$(grep -o 'failures="[0-9]*"' test_results.xml | head -1 | sed 's/failures="\([0-9]*\)"/\1/')
    errors=$(grep -o 'errors="[0-9]*"' test_results.xml | head -1 | sed 's/errors="\([0-9]*\)"/\1/')
    skipped=$(grep -o 'skipped="[0-9]*"' test_results.xml | head -1 | sed 's/skipped="\([0-9]*\)"/\1/')
    time=$(grep -o 'time="[0-9.]*"' test_results.xml | head -1 | sed 's/time="\([0-9.]*\)"/\1/')
    
    # Write summary table
    echo "### Summary" >> test_report.md
    echo "" >> test_report.md
    echo "| Metric | Value |" >> test_report.md
    echo "|--------|-------|" >> test_report.md
    echo "| Total Tests | $total_tests |" >> test_report.md
    echo "| Passed | $((total_tests - failures - errors - skipped)) |" >> test_report.md
    echo "| Failed | $failures |" >> test_report.md
    echo "| Errors | $errors |" >> test_report.md
    echo "| Skipped | $skipped |" >> test_report.md
    echo "| Time | ${time}s |" >> test_report.md
    echo "" >> test_report.md
    
    # List failed tests if any
    if [ "$failures" -gt 0 ] || [ "$errors" -gt 0 ]; then
        echo "### Failed Tests" >> test_report.md
        echo "" >> test_report.md
        echo "| Test | Time | Failure Message |" >> test_report.md
        echo "|------|------|-----------------|" >> test_report.md
        
        # Extract failed test details
        grep -A 5 '<failure' test_results.xml | grep -v "</failure>" | grep -v "--" | 
        while read -r line; do
            if [[ $line =~ name=\"([^\"]+)\" ]]; then
                test_name="${BASH_REMATCH[1]}"
                time_line=$(grep -o "time=\"[0-9.]*\"" <<< "$line" | sed 's/time="\([0-9.]*\)"/\1/')
                message_line=$(grep -o 'message="[^"]*"' <<< "$line" | sed 's/message="\([^"]*\)"/\1/')
                echo "| $test_name | ${time_line}s | $message_line |" >> test_report.md
            fi
        done
        echo "" >> test_report.md
    fi
fi

# Check for pytest_output.log
if [ -f "pytest_output.log" ]; then
    echo "## Pytest Output" >> test_report.md
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

# Create JSON report
cat > test_report.json << EOF
{
  "generated": "$(date)",
  "summary": {
    "total_tests": ${total_tests:-0},
    "passed": $((${total_tests:-0} - ${failures:-0} - ${errors:-0} - ${skipped:-0})),
    "failed": ${failures:-0},
    "errors": ${errors:-0},
    "skipped": ${skipped:-0},
    "time": ${time:-0}
  }
}

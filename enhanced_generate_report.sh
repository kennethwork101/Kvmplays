#!/bin/bash

# This script generates test reports in multiple formats
# Usage: ./enhanced_generate_report.sh path/to/uvprog_dir

UVPROG_DIR="$1"
REPORT_MD="${UVPROG_DIR}/test_report.md"
REPORT_JSON="${UVPROG_DIR}/test_report.json"
REPORT_CSV="${UVPROG_DIR}/test_report.csv"

# Generate timestamp
TIMESTAMP=$(date --iso-8601=seconds)

# --- Generate Markdown report ---
echo "# Pytest Test Report" > "$REPORT_MD"
echo "Generated: $TIMESTAMP" >> "$REPORT_MD"
echo "" >> "$REPORT_MD"

# Initialize JSON with opening bracket
echo "[" > "$REPORT_JSON"

# Initialize CSV with header row
echo "repo_name,test_name,status,duration,message" > "$REPORT_CSV"

# Track if we need a comma in JSON output
FIRST_JSON_ENTRY=true

# Find all directories with pytest_output.log files
for DIR in $(find "$UVPROG_DIR" -name pytest_output.log -exec dirname {} \;); do
  REPO_NAME=$(basename "$DIR")

  # --- MARKDOWN OUTPUT ---
  echo "## $REPO_NAME" >> "$REPORT_MD"
  echo "" >> "$REPORT_MD"

  # Test Results - MODIFIED SECTION
  echo "### Test Results" >> "$REPORT_MD"
  echo '```' >> "$REPORT_MD"
  if [ -f "$DIR/pytest_output.log" ]; then
    # Extract test results directly from XML first - this ensures all tests are reported
    if [ -f "$DIR/test_results.xml" ]; then
      # Extract testcase elements and format them for reporting
      grep -o '<testcase[^>]*>' "$DIR/test_results.xml" | while read -r line; do
        TEST_NAME=$(echo "$line" | grep -o 'name="[^"]*"' | sed 's/name="\([^"]*\)"/\1/')
        TEST_CLASS=$(echo "$line" | grep -o 'classname="[^"]*"' | sed 's/classname="\([^"]*\)"/\1/')
        TEST_FILE=$(echo "$TEST_CLASS" | sed 's/\./\//g')
        
        # Get the full testcase with possible failure/error/skipped tags
        TESTCASE_IDX=$(grep -n "$line" "$DIR/test_results.xml" | cut -d: -f1)
        NEXT_10_LINES=$(tail -n +$TESTCASE_IDX "$DIR/test_results.xml" | head -10)

        # Determine test status
        if echo "$NEXT_10_LINES" | grep -q '<failure'; then
          STATUS="FAILED"
        elif echo "$NEXT_10_LINES" | grep -q '<error'; then
          STATUS="ERROR"
        elif echo "$NEXT_10_LINES" | grep -q '<skipped'; then
          STATUS="SKIPPED"
        else
          STATUS="PASSED"
        fi
        
        # Print properly formatted test results
        echo "$TEST_FILE::$TEST_NAME $STATUS" >> "$REPORT_MD"
      done
    else
      # Fallback to log parsing if XML not available
      # Modified to capture more test output patterns
      grep -E "::test_|PASSED|FAILED|ERROR|SKIPPED" "$DIR/pytest_output.log" | 
      grep -v "===" | 
      grep -v "short test summary" | 
      grep -v " seconds " |
      grep -v "warnings in" >> "$REPORT_MD"
    fi
  else
    echo "No pytest output found" >> "$REPORT_MD"
  fi
  echo '```' >> "$REPORT_MD"
  echo "" >> "$REPORT_MD"

  # Summary
  echo "### Summary" >> "$REPORT_MD"
  echo '```' >> "$REPORT_MD"
  SUMMARY=""
  if [ -f "$DIR/pytest_output.log" ]; then
    # Extract the test summary line with passed/failed counts
    STATS=$(grep -E "[0-9]+ failed, [0-9]+ passed|[0-9]+ passed, [0-9]+ failed" "$DIR/pytest_output.log" | tail -1 || echo "Summary not found")
    
    # Extract failure details but limit to a reasonable amount
    FAILURES=$(grep -A1 "= FAILURES =" "$DIR/pytest_output.log" 2>/dev/null && 
               grep -A2 "_{10,}" "$DIR/pytest_output.log" | head -20 || 
               echo "No failures found")

    echo "$FAILURES" >> "$REPORT_MD"
    echo "$STATS" >> "$REPORT_MD"

    SUMMARY="$STATS"
  else
    echo "No pytest output found" >> "$REPORT_MD"
    SUMMARY="No pytest output found"
  fi
  echo '```' >> "$REPORT_MD"
  echo "" >> "$REPORT_MD"

  # --- JSON and CSV PROCESSING ---
  # Extract test results from the XML for structured output
  if [ -f "$DIR/test_results.xml" ]; then
    echo "### Statistics" >> "$REPORT_MD"

    # Extract data from XML using basic tools
    TESTS=$(grep -o 'tests="[0-9]*"' "$DIR/test_results.xml" | head -1 | grep -o '[0-9]*')
    FAILURES=$(grep -o 'failures="[0-9]*"' "$DIR/test_results.xml" | head -1 | grep -o '[0-9]*')
    ERRORS=$(grep -o 'errors="[0-9]*"' "$DIR/test_results.xml" | head -1 | grep -o '[0-9]*')
    SKIPPED=$(grep -o 'skipped="[0-9]*"' "$DIR/test_results.xml" | head -1 | grep -o '[0-9]*')
    TIME=$(grep -o 'time="[0-9\.]*"' "$DIR/test_results.xml" | head -1 | grep -o '[0-9\.]*')
    
    # Also look for the time in the log file for more accurate timing
    LOG_TIME=$(grep -o '[0-9\.]\+s ([0-9]\+:[0-9]\+:[0-9]\+)' "$DIR/pytest_output.log" | tail -1 || echo "")

    echo "- Tests run: $TESTS" >> "$REPORT_MD"
    echo "- Failures: $FAILURES" >> "$REPORT_MD"
    echo "- Errors: $ERRORS" >> "$REPORT_MD"
    echo "- Skipped: $SKIPPED" >> "$REPORT_MD"
    if [ -n "$LOG_TIME" ]; then
      echo "- Time: $TIME $LOG_TIME seconds" >> "$REPORT_MD"
    else
      echo "- Time: $TIME seconds" >> "$REPORT_MD"
    fi
    echo "" >> "$REPORT_MD"

    # Extract individual testcase results for JSON and CSV - keep this section as is
    grep -o '<testcase[^>]*>' "$DIR/test_results.xml" | while read -r line; do
      # Extract test details
      TEST_NAME=$(echo "$line" | grep -o 'name="[^"]*"' | sed 's/name="\([^"]*\)"/\1/')
      TEST_CLASS=$(echo "$line" | grep -o 'classname="[^"]*"' | sed 's/classname="\([^"]*\)"/\1/')
      TEST_TIME=$(echo "$line" | grep -o 'time="[^"]*"' | sed 's/time="\([^"]*\)"/\1/')

      # Get the full testcase with possible failure/error/skipped tags
      TESTCASE_IDX=$(grep -n "$line" "$DIR/test_results.xml" | cut -d: -f1)
      NEXT_10_LINES=$(tail -n +$TESTCASE_IDX "$DIR/test_results.xml" | head -10)

      # Determine test status and message
      if echo "$NEXT_10_LINES" | grep -q '<failure'; then
        STATUS="FAILED"
        MESSAGE=$(echo "$NEXT_10_LINES" | grep -o 'message="[^"]*"' | head -1 | sed 's/message="\([^"]*\)"/\1/' | tr -d '",' | tr '\n' ' ')
      elif echo "$NEXT_10_LINES" | grep -q '<error'; then
        STATUS="ERROR"
        MESSAGE=$(echo "$NEXT_10_LINES" | grep -o 'message="[^"]*"' | head -1 | sed 's/message="\([^"]*\)"/\1/' | tr -d '",' | tr '\n' ' ')
      elif echo "$NEXT_10_LINES" | grep -q '<skipped'; then
        STATUS="SKIPPED"
        MESSAGE=$(echo "$NEXT_10_LINES" | grep -o 'message="[^"]*"' | head -1 | sed 's/message="\([^"]*\)"/\1/' | tr -d '",' | tr '\n' ' ')
      else
        STATUS="PASSED"
        MESSAGE=""
      fi

      # Add JSON entry if test name exists (avoid empty entries)
      if [ ! -z "$TEST_NAME" ]; then
        # Escape JSON special characters
        ESC_TEST_NAME=$(echo "$TEST_NAME" | sed 's/"/\\"/g')
        ESC_TEST_CLASS=$(echo "$TEST_CLASS" | sed 's/"/\\"/g')
        ESC_MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')

        # Add entry to JSON
        if [ "$FIRST_JSON_ENTRY" = true ]; then
          FIRST_JSON_ENTRY=false
        else
          echo "," >> "$REPORT_JSON"
        fi

        # Add JSON entry
        cat >> "$REPORT_JSON" << EOF
  {
    "repo_name": "$REPO_NAME",
    "test_class": "$ESC_TEST_CLASS",
    "test_name": "$ESC_TEST_NAME",
    "status": "$STATUS",
    "duration": $TEST_TIME,
    "message": "$ESC_MESSAGE",
    "timestamp": "$TIMESTAMP"
  }
EOF

        # Add CSV entry - handle commas in fields
        echo "\"$REPO_NAME\",\"$TEST_NAME\",\"$STATUS\",\"$TEST_TIME\",\"$MESSAGE\"" >> "$REPORT_CSV"
      fi
    done
  fi

  echo "---" >> "$REPORT_MD"
  echo "" >> "$REPORT_MD"
done

# Close the JSON array
echo "]" >> "$REPORT_JSON"

echo "Test reports generated at:"
echo "- $REPORT_MD (human-readable)"
echo "- $REPORT_JSON (database-friendly JSON)"
echo "- $REPORT_CSV (spreadsheet-compatible CSV)"

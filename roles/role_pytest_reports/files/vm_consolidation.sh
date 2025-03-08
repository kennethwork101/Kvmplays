#!/bin/bash
# Script to consolidate test reports from multiple VMs

# Create timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="consolidated_reports"
REPORT_PATH="$REPORT_DIR/report_$TIMESTAMP"

# Create directories
mkdir -p "$REPORT_PATH"

# Start the consolidated report
CONSOLIDATED_REPORT="$REPORT_PATH/consolidated_report.md"
echo "# Consolidated Test Reports" > "$CONSOLIDATED_REPORT"
echo "Generated: $(date)" >> "$CONSOLIDATED_REPORT"
echo "Report ID: $TIMESTAMP" >> "$CONSOLIDATED_REPORT"
echo "" >> "$CONSOLIDATED_REPORT"

# Calculate total duration (initialize)
TOTAL_DURATION=0

# VM Summary section
echo "## VM Summary" >> "$CONSOLIDATED_REPORT"
echo "" >> "$CONSOLIDATED_REPORT"
echo "| Report Generated | Duration (s) | VM Hostname |" >> "$CONSOLIDATED_REPORT"
echo "|------------------|--------------|-------------|" >> "$CONSOLIDATED_REPORT"

# For each VM report file (assuming they're passed as arguments or found in a directory)
for vm_report in "$@"; do
    if [ -f "$vm_report" ]; then
        # Extract VM hostname and timestamp
        vm_hostname=$(grep -m 1 "VM:" "$vm_report" 2>/dev/null || basename "$vm_report" | sed 's/_test_report.md//')
        report_date=$(grep -m 1 "Generated:" "$vm_report" 2>/dev/null || echo "Unknown" | sed 's/Generated: //')

        # Extract duration information - look for either Total Duration or Total Time in the file
        vm_duration=$(grep -m 1 "Total Duration" "$vm_report" | awk -F'|' '{print $3}' | sed 's/^ *//;s/ *$//' | sed 's/ s.*$//' 2>/dev/null ||
                      grep -m 1 "Total Time" "$vm_report" | awk -F'|' '{print $3}' | sed 's/^ *//;s/ *$//' | sed 's/ s.*$//' 2>/dev/null ||
                      echo "N/A")

        # Add to VM summary table - with duration before hostname
        printf "| %-18s | %-12s | %-11s |\n" "$report_date" "$vm_duration" "$vm_hostname" >> "$CONSOLIDATED_REPORT"

        # Add to total duration if it's a number
        if [[ "$vm_duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            TOTAL_DURATION=$(echo "$TOTAL_DURATION + $vm_duration" | bc)
        fi

        # Copy the VM report content
        cp "$vm_report" "$REPORT_PATH/$(basename "$vm_report")"
    fi
done

# Format the total duration
FORMATTED_DURATION=$(printf "%02d:%02d:%02d" $(($TOTAL_DURATION/3600)) $(($TOTAL_DURATION%3600/60)) $(($TOTAL_DURATION%60)))

# Add total duration information after VM Summary
echo "" >> "$CONSOLIDATED_REPORT"
echo "### Total Test Duration: ${TOTAL_DURATION}s ($FORMATTED_DURATION)" >> "$CONSOLIDATED_REPORT"
echo "" >> "$CONSOLIDATED_REPORT"

echo "## Detailed Reports by VM" >> "$CONSOLIDATED_REPORT"
echo "" >> "$CONSOLIDATED_REPORT"

# Append each VM's report content
for vm_report in "$@"; do
    if [ -f "$vm_report" ]; then
        vm_hostname=$(basename "$vm_report" | sed 's/_test_report.md//')
        echo "" >> "$CONSOLIDATED_REPORT"
        echo "# VM: $vm_hostname" >> "$CONSOLIDATED_REPORT"
        echo "===========================================" >> "$CONSOLIDATED_REPORT"
        echo "" >> "$CONSOLIDATED_REPORT"
        cat "$vm_report" >> "$CONSOLIDATED_REPORT"
        echo "" >> "$CONSOLIDATED_REPORT"
        echo "---" >> "$CONSOLIDATED_REPORT"
        echo "" >> "$CONSOLIDATED_REPORT"
    fi
done

# Create links to latest report
mkdir -p "$REPORT_DIR"
ln -sf "$CONSOLIDATED_REPORT" "$REPORT_DIR/latest_report.md"

echo "Consolidated report created at: $CONSOLIDATED_REPORT"
echo "Symlink created at: $REPORT_DIR/latest_report.md"
echo "Consolidation complete."

#!/bin/bash

# Create role directory structure
mkdir -p role_pytest_reports/{defaults,files,handlers,meta,tasks,templates,vars}

# Create defaults/main.yml
cat > role_pytest_reports/defaults/main.yml << 'EOF'
---
# Default variables for role_pytest_reports

# Repository and path configuration
uvprog: "uvprog2025"  # Project directory name

# Report configuration
reports_dir: "{{ playbook_dir }}/test_reports"
reports_history_dir: "{{ reports_dir }}/history"
consolidated_report_path: "{{ playbook_dir }}/consolidated_report.md"
report_formats:
  - md
  - json
  - csv

# XML formatting configuration
format_xml: true  # Set to false to disable XML formatting
xml_backup: true  # Set to false to skip creating backup of original XML
EOF

# Create files/enhanced_generate_report.sh
cat > role_pytest_reports/files/enhanced_generate_report.sh << 'EOF'
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
EOF

# Create CSV report
echo "Metric,Value" > test_report.csv
echo "Total Tests,${total_tests:-0}" >> test_report.csv
echo "Passed,$((${total_tests:-0} - ${failures:-0} - ${errors:-0} - ${skipped:-0}))" >> test_report.csv
echo "Failed,${failures:-0}" >> test_report.csv
echo "Errors,${errors:-0}" >> test_report.csv
echo "Skipped,${skipped:-0}" >> test_report.csv
echo "Time,${time:-0}" >> test_report.csv

echo "Reports generated successfully."
EOF

# Make the script executable
chmod +x role_pytest_reports/files/enhanced_generate_report.sh

# Create meta/main.yml
cat > role_pytest_reports/meta/main.yml << 'EOF'
---
galaxy_info:
  role_name: role_pytest_reports
  author: Your Name
  description: Processes pytest results, formats XML output, and generates consolidated reports
  company: Your Company
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - all
    - name: Debian
      versions:
        - all
    - name: EL  # Enterprise Linux
      versions:
        - all

  galaxy_tags:
    - testing
    - reporting
    - pytest
    - development

dependencies: []
EOF

# Create tasks/main.yml
cat > role_pytest_reports/tasks/main.yml << 'EOF'
---
# Main tasks file for role_pytest_reports

# Include task files
- name: Gather test results
  import_tasks: gather_results.yml
  tags:
    - gather
    - always

- name: Format XML test results
  import_tasks: format_xml.yml
  tags:
    - format
    - xml
  when: format_xml | bool

- name: Generate test reports
  import_tasks: generate_reports.yml
  tags:
    - generate
    - reports

- name: Consolidate test reports
  import_tasks: consolidate.yml
  tags:
    - consolidate
    - reports
EOF

# Create tasks/gather_results.yml
cat > role_pytest_reports/tasks/gather_results.yml << 'EOF'
---
# Tasks for gathering test results

- name: Extract test summary from output
  shell: |
    grep -A1 "= FAILURES =" pytest_output.log || echo "No failures found"
    grep "= .* failed, .* passed" pytest_output.log || echo "Summary not found"
  args:
    chdir: "{{ user_home.stdout }}/{{ uvprog }}/{{ (item | basename | splitext)[0] }}"
  become: yes
  become_user: "{{ username }}"
  loop: "{{ git_repos }}"
  register: test_summary
  changed_when: false
  failed_when: false

- name: Display test results summary
  debug:
    msg: |
      ===== Test Results for {{ (item.item | basename | splitext)[0] }} =====
      {{ item.stdout }}
  loop: "{{ test_results.results }}"
  when: item.stdout | trim != ""

- name: Display test summary
  debug:
    msg: |
      ===== Test Summary for {{ (item.item | basename | splitext)[0] }} =====
      {{ item.stdout }}
  loop: "{{ test_summary.results }}"

- name: Parse JUnit XML results
  community.general.xml:
    path: "{{ user_home.stdout }}/{{ uvprog }}/{{ (item | basename | splitext)[0] }}/test_results.xml"
    xpath: /testsuite
    content: attribute
  become: yes
  become_user: "{{ username }}"
  loop: "{{ git_repos }}"
  register: junit_results
  failed_when: false

- name: Display JUnit test summary
  debug:
    msg: |
      ===== JUnit Test Summary for {{ (item.item | basename | splitext)[0] }} =====
      Tests run: {{ item.matches[0].testsuite.tests }}
      Failures: {{ item.matches[0].testsuite.failures }}
      Errors: {{ item.matches[0].testsuite.errors }}
      Skipped: {{ item.matches[0].testsuite.skipped }}
      Time: {{ item.matches[0].testsuite.time }} seconds
  loop: "{{ junit_results.results }}"
  when:
    - item.matches is defined
    - item.matches | length > 0

- name: Print completion timestamp
  debug:
    msg: "Finished gathering test results at {{ ansible_date_time.iso8601 }}"
EOF

# Create tasks/format_xml.yml
cat > role_pytest_reports/tasks/format_xml.yml << 'EOF'
---
# Tasks for formatting XML test results

- name: Ensure python3-lxml is installed
  become: true
  package:
    name: python3-lxml
    state: present
  when: ansible_os_family in ['Debian', 'RedHat']

- name: Format XML test results
  shell: |
    if [ -f test_results.xml ]; then
      {% if xml_backup | bool %}
      cp test_results.xml test_results.xml.bak
      {% endif %}
      python3 -c '
import sys
from lxml import etree
try:
    parser = etree.XMLParser(remove_blank_text=True)
    tree = etree.parse("test_results.xml", parser)
    with open("test_results.xml", "wb") as f:
        f.write(etree.tostring(tree, encoding="utf-8", xml_declaration=True, pretty_print=True))
    print("XML formatted successfully")
except Exception as e:
    print(f"Error formatting XML: {e}")
    sys.exit(1)
'
    else
      echo "No test_results.xml file found"
    fi
  args:
    chdir: "{{ user_home.stdout }}/{{ uvprog }}/{{ (item | basename | splitext)[0] }}"
    executable: /bin/bash
  become: yes
  become_user: "{{ username }}"
  loop: "{{ git_repos }}"
  register: format_results
  changed_when: format_results.stdout == "XML formatted successfully"
  failed_when: "'Error formatting XML' in format_results.stderr"

- name: Copy formatted XML for reporting (optional)
  shell: |
    if [ -f test_results.xml ]; then
      cp test_results.xml test_results_formatted.xml
    fi
  args:
    chdir: "{{ user_home.stdout }}/{{ uvprog }}/{{ (item.item | basename | splitext)[0] }}"
    executable: /bin/bash
  become: yes
  become_user: "{{ username }}"
  loop: "{{ format_results.results }}"
  when: "'XML formatted successfully' in item.stdout"
  failed_when: false
  changed_when: false
EOF

# Create tasks/generate_reports.yml
cat > role_pytest_reports/tasks/generate_reports.yml << 'EOF'
---
# Tasks for generating test reports

# First, copy the report generation script to the target
- name: Copy report generation script
  copy:
    src: enhanced_generate_report.sh
    dest: "{{ user_home.stdout }}/enhanced_generate_report.sh"
    mode: '0755'
  become: yes
  become_user: "{{ username }}"

# Then run the enhanced script on each guest VM
- name: Generate enhanced test reports on guest VM
  shell: "./enhanced_generate_report.sh {{ user_home.stdout }}/{{ uvprog }}"
  args:
    chdir: "{{ user_home.stdout }}"
  become: yes
  become_user: "{{ username }}"

- name: Ensure reports directory exists with correct permissions
  file:
    path: "{{ reports_dir }}"
    state: directory
    mode: '0755'
    owner: "{{ lookup('env', 'USER') }}"
    group: "{{ lookup('env', 'USER') }}"
  delegate_to: localhost
  run_once: true
  become: yes

# Fetch test reports from guest VMs
- name: Fetch test reports from guest VMs
  fetch:
    src: "{{ user_home.stdout }}/{{ uvprog }}/{{ item }}"
    dest: "{{ reports_dir }}/{{ inventory_hostname }}_{{ item }}"
    flat: yes
  become: yes
  become_user: "{{ username }}"
  with_items:
    - "test_report.{{ item }}"
  loop: "{{ report_formats }}"
  failed_when: false  # Continue even if one format is missing

# Optionally, display that the report was created
- name: Report generation status
  debug:
    msg: "Test reports generated at {{ user_home.stdout }}/{{ uvprog }}/test_report.[md,json,csv]"
EOF

# Create tasks/consolidate.yml
cat > role_pytest_reports/tasks/consolidate.yml << 'EOF'
---
# Tasks for consolidating test reports

# Create directory for versioned reports
- name: Ensure versioned reports directory exists with correct permissions
  file:
    path: "{{ reports_history_dir }}"
    state: directory
    mode: '0755'
    owner: "{{ lookup('env', 'USER') }}"
    group: "{{ lookup('env', 'USER') }}"
  delegate_to: localhost
  run_once: true
  become: yes

# Get current timestamp for report naming
- name: Get current timestamp
  shell: date '+%Y%m%d_%H%M%S'
  register: timestamp
  delegate_to: localhost
  run_once: true
  changed_when: false

# Handle versioning of previous reports
- name: Version previous consolidated report if it exists
  shell: |
    # Check if previous consolidated report exists
    if [ -f "{{ consolidated_report_path }}" ]; then
      # Find the highest existing version number
      max_num=0
      for file in {{ reports_history_dir }}/consolidated_report_*.md; do
        if [ -f "$file" ]; then
          num=$(echo "$file" | grep -o 'report_[0-9]*\.md' | grep -o '[0-9]*')
          if [ "$num" -gt "$max_num" ]; then
            max_num=$num
          fi
        fi
      done

      # Increment the version number
      next_num=$((max_num + 1))

      # Copy the current report to history with version number
      cp "{{ consolidated_report_path }}" "{{ reports_history_dir }}/consolidated_report_${next_num}.md"
      echo "Versioned previous report as consolidated_report_${next_num}.md"

      # Also create a timestamped copy for absolute reference
      cp "{{ consolidated_report_path }}" "{{ reports_history_dir }}/consolidated_report_${next_num}_{{ timestamp.stdout }}.md"
    fi
  args:
    chdir: "{{ playbook_dir }}"
  delegate_to: localhost
  run_once: true
  register: versioning_result
  changed_when: versioning_result.stdout != ""

# Generate a new consolidated report
- name: Generate new consolidated report
  shell: |
    echo "# Consolidated Test Reports" > "{{ consolidated_report_path }}"
    echo "Generated: $(date)" >> "{{ consolidated_report_path }}"
    echo "Report ID: {{ timestamp.stdout }}" >> "{{ consolidated_report_path }}"
    echo "" >> "{{ consolidated_report_path }}"

    # Summary table of VMs
    echo "## VM Summary" >> "{{ consolidated_report_path }}"
    echo "" >> "{{ consolidated_report_path }}"
    echo "| VM Hostname | Report Generated |" >> "{{ consolidated_report_path }}"
    echo "|-------------|------------------|" >> "{{ consolidated_report_path }}"

    for report in {{ reports_dir }}/*_test_report.md; do
      if [ -f "$report" ]; then
        vm_name=$(basename "$report" | sed 's/_test_report.md//')
        report_date=$(grep "Generated:" "$report" | sed 's/Generated: //')
        echo "| $vm_name | $report_date |" >> "{{ consolidated_report_path }}"
      fi
    done

    echo "" >> "{{ consolidated_report_path }}"
    echo "## Detailed Reports by VM" >> "{{ consolidated_report_path }}"
    echo "" >> "{{ consolidated_report_path }}"

    # Detailed reports
    for report in {{ reports_dir }}/*_test_report.md; do
      if [ -f "$report" ]; then
        vm_name=$(basename "$report" | sed 's/_test_report.md//')
        echo "" >> "{{ consolidated_report_path }}"
        echo "# VM: $vm_name" >> "{{ consolidated_report_path }}"
        echo "===========================================" >> "{{ consolidated_report_path }}"
        echo "" >> "{{ consolidated_report_path }}"
        cat "$report" >> "{{ consolidated_report_path }}"
        echo "" >> "{{ consolidated_report_path }}"
        echo "---" >> "{{ consolidated_report_path }}"
        echo "" >> "{{ consolidated_report_path }}"
      fi
    done

    # Also create a timestamped copy in history
    cp "{{ consolidated_report_path }}" "{{ reports_history_dir }}/consolidated_report_{{ timestamp.stdout }}.md"
  args:
    chdir: "{{ playbook_dir }}"
  delegate_to: localhost
  run_once: true

# Display report information and history
- name: Display report information
  shell: |
    echo "Current report: {{ consolidated_report_path }}"
    echo "Timestamped copy: {{ reports_history_dir }}/consolidated_report_{{ timestamp.stdout }}.md"
    echo ""
    echo "Report history:"
    ls -1t {{ reports_history_dir }}/consolidated_report_*.md 2>/dev/null | head -10 | sed 's/^/- /'
    echo ""
    echo "Total reports in history: $(ls -1 {{ reports_history_dir }}/consolidated_report_*.md 2>/dev/null | wc -l)"
  args:
    chdir: "{{ playbook_dir }}"
  register: report_info
  delegate_to: localhost
  run_once: true
  changed_when: false

- name: Show report history
  debug:
    msg: "{{ report_info.stdout_lines }}"
  delegate_to: localhost
  run_once: true

# Display the location of the consolidated report
- name: Report consolidated report location
  debug:
    msg: "Consolidated report generated at {{ consolidated_report_path }}"
  delegate_to: localhost
  run_once: true
EOF

# Create the README.md file
cat > role_pytest_reports/README.md << 'EOF'
# Ansible Role: role_pytest_reports

This role processes pytest results, formats XML output, and generates consolidated reports.

## Features

- Extracts test information from pytest output logs
- Parses JUnit XML test results
- Formats XML test results for improved readability
- Generates enhanced test reports in multiple formats (MD, JSON, CSV)
- Consolidates reports from multiple VMs into a single document
- Maintains a version history of reports

## Requirements

- Python 3
- python3-lxml package (will be installed by the role if not present)
- Ansible community.general collection (for the xml module)

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Project directory name
uvprog: "uvprog2025"

# Report configuration
reports_dir: "{{ playbook_dir }}/test_reports"
reports_history_dir: "{{ reports_dir }}/history"
consolidated_report_path: "{{ playbook_dir }}/consolidated_report.md"
report_formats:
  - md
  - json
  - csv

# XML formatting configuration
format_xml: true  # Set to false to disable XML formatting
xml_backup: true  # Set to false to skip creating backup of original XML
```

## Dependencies

None.

## Example Playbook

```yaml
- name: Run pytest and generate reports
  hosts: test_vms
  become: yes

  vars:
    uvprog: "uvprog2025"
    format_xml: true

  pre_tasks:
    - name: Get user home directory
      shell: echo $HOME
      register: user_home
      become: yes
      become_user: "{{ username }}"
      changed_when: false

  roles:
    - role: role_pytest_reports
```

## Tags

- `gather`: Tasks for gathering test results
- `format`, `xml`: Tasks for formatting XML test results
- `generate`, `reports`: Tasks for generating test reports
- `consolidate`, `reports`: Tasks for consolidating test reports

## License

MIT

## Author Information

Your Name
EOF

# Create an example playbook
cat > example_playbook.yml << 'EOF'
---
# Example playbook for using the role_pytest_reports role

- name: Run pytest and generate reports
  hosts: test_vms
  become: yes

  # Variables can be defined here or in group_vars/host_vars
  vars:
    uvprog: "uvprog2025"
    format_xml: true

  # Pre-tasks to get necessary information
  pre_tasks:
    - name: Get user home directory
      shell: echo $HOME
      register: user_home
      become: yes
      become_user: "{{ username }}"
      changed_when: false

  # Include the role
  roles:
    - role: role_pytest_reports

  # Any post-tasks can go here
  post_tasks:
    - name: Notify completion
      debug:
        msg: "Pytest report processing completed successfully"
EOF

# Create empty placeholder files
touch role_pytest_reports/handlers/main.yml
touch role_pytest_reports/templates/main.yml
touch role_pytest_reports/vars/main.yml

# Create a tarball with all files
tar -czvf role_pytest_reports.tar.gz role_pytest_reports example_playbook.yml

echo "Setup complete! The role has been created and packaged into role_pytest_reports.tar.gz"
echo "To use the role, extract it with: tar -xzvf role_pytest_reports.tar.gz"


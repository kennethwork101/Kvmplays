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

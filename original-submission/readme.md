PROJECT TITLE

Automated IP Reputation Analysis Tool

 

DESCRIPTION

Brief description of what the tool does and why it exists.

 

REQUIREMENTS

- macOS

- PowerShell Core (pwsh)

- Python 3

- Python package: requests

- AbuseIPDB API key

 

SETUP

1. Install PowerShell Core (pwsh)

2. Install Python 3

3. Install required Python library:

   pip3 install requests

4. Add your AbuseIPDB API key to config.json

 

USAGE

1. Run PowerShell script:

   pwsh extract_ips.ps1

 

2. Run Python script:

   python3 check_ip_reputation.py

 

OUTPUT FILES

- remote_ips.csv

- threat_report.json

 
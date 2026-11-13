# Automated IP Reputation Analysis Tool

A two-stage threat-intelligence script that finds every remote IP address a computer is currently talking to and checks each one against the **AbuseIPDB** reputation database, producing a JSON threat report.

**Module:** Scripting for Cyber Security (H2702), TU Dublin, CA3
**Team:** Benjamin Oludipe and a classmate (pair project; partner name withheld for privacy)
**Languages / tools:** PowerShell Core, Python 3 (`requests`, `csv`, `json`), AbuseIPDB REST API, `netstat`

---

## Why it exists
An analyst who suspects a machine is compromised needs a fast answer to *"is this computer connected to anything known to be malicious?"* Checking connections one by one is slow. This tool automates the collection and the lookup.

## How it works
```
netstat -an ──► extract_ips.ps1 ──► remote_ips.csv ──► check_ip_reputation.py ──► AbuseIPDB API ──► threat_report.json
```
1. **`extract_ips.ps1` (PowerShell):** runs `netstat -an`, keeps only `ESTABLISHED` connections, pulls out the remote address, removes duplicates and saves the list to `remote_ips.csv`.
2. **`check_ip_reputation.py` (Python):** reads the CSV, sends each IP to the AbuseIPDB `/check` endpoint (last 90 days) and records the abuse-confidence score and country, or the error, in `threat_report.json`.

## My contribution
Pair project. We agreed the workflow, tool design and use case together, then split the build:
- **Me: the PowerShell collection stage** (`extract_ips.ps1`): reading active TCP connections, extracting remote IPs, filtering, exporting to CSV, and testing it on macOS with PowerShell Core.
- **My partner: the Python enrichment stage** (`check_ip_reputation.py`): the AbuseIPDB integration and JSON report.
- **Together:** joining the two stages, debugging file/config issues and writing the documentation.

After submission I uploaded and documented this repository, and diagnosed and fixed the parsing bug described below (in both scripts).

## Setup and usage
Requirements: PowerShell Core (`pwsh`), Python 3, `pip3 install requests`, a free AbuseIPDB API key.

1. Put your key in `config.json`. The committed file contains only a placeholder, so **never commit a real key**.
2. `pwsh extract_ips.ps1` (Windows PowerShell or PowerShell Core on macOS/Linux)
3. `python3 check_ip_reputation.py`

## Evidence
- `original-submission/`: the code and outputs exactly as submitted (IP addresses redacted).
- `remote_ips.csv` / `threat_report.json`: real outputs from the first run, showing the bug (IP addresses redacted).
- `Terminal Saved Output`: the terminal session from the lab (IPs, hostnames and key names redacted).

## Bug found, fixed and tested
The first sample report (kept in `original-submission/`) shows every lookup failing. I traced two causes:
1. **Wrong column and port format.** The script took a fixed column from `netstat`, but Windows lines start with spaces (shifting the columns) and macOS prints addresses as `IP.port`, not `IP:port`. The port stayed attached, so the API never received a valid IP.
2. **Errors were hidden.** The script assumed every API reply contained `data`, so any HTTP error (bad key, bad IP) appeared only as `'data'`.

**Fix (after submission):** the remote address is now taken from the column before `ESTABLISHED`, the port is stripped for Windows, macOS and Linux formats (IPv4 and IPv6), macOS uses `netstat -anl` so long IPv6 addresses are not truncated, private/loopback addresses are skipped, and API errors are reported with their real HTTP status.

**Tests (in `tests/`):**
- `pwsh tests/test_parse.ps1`: endpoint parsing on Windows, macOS and Linux samples (IPv4 and IPv6) and the column choice on real-format netstat lines.
- `python3 tests/test_lookup.py`: runs the lookup against a fake AbuseIPDB (no network, no key) and checks that private/invalid addresses are never sent, HTTP 401 is reported, and a successful lookup is recorded.
- I also ran the collection stage on real macOS `netstat -anl` output: 0 malformed addresses.

**Lesson:** validate input against each operating system's real output, and check the results, not just that the script ran.

## Security notes
- The API key is loaded from a config file, never hard-coded.
- Only IP addresses are sent to the third-party API; no other host data leaves the machine.

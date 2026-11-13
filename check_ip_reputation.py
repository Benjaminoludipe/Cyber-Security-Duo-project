import csv
import ipaddress
import json
import requests

API_URL = "https://api.abuseipdb.com/api/v2/check"

with open("config.json") as f:
    API_KEY = json.load(f)["api_key"]

results = []

with open("remote_ips.csv", newline="") as file:
    reader = csv.DictReader(file)

    for row in reader:
        ip = row["RemoteIP"].strip()

        # Validate the address and skip ones that public threat intelligence cannot know about
        try:
            addr = ipaddress.ip_address(ip)
        except ValueError:
            results.append({"ip": ip, "error": "not a valid IP address"})
            continue
        if addr.is_private or addr.is_loopback or addr.is_link_local:
            results.append({"ip": ip, "skipped": "private/loopback address"})
            continue

        try:
            response = requests.get(
                API_URL,
                headers={
                    "Key": API_KEY,
                    "Accept": "application/json"
                },
                params={
                    "ipAddress": ip,
                    "maxAgeInDays": 90
                },
                timeout=10
            )

            # Report the API's real answer (e.g. 401 bad key, 422 bad IP) instead of a KeyError
            if response.status_code != 200:
                results.append({
                    "ip": ip,
                    "error": f"HTTP {response.status_code}: {response.text[:200]}"
                })
                continue

            data = response.json()["data"]

            results.append({
                "ip": ip,
                "abuseScore": data["abuseConfidenceScore"],
                "country": data["countryName"]
            })

        except Exception as e:
            results.append({
                "ip": ip,
                "error": str(e)
            })

with open("threat_report.json", "w") as out:
    json.dump(results, out, indent=4)

print("Threat intelligence report generated: threat_report.json")

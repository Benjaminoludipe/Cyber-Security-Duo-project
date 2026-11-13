import csv
import json
import requests

API_URL = "https://api.abuseipdb.com/api/v2/check"

with open("config.json") as f:
    API_KEY = json.load(f)["api_key"]

results = []

with open("remote_ips.csv", newline="") as file:
    reader = csv.DictReader(file)

    for row in reader:
        ip = row["RemoteIP"]

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

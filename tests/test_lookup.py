"""Runs check_ip_reputation.py against a fake AbuseIPDB (no network, no real key).

Run from the repo root:  python3 tests/test_lookup.py
"""
import json, os, runpy, shutil, sys, tempfile, types

calls = []

class FakeResponse:
    def __init__(self, code, body):
        self.status_code, self._body, self.text = code, body, json.dumps(body)
    def json(self):
        return self._body

def fake_get(url, headers, params, timeout):
    calls.append(params["ipAddress"])
    if params["ipAddress"] == "8.8.8.8":
        return FakeResponse(200, {"data": {"abuseConfidenceScore": 0, "countryName": "United States"}})
    return FakeResponse(401, {"errors": [{"detail": "Authentication failed"}]})

sys.modules["requests"] = types.SimpleNamespace(get=fake_get)
script = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "check_ip_reputation.py"))
work = tempfile.mkdtemp()
os.chdir(work)
json.dump({"api_key": "test"}, open("config.json", "w"))
open("remote_ips.csv", "w").write('"RemoteIP"\n"127.0.0.1"\n"192.168.1.5"\n"not-an-ip"\n"8.8.8.8"\n"1.1.1.1"\n')
runpy.run_path(script)
out = json.load(open("threat_report.json"))

assert calls == ["8.8.8.8", "1.1.1.1"], f"private/invalid addresses must not reach the API: {calls}"
assert out[0]["skipped"] and out[1]["skipped"], "loopback/private should be skipped"
assert out[2]["error"] == "not a valid IP address"
assert out[3] == {"ip": "8.8.8.8", "abuseScore": 0, "country": "United States"}
assert out[4]["error"].startswith("HTTP 401"), "API errors must be reported with their status"
shutil.rmtree(work)
print("all lookup tests passed")

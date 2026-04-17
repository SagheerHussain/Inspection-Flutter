import urllib.request
import json
import time

url = "https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer?limit=5000&pageNumber=1"
headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'
}
payload = {"allocatedTo":"sujoy.ghosh@otobix.in"}

t0 = time.time()
req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        print("Total:", data.get('total'))
        print("Records returned:", len(data.get('data', [])))
        print("Time:", time.time() - t0, "s")
except Exception as e:
    print("Error:", e)

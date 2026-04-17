import urllib.request
import json
import time

url = "https://ob-dealerapp-kong.onrender.com/api/admin/telecallings/get-list?page=1&limit=20"
headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'
}
payload = {"search": "101141", "allocatedTo": "sujoy.ghosh@otobix.in"}

req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        print("Admin endpoint:", data.get('total'))
except Exception as e:
    print("Error:", e)

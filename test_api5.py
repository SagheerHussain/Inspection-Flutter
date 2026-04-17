import urllib.request
import json
import time

urls = [
    "https://ob-dealerapp-kong.onrender.com/api/inspection/car/get-list-by-inspection-engineer?limit=1&pageNumber=1",
    "https://ob-dealerapp-kong.onrender.com/api/car/get-list?limit=1&pageNumber=1",
    "https://ob-dealerapp-kong.onrender.com/api/admin/car/get-list",
    "https://ob-dealerapp-kong.onrender.com/api/inspection/cars/get-list-by-inspection-engineer?limit=1&pageNumber=1"
]
headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'
}
payload = {"allocatedTo":"sujoy.ghosh@otobix.in"}

for url in urls:
    print("Testing:", url)
    try:
        req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print("Total:", data.get('total'))
    except Exception as e:
        print("Error:", e)

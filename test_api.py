import urllib.request
import json

base_url = "https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer"
headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'
}

def post(url, payload):
    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print("Total:", data.get('total'))
    except Exception as e:
        print("Error:", e)

print("1. Url ?search=X")
post(f"{base_url}?limit=20&pageNumber=1&search=26-101141", {})

print("2. Body search=X")
post(f"{base_url}?limit=20&pageNumber=1", {"search": "26-101141"})

print("3. Body searchText=X")
post(f"{base_url}?limit=20&pageNumber=1", {"searchText": "26-101141"})

print("4. Body query=X")
post(f"{base_url}?limit=20&pageNumber=1", {"query": "26-101141"})

print("5. Body appointmentId=X")
post(f"{base_url}?limit=20&pageNumber=1", {"appointmentId": "26-101141"})

print("6. No args:")
post(f"{base_url}?limit=20&pageNumber=1", {})

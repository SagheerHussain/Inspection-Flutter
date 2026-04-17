import urllib.request
import json

base_url = "https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer"
headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'
}

def post(payload):
    req = urllib.request.Request(base_url+"?limit=20&pageNumber=1", data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print(f"Total for {payload}: {data.get('total')}")
    except Exception as e:
        print("Error:", e)

post({"allocatedTo":"sujoy.ghosh@otobix.in", "searchString": "101141"})
post({"allocatedTo":"sujoy.ghosh@otobix.in", "searchTerm": "101141"})
post({"allocatedTo":"sujoy.ghosh@otobix.in", "$text": {"$search": "101141"}})
post({"allocatedTo":"sujoy.ghosh@otobix.in", "appointmentId": {"$regex": "101141"}})
post({"allocatedTo":"sujoy.ghosh@otobix.in", "appointmentId": "26-101141"})

import urllib.request
import json

base_url_t = "https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer?limit=1&pageNumber=1"
base_url_c = "https://ob-dealerapp-kong.onrender.com/api/car/get-list-by-inspection-engineer?limit=1&pageNumber=1"
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
            if len(data.get('data',[])) > 0:
                print("First:", data['data'][0].get('appointmentId'), data['data'][0].get('inspectionStatus'))
    except Exception as e:
        print("Error:", url, e)

payload = {"allocatedTo":"sujoy.ghosh@otobix.in"}
post(base_url_t, payload)
post(base_url_c, payload)

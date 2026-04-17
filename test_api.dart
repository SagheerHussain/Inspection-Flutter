import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer?limit=20&pageNumber=1&search=26-101141';
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'
    },
    body: jsonEncode({"allocatedTo":"sujoy.ghosh@otobix.in"})
  );
  print('search query param: \${jsonDecode(response.body)['total']}');

  final url2 = 'https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer?limit=20&pageNumber=1&keyword=26-101141';
  final response2 = await http.post(Uri.parse(url2), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'}, body: jsonEncode({"allocatedTo":"sujoy.ghosh@otobix.in"}));
  print('keyword query param: \${jsonDecode(response2.body)['total']}');
  
  final url4 = 'https://ob-dealerapp-kong.onrender.com/api/inspection/telecallings/get-list-by-inspection-engineer?limit=20&pageNumber=1';
  final response4 = await http.post(Uri.parse(url4), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'}, body: jsonEncode({"allocatedTo":"sujoy.ghosh@otobix.in", "search": "26-101141"}));
  print('search in body: \${jsonDecode(response4.body)['total']}');
  
  final response5 = await http.post(Uri.parse(url4), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'}, body: jsonEncode({"allocatedTo":"sujoy.ghosh@otobix.in", "searchTerm": "26-101141"}));
  print('searchTerm in body: \${jsonDecode(response5.body)['total']}');
  
  final response6 = await http.post(Uri.parse(url4), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5MDBhYzc2NTA4OGQxYTA2ODc3MDU0NCIsInVzZXJOYW1lIjoiY3VzdG9tZXIiLCJ1c2VyVHlwZSI6IkN1c3RvbWVyIiwiaWF0IjoxNzY0MzMxNjMxLCJleHAiOjIwNzk2OTE2MzF9.oXw1J4ca1XoIAg-vCO2y0QqZIq0VWHdYBrl2y9iIv4Q'}, body: jsonEncode({"allocatedTo":"sujoy.ghosh@otobix.in", "globalSearch": "26-101141"}));
  print('globalSearch in body: \${jsonDecode(response6.body)['total']}');
}

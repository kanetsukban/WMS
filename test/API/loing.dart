import 'package:http/http.dart' as http;

void main() async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.1.21/api/auth/login/'),
  );

  request.fields.addAll({
    'username': 'amr@system',
    'password': 'amr@Passw0rd',   // ❌ เอา \n ออก
  });

  // ❌ ไม่ต้องส่ง Cookie ตอน login
  // request.headers.addAll({'Cookie': '...'});

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print("Error: ${response.statusCode}");
    print(await response.stream.bytesToString()); // debug body error
  }
}

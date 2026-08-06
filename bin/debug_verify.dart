import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyDmkhkEh_CPkDY0lik93MYR_yII_2HKM1U';
  final projectId = 'factory-management-8307e';
  final client = HttpClient();

  final authUrl = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
  );
  final authReq = await client.postUrl(authUrl);
  authReq.headers.contentType = ContentType.json;
  authReq.write(jsonEncode({
    'email': 'admin@factory.com',
    'password': 'Password123!',
    'returnSecureToken': true,
  }));
  final authRes = await authReq.close();
  final authBody = jsonDecode(await authRes.transform(utf8.decoder).join());
  final idToken = authBody['idToken'] as String;
  final uid = authBody['localId'] as String;

  print('UID: $uid');

  final userUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
  );
  final userReq = await client.getUrl(userUrl);
  userReq.headers.set('Authorization', 'Bearer $idToken');
  final userRes = await userReq.close();
  print('User Doc status: ${userRes.statusCode}');
  print('User Doc body: ${await userRes.transform(utf8.decoder).join()}');

  // Let's get specific document /customers/cust_seed_001 directly
  final custUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/customers/cust_seed_001',
  );
  final custReq = await client.getUrl(custUrl);
  custReq.headers.set('Authorization', 'Bearer $idToken');
  final custRes = await custReq.close();
  print('Cust 001 status: ${custRes.statusCode}');
  print('Cust 001 body: ${await custRes.transform(utf8.decoder).join()}');

  client.close(force: true);
}

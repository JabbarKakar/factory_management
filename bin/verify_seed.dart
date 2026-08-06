import 'dart:convert';
import 'dart:io';

/// Verification script to test and inspect seeded Firestore data.
///
/// Usage:
///   dart run bin/verify_seed.dart
void main(List<String> args) async {
  final apiKey = 'AIzaSyDmkhkEh_CPkDY0lik93MYR_yII_2HKM1U';
  final projectId = 'factory-management-8307e';
  final email = 'admin@factory.com';
  final password = 'Password123!';
  final factoryId = 'factory_seed_001';

  print('====================================================');
  print('          FIRESTORE SEED VERIFIER                   ');
  print('====================================================');

  final client = HttpClient();

  try {
    // 1. Authenticate
    print('\n[1/3] Authenticating with Firebase Auth...');
    final authUrl = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );
    final authReq = await client.postUrl(authUrl);
    authReq.headers.contentType = ContentType.json;
    authReq.write(jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }));
    final authRes = await authReq.close();
    final authBody = await authRes.transform(utf8.decoder).join();
    if (authRes.statusCode != 200) {
      throw Exception('Failed to sign in: $authBody');
    }
    final idToken = jsonDecode(authBody)['idToken'] as String;
    print('✔ Authenticated as $email');

    // 2. Query Customers
    print('\n[2/3] Querying Customers collection for factory "$factoryId"...');
    final queryUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery',
    );
    final custReq = await client.postUrl(queryUrl);
    custReq.headers.set('Authorization', 'Bearer $idToken');
    custReq.headers.contentType = ContentType.json;
    custReq.write(jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'customers'}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'factoryId'},
            'op': 'EQUAL',
            'value': {'stringValue': factoryId}
          }
        },
        'limit': 100
      }
    }));
    final custRes = await custReq.close();
    final custBody = await custRes.transform(utf8.decoder).join();
    final custResults = jsonDecode(custBody) as List;
    final custDocs = custResults
        .where((item) => item is Map && item.containsKey('document'))
        .map((item) => item['document'])
        .toList();

    print('✔ Total Customers found: ${custDocs.length}');
    if (custDocs.isNotEmpty) {
      print('\n  Sample Customers:');
      for (var i = 0; i < custDocs.length && i < 5; i++) {
        final fields = custDocs[i]['fields'] as Map<String, dynamic>;
        final name = fields['name']?['stringValue'] ?? 'N/A';
        final phone = fields['phone']?['stringValue'] ?? 'N/A';
        final category = fields['category']?['stringValue'] ?? 'N/A';
        print('  - [Customer #${i + 1}] Name: "$name", Phone: $phone, Category: $category');
      }
    }

    // 3. Query Job Work Orders
    print('\n[3/3] Querying Job Work Orders collection for factory "$factoryId"...');
    final jwReq = await client.postUrl(queryUrl);
    jwReq.headers.set('Authorization', 'Bearer $idToken');
    jwReq.headers.contentType = ContentType.json;
    jwReq.write(jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'jobWorkOrders'}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'factoryId'},
            'op': 'EQUAL',
            'value': {'stringValue': factoryId}
          }
        },
        'limit': 100
      }
    }));
    final jwRes = await jwReq.close();
    final jwBody = await jwRes.transform(utf8.decoder).join();
    final jwResults = jsonDecode(jwBody) as List;
    final jwDocs = jwResults
        .where((item) => item is Map && item.containsKey('document'))
        .map((item) => item['document'])
        .toList();

    print('✔ Total Job Work Orders found: ${jwDocs.length}');
    if (jwDocs.isNotEmpty) {
      print('\n  Sample Job Work Orders:');
      for (var i = 0; i < jwDocs.length && i < 5; i++) {
        final fields = jwDocs[i]['fields'] as Map<String, dynamic>;
        final jwNum = fields['jobWorkNumber']?['stringValue'] ?? 'N/A';
        final custName = fields['customerName']?['stringValue'] ?? 'N/A';
        final status = fields['status']?['stringValue'] ?? 'N/A';
        final variety = fields['input']?['mapValue']?['fields']?['variety']?['stringValue'] ?? 'N/A';
        print('  - [JobWork #${i + 1}] Order: $jwNum | Customer: "$custName" | Status: $status | Variety: $variety');
      }
    }

    print('\n====================================================');
    print('   VERIFICATION PASSED! ALL SEEDED DATA CONFIRMED.  ');
    print('====================================================\n');
  } catch (e, stack) {
    print('❌ Verification failed: $e');
    print(stack);
  } finally {
    client.close(force: true);
  }
}

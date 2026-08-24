import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Standalone Dart script to seed Firestore with mock Customers and Job Work Orders.
///
/// Usage:
///   dart run bin/seed_data.dart [options]
///
/// Options:
///   --email=<email>             Firebase Auth email (default: admin@factory.com)
///   --password=<password>       Firebase Auth password (default: Password123!)
///   --factory-id=<id>           Factory ID (default: factory_seed_001)
///   --customers-count=<n>       Number of customer docs to insert (default: 50)
///   --job-works-count=<n>       Number of job work docs to insert (default: 50)
///   --project-id=<id>           Firebase Project ID (default: factory-management-8307e)
///   --api-key=<key>             Firebase Web API Key
///   --emulator                  Seed the local emulator suite instead of production
///   --emulator-host=<host>      Emulator host (default: localhost)
///
/// Seeding the emulator (does not consume the production quota):
///   firebase emulators:start --import=./.emulator-data --export-on-exit
///   dart run bin/seed_data.dart --emulator
// Overridden to the emulator REST endpoints when `--emulator` is passed.
var _authBase = 'https://identitytoolkit.googleapis.com/v1';
var _firestoreBase = 'https://firestore.googleapis.com/v1';

void main(List<String> args) async {
  final options = _parseArgs(args);
  final useEmulator = options.containsKey('emulator');
  final emulatorHost = options['emulator-host'] ?? 'localhost';
  if (useEmulator) {
    _authBase = 'http://$emulatorHost:9099/identitytoolkit.googleapis.com/v1';
    _firestoreBase = 'http://$emulatorHost:8080/v1';
  }
  final email = options['email'] ?? 'admin@factory.com';
  final password = options['password'] ?? 'Password123!';
  final factoryId = options['factory-id'] ?? 'factory_seed_001';
  final customersCount = int.tryParse(options['customers-count'] ?? '50') ?? 50;
  final jobWorksCount = int.tryParse(options['job-works-count'] ?? '50') ?? 50;
  final projectId = options['project-id'] ?? 'factory-management-8307e';
  final apiKey = options['api-key'] ?? 'AIzaSyDmkhkEh_CPkDY0lik93MYR_yII_2HKM1U';

  print('====================================================');
  print('          FACTORY MANAGEMENT DATA SEEDER            ');
  print('====================================================');
  print('Target             : ${useEmulator ? 'EMULATOR ($emulatorHost)' : 'PRODUCTION'}');
  print('Target Project ID  : $projectId');
  print('Factory ID         : $factoryId');
  print('Auth User          : $email');
  print('Customers to Seed  : $customersCount');
  print('Job Works to Seed  : $jobWorksCount');
  print('----------------------------------------------------');

  final client = HttpClient();

  try {
    // Step 1: Authenticate user via Firebase Auth REST API
    print('\n[1/5] Authenticating with Firebase Auth...');
    final auth = await _authenticate(client, apiKey, email, password);
    final idToken = auth['idToken']!;
    final uid = auth['localId']!;
    print('✔ Authenticated successfully! (UID: $uid)');

    // Step 2: Ensure Factory document exists
    print('\n[2/5] Checking/Creating Factory Profile ($factoryId)...');
    await _ensureFactoryExists(client, projectId, idToken, factoryId, uid);
    print('✔ Factory profile ready.');

    // Step 3: Ensure User Profile document exists
    print('\n[3/5] Checking/Creating User Profile ($uid)...');
    await _ensureUserProfileExists(client, projectId, idToken, uid, email, factoryId);
    print('✔ User profile ready.');

    // Step 4: Seed Customers
    print('\n[4/5] Inserting $customersCount Customers into Firestore...');
    final customers = await _seedCustomers(
      client,
      projectId,
      idToken,
      factoryId,
      customersCount,
    );
    print('✔ Successfully inserted/updated ${customers.length} customers!');

    // Step 5: Seed Job Work Orders
    print('\n[5/5] Inserting $jobWorksCount Job Work Orders into Firestore...');
    await _seedJobWorkOrders(
      client,
      projectId,
      idToken,
      factoryId,
      customers,
      jobWorksCount,
    );
    print('✔ Successfully inserted/updated $jobWorksCount job work orders!');

    print('\n====================================================');
    print('   SEEDING COMPLETED SUCCESSFULLY!                  ');
    print('   Inserted/Updated ${customers.length} Customers & $jobWorksCount Job Works.');
    print('====================================================\n');
  } catch (e, stack) {
    print('\n❌ ERROR DURING SEEDING: $e');
    print(stack);
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      } else if (parts.length == 1) {
        map[parts[0]] = 'true';
      }
    }
  }
  return map;
}

Future<Map<String, String>> _authenticate(
  HttpClient client,
  String apiKey,
  String email,
  String password,
) async {
  var url = Uri.parse(
    '$_authBase/accounts:signInWithPassword?key=$apiKey',
  );
  var req = await client.postUrl(url);
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'email': email,
    'password': password,
    'returnSecureToken': true,
  }));
  var res = await req.close();
  var body = await res.transform(utf8.decoder).join();

  if (res.statusCode == 200) {
    final data = jsonDecode(body);
    return {
      'idToken': data['idToken'] as String,
      'localId': data['localId'] as String,
    };
  }

  url = Uri.parse(
    '$_authBase/accounts:signUp?key=$apiKey',
  );
  req = await client.postUrl(url);
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'email': email,
    'password': password,
    'returnSecureToken': true,
  }));
  res = await req.close();
  body = await res.transform(utf8.decoder).join();

  if (res.statusCode == 200) {
    final data = jsonDecode(body);
    return {
      'idToken': data['idToken'] as String,
      'localId': data['localId'] as String,
    };
  }

  throw Exception('Authentication failed ($email): $body');
}

Future<void> _ensureFactoryExists(
  HttpClient client,
  String projectId,
  String idToken,
  String factoryId,
  String ownerUid,
) async {
  final url = Uri.parse(
    '$_firestoreBase/projects/$projectId/databases/(default)/documents/factories/$factoryId',
  );
  final req = await client.patchUrl(url);
  req.headers.set('Authorization', 'Bearer $idToken');
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'fields': {
      'name': {'stringValue': 'Main Seed Factory'},
      'ownerUserId': {'stringValue': ownerUid},
      'status': {'stringValue': 'active'},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    }
  }));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();

  if (res.statusCode != 200) {
    throw Exception('Failed to upsert factory doc: $body');
  }
}

Future<void> _ensureUserProfileExists(
  HttpClient client,
  String projectId,
  String idToken,
  String uid,
  String email,
  String factoryId,
) async {
  final url = Uri.parse(
    '$_firestoreBase/projects/$projectId/databases/(default)/documents/users/$uid',
  );
  final req = await client.patchUrl(url);
  req.headers.set('Authorization', 'Bearer $idToken');
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'fields': {
      'email': {'stringValue': email},
      'name': {'stringValue': 'Admin User'},
      'role': {'stringValue': 'owner'},
      'factoryId': {'stringValue': factoryId},
      'status': {'stringValue': 'active'},
      'onboardingComplete': {'booleanValue': true},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    }
  }));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();

  if (res.statusCode != 200) {
    throw Exception('Failed to upsert user doc: $body');
  }
}

class _CustomerData {
  _CustomerData({required this.id, required this.name});
  final String id;
  final String name;
}

Future<List<_CustomerData>> _seedCustomers(
  HttpClient client,
  String projectId,
  String idToken,
  String factoryId,
  int count,
) async {
  final random = Random();
  final companyPrefixes = [
    'Al-Madina', 'Tariq', 'Ziarat', 'Karakoram', 'Peshawar',
    'Indus', 'Kohinoor', 'Balochistan', 'Grand', 'Apex',
    'Royal', 'Standard', 'National', 'Pak-Afghan', 'Crescent',
    'Habib', 'Sultan', 'United', 'Mehran', 'Khyber'
  ];
  final companySuffixes = [
    'Marbles', 'Granites', 'Stone Industry', 'Traders', 'Buildtech',
    'Constructions', 'Stones & Slabs', 'Exports', 'Suppliers',
    'Mining Co.', 'Enterprises', 'Corporation', 'Holdings'
  ];
  final personNames = [
    'Tariq Mahmood', 'Muhammad Bilal', 'Usman Ghani', 'Kamran Shahid',
    'Zahid Khan', 'Asif Ali', 'Ahmed Hassan', 'Imran Raza',
    'Rashid Minhas', 'Sohail Ahmed', 'Faisal Shah', 'Omer Farooq',
    'Zubair Butt', 'Nabeel Chaudhry', 'Waqar Younis'
  ];
  final cities = [
    'Karachi', 'Lahore', 'Rawalpindi', 'Quetta', 'Islamabad',
    'Peshawar', 'Multan', 'Faisalabad', 'Gujranwala', 'Hyderabad'
  ];
  final provinces = [
    'Punjab', 'Sindh', 'KPK', 'Balochistan', 'Islamabad Capital Territory'
  ];
  final categories = ['retail', 'wholesale', 'vip', 'standard'];
  final customerTypes = ['commercial', 'individual', 'government'];
  final paymentTermsList = ['cash', 'net15', 'net30', 'net60'];

  final seededCustomers = <_CustomerData>[];
  final now = DateTime.now();

  for (var i = 1; i <= count; i++) {
    final custId = 'cust_seed_${i.toString().padLeft(3, '0')}';
    final isCommercial = random.nextDouble() > 0.3;
    final name = isCommercial
        ? '${companyPrefixes[random.nextInt(companyPrefixes.length)]} ${companySuffixes[random.nextInt(companySuffixes.length)]} #$i'
        : '${personNames[random.nextInt(personNames.length)]} ($i)';

    final city = cities[random.nextInt(cities.length)];
    final province = provinces[random.nextInt(provinces.length)];
    final category = categories[random.nextInt(categories.length)];
    final custType = isCommercial
        ? 'commercial'
        : customerTypes[random.nextInt(customerTypes.length)];
    final paymentTerms =
        paymentTermsList[random.nextInt(paymentTermsList.length)];
    final creditLimit = (random.nextInt(20) + 1) * 25000.0;
    final openingBal = (random.nextInt(10)) * 5000.0;
    final balance = openingBal + (random.nextInt(10)) * 2000.0;
    final phone =
        '+923${random.nextInt(90) + 10}${random.nextInt(9000000) + 1000000}';
    final daysAgo = random.nextInt(180);
    final createdAt = now.subtract(Duration(days: daysAgo));

    final docData = {
      'fields': {
        'factoryId': {'stringValue': factoryId},
        'customerType': {'stringValue': custType},
        'name': {'stringValue': name},
        'contactPersonName': {
          'stringValue': personNames[random.nextInt(personNames.length)]
        },
        'phone': {'stringValue': phone},
        'phoneSecondary': {
          'stringValue':
              '+923${random.nextInt(90) + 10}${random.nextInt(9000000) + 1000000}'
        },
        'email': {
          'stringValue':
              'customer$i@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com'
        },
        'billingStreet': {
          'stringValue': 'Plot ${random.nextInt(200) + 1}, Industrial Area'
        },
        'billingCity': {'stringValue': city},
        'billingProvince': {'stringValue': province},
        'shippingStreet': {
          'stringValue': 'Plot ${random.nextInt(200) + 1}, Industrial Area'
        },
        'shippingCity': {'stringValue': city},
        'shippingProvince': {'stringValue': province},
        'useSameShippingAddress': {'booleanValue': true},
        'cnicNtn': {
          'stringValue':
              '${random.nextInt(89999) + 10000}-${random.nextInt(8999999) + 1000000}-${random.nextInt(9) + 1}'
        },
        'category': {'stringValue': category},
        'serviceType': {'stringValue': 'job_work'},
        'serviceTypes': {
          'arrayValue': {
            'values': [
              {'stringValue': 'job_work'}
            ]
          }
        },
        'creditLimit': {'doubleValue': creditLimit},
        'paymentTerms': {'stringValue': paymentTerms},
        'balance': {'doubleValue': balance},
        'openingBalance': {'doubleValue': openingBal},
        'createdAt': {'timestampValue': createdAt.toUtc().toIso8601String()},
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      }
    };

    final url = Uri.parse(
      '$_firestoreBase/projects/$projectId/databases/(default)/documents/customers/$custId',
    );
    final req = await client.patchUrl(url);
    req.headers.set('Authorization', 'Bearer $idToken');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(docData));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode == 200) {
      seededCustomers.add(_CustomerData(id: custId, name: name));
    } else {
      print('Warning: Failed customer $custId: $body');
    }

    if (i % 10 == 0 || i == count) {
      print('  Inserted/Updated $i / $count customers...');
    }
  }

  return seededCustomers;
}

Future<void> _seedJobWorkOrders(
  HttpClient client,
  String projectId,
  String idToken,
  String factoryId,
  List<_CustomerData> customers,
  int count,
) async {
  final random = Random();
  final varieties = [
    'Ziarat White', 'Boticina', 'Badal', 'Sunny Grey', 'Black & Gold',
    'Verde Guatemala', 'Travertine', 'Silky Black', 'Tora Gold', 'Granite Pink'
  ];
  final strategies = ['standard', 'custom', 'highYield', 'fastDelivery'];
  final targetProducts = ['slabs', 'tiles', 'blocks', 'custom'];
  final finishes = ['raw', 'polished', 'honed', 'brushed', 'bushHammered'];
  final thicknesses = ['18mm', '20mm', '25mm', '30mm'];
  final pricingModels = ['perTon', 'perSqFt', 'fixedRate'];
  final paymentTermsList = ['cash', 'net15', 'net30', 'net60'];
  final mineLocations = [
    'Ziarat, Balochistan', 'Mardan, KPK', 'Khuzdar, Balochistan',
    'Swat, KPK', 'Nowshera, KPK'
  ];
  final mineOwners = [
    'Khan Minerals', 'Ziarat Mining Corp', 'Karakoram Stones',
    'Baloch Mining Enterprise', 'Indus Mineral Suppliers'
  ];
  final vehicleNumbers = [
    'LES-1234', 'KHI-9876', 'PKE-5544', 'QTA-3311', 'ISL-7788', 'MLT-4422'
  ];
  final statuses = [
    'agreed', 'inCutting', 'qc', 'ready', 'collected', 'closed', 'cancelled'
  ];

  final now = DateTime.now();

  for (var i = 1; i <= count; i++) {
    final jwId = 'jw_seed_${i.toString().padLeft(3, '0')}';
    final jwNumber = 'JW-${now.year}-${i.toString().padLeft(4, '0')}';

    final customer = customers.isNotEmpty
        ? customers[random.nextInt(customers.length)]
        : _CustomerData(id: 'cust_seed_001', name: 'Al-Madina Marbles');

    final variety = varieties[random.nextInt(varieties.length)];
    final strategy = strategies[random.nextInt(strategies.length)];
    final targetProduct = targetProducts[random.nextInt(targetProducts.length)];
    final finish = finishes[random.nextInt(finishes.length)];
    final thickness = thicknesses[random.nextInt(thicknesses.length)];
    final pricingModel = pricingModels[random.nextInt(pricingModels.length)];
    final status = statuses[random.nextInt(statuses.length)];
    final paymentTerms =
        paymentTermsList[random.nextInt(paymentTermsList.length)];

    final blockCount = random.nextInt(15) + 1;
    final totalTons = (random.nextInt(150) + 10) * 1.5;
    final agreedRate = pricingModel == 'perTon'
        ? (random.nextInt(10) + 10) * 100.0
        : (random.nextInt(20) + 20) * 5.0;

    final totalCharges = totalTons * agreedRate;
    final advanceReceived = (random.nextInt(5)) * (totalCharges / 5);
    final balanceDue = totalCharges - advanceReceived;

    final daysAgo = random.nextInt(120);
    final receivedDate = now.subtract(Duration(days: daysAgo));
    final expectedDate = receivedDate.add(Duration(days: random.nextInt(30) + 5));

    final docData = {
      'fields': {
        'jobWorkNumber': {'stringValue': jwNumber},
        'factoryId': {'stringValue': factoryId},
        'customerId': {'stringValue': customer.id},
        'customerName': {'stringValue': customer.name},
        'status': {'stringValue': status},
        'receivedDate': {
          'timestampValue': receivedDate.toUtc().toIso8601String()
        },
        'expectedCompletionDate': {
          'timestampValue': expectedDate.toUtc().toIso8601String()
        },
        'mineLocation': {
          'stringValue': mineLocations[random.nextInt(mineLocations.length)]
        },
        'mineOwner': {
          'stringValue': mineOwners[random.nextInt(mineOwners.length)]
        },
        'input': {
          'mapValue': {
            'fields': {
              'variety': {'stringValue': variety},
              'blockCount': {'integerValue': blockCount.toString()},
              'totalTons': {'doubleValue': totalTons},
              'dimensions': {
                'stringValue':
                    '${random.nextInt(5) + 8}x${random.nextInt(3) + 4}x${random.nextInt(3) + 3} ft'
              },
              'notes': {'stringValue': 'Quality marble blocks for $targetProduct'},
              'vehicleNumber': {
                'stringValue': vehicleNumbers[random.nextInt(vehicleNumbers.length)]
              },
            }
          }
        },
        'cuttingSpec': {
          'mapValue': {
            'fields': {
              'strategy': {'stringValue': strategy},
              'targetProduct': {'stringValue': targetProduct},
              'smallSizes': {
                'arrayValue': {
                  'values': [
                    {'stringValue': '12x12'},
                    {'stringValue': '12x24'}
                  ]
                }
              },
              'largeSizes': {
                'arrayValue': {
                  'values': [
                    {'stringValue': '24x24'},
                    {'stringValue': '36x36'}
                  ]
                }
              },
              'thickness': {'stringValue': thickness},
              'finish': {'stringValue': finish},
              'specialInstructions': {
                'stringValue': 'Handle with care during gangsaw loading'
              },
            }
          }
        },
        'pricing': {
          'mapValue': {
            'fields': {
              'model': {'stringValue': pricingModel},
              'agreedRate': {'doubleValue': agreedRate},
              'smallStockPrice': {'doubleValue': 0.0},
              'largeStockPrice': {'doubleValue': 0.0},
              'finalCuttingCharges': {'doubleValue': totalCharges},
              'advanceReceived': {'doubleValue': advanceReceived},
              'balanceDue': {'doubleValue': balanceDue},
              'paymentTerms': {'stringValue': paymentTerms},
            }
          }
        },
        'schemaVersion': {'integerValue': '2'},
        'createdAt': {
          'timestampValue': receivedDate.toUtc().toIso8601String()
        },
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String()
        },
      }
    };

    final url = Uri.parse(
      '$_firestoreBase/projects/$projectId/databases/(default)/documents/jobWorkOrders/$jwId',
    );
    final req = await client.patchUrl(url);
    req.headers.set('Authorization', 'Bearer $idToken');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(docData));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode != 200) {
      print('Warning: Failed job work $jwId: $body');
    }

    if (i % 10 == 0 || i == count) {
      print('  Inserted/Updated $i / $count job work orders...');
    }
  }
}

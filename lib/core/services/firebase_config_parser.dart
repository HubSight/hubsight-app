import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';

const androidFirebasePackageName = 'com.quoctran.hubsight';
const storedAndroidFirebaseOptionsKey = 'hubsight_firebase_android_options';

/// Parses the Android Firebase client embedded in a runtime `.hscfg` profile.
FirebaseOptions parseAndroidFirebaseOptions(
  String googleServicesJson, {
  String packageName = androidFirebasePackageName,
}) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(googleServicesJson);
  } on FormatException catch (error) {
    throw FormatException('Invalid google-services.json: ${error.message}');
  }

  final root = _requiredMap(decoded, 'root');
  final projectInfo = _requiredMap(root['project_info'], 'project_info');
  final clients = _requiredList(root['client'], 'client');

  Map<String, dynamic>? selectedClient;
  for (final candidate in clients) {
    final client = _requiredMap(candidate, 'client[]');
    final clientInfo = _requiredMap(client['client_info'], 'client_info');
    final androidInfo = _requiredMap(
      clientInfo['android_client_info'],
      'android_client_info',
    );
    if (_requiredString(androidInfo['package_name'], 'package_name') ==
        packageName) {
      selectedClient = client;
      break;
    }
  }

  if (selectedClient == null) {
    throw FormatException(
      'google-services.json does not contain an Android client for '
      '$packageName.',
    );
  }

  final clientInfo = _requiredMap(
    selectedClient['client_info'],
    'client_info',
  );
  final apiKeys = _requiredList(selectedClient['api_key'], 'api_key');
  String? apiKey;
  for (final candidate in apiKeys) {
    final key = _requiredMap(candidate, 'api_key[]')['current_key'];
    if (key is String && key.trim().isNotEmpty) {
      apiKey = key.trim();
      break;
    }
  }
  if (apiKey == null) {
    throw const FormatException(
      'google-services.json is missing api_key.current_key.',
    );
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: _requiredString(clientInfo['mobilesdk_app_id'], 'mobilesdk_app_id'),
    messagingSenderId: _requiredString(
      projectInfo['project_number'],
      'project_number',
    ),
    projectId: _requiredString(projectInfo['project_id'], 'project_id'),
    databaseURL: _optionalString(projectInfo['firebase_url']),
    storageBucket: _optionalString(projectInfo['storage_bucket']),
  );
}

String encodeFirebaseOptions(FirebaseOptions options) {
  return jsonEncode(<String, String?>{
    'apiKey': options.apiKey,
    'appId': options.appId,
    'messagingSenderId': options.messagingSenderId,
    'projectId': options.projectId,
    'databaseURL': options.databaseURL,
    'storageBucket': options.storageBucket,
  });
}

FirebaseOptions decodeFirebaseOptions(String encoded) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(encoded);
  } on FormatException catch (error) {
    throw FormatException('Invalid stored Firebase options: ${error.message}');
  }
  final values = _requiredMap(decoded, 'Firebase options');
  return FirebaseOptions(
    apiKey: _requiredString(values['apiKey'], 'apiKey'),
    appId: _requiredString(values['appId'], 'appId'),
    messagingSenderId: _requiredString(
      values['messagingSenderId'],
      'messagingSenderId',
    ),
    projectId: _requiredString(values['projectId'], 'projectId'),
    databaseURL: _optionalString(values['databaseURL']),
    storageBucket: _optionalString(values['storageBucket']),
  );
}

bool firebaseOptionsMatch(FirebaseOptions first, FirebaseOptions second) {
  return first.apiKey == second.apiKey &&
      first.appId == second.appId &&
      first.messagingSenderId == second.messagingSenderId &&
      first.projectId == second.projectId &&
      first.databaseURL == second.databaseURL &&
      first.storageBucket == second.storageBucket;
}

Map<String, dynamic> _requiredMap(dynamic value, String field) {
  if (value is! Map) {
    throw FormatException(
        'google-services.json field "$field" must be an object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<dynamic> _requiredList(dynamic value, String field) {
  if (value is! List || value.isEmpty) {
    throw FormatException(
      'google-services.json field "$field" must be a non-empty array.',
    );
  }
  return value;
}

String _requiredString(dynamic value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return value.toString();
  throw FormatException(
    'google-services.json is missing required field "$field".',
  );
}

String? _optionalString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

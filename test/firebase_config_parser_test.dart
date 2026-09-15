import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_app/core/services/firebase_config_parser.dart';

void main() {
  group('parseAndroidFirebaseOptions', () {
    test('selects the client matching the HubSight Android package', () {
      final options = parseAndroidFirebaseOptions(
        _configJson(clients: [
          _client('com.example.other', appId: 'other-app'),
          _client(
            androidFirebasePackageName,
            appId: 'hubsight-app',
            apiKey: 'hubsight-key',
          ),
        ]),
      );

      expect(options.appId, 'hubsight-app');
      expect(options.apiKey, 'hubsight-key');
      expect(options.projectId, 'project-id');
      expect(options.messagingSenderId, '123456789');
      expect(options.storageBucket, 'project-id.appspot.com');
    });

    test('does not silently use a client for another package', () {
      expect(
        () => parseAndroidFirebaseOptions(
          _configJson(clients: [_client('com.example.other')]),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(androidFirebasePackageName),
          ),
        ),
      );
    });

    test('throws when a required project field is missing', () {
      final config = jsonDecode(
        _configJson(clients: [_client(androidFirebasePackageName)]),
      ) as Map<String, dynamic>;
      (config['project_info'] as Map<String, dynamic>).remove('project_id');

      expect(
        () => parseAndroidFirebaseOptions(jsonEncode(config)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('project_id'),
          ),
        ),
      );
    });

    test('throws for malformed JSON', () {
      expect(
        () => parseAndroidFirebaseOptions('{not-json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('stored Firebase options round-trip', () {
      final original = parseAndroidFirebaseOptions(
        _configJson(clients: [_client(androidFirebasePackageName)]),
      );

      final restored = decodeFirebaseOptions(encodeFirebaseOptions(original));

      expect(firebaseOptionsMatch(original, restored), isTrue);
      expect(restored.databaseURL, original.databaseURL);
      expect(restored.storageBucket, original.storageBucket);
    });
  });
}

String _configJson({required List<Map<String, dynamic>> clients}) {
  return jsonEncode({
    'project_info': {
      'project_number': '123456789',
      'project_id': 'project-id',
      'firebase_url': 'https://project-id.firebaseio.com',
      'storage_bucket': 'project-id.appspot.com',
    },
    'client': clients,
  });
}

Map<String, dynamic> _client(
  String packageName, {
  String appId = 'default-app-id',
  String apiKey = 'default-api-key',
}) {
  return {
    'client_info': {
      'mobilesdk_app_id': appId,
      'android_client_info': {'package_name': packageName},
    },
    'api_key': [
      {'current_key': apiKey},
    ],
  };
}

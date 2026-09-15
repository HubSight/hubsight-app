import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_app/core/services/passkey_service.dart';

void main() {
  group('HubSightPasskeyOptions', () {
    test('parses the backend challenge envelope', () {
      final options = HubSightPasskeyOptions.fromResponse({
        'challenge_id': 'challenge-123',
        'publicKey': {
          'challenge': 'base64url-challenge',
          'rpId': 'cctv.example.com',
          'allowCredentials': <Object>[],
        },
      });

      expect(options.challengeId, 'challenge-123');
      expect(options.publicKey, {
        'challenge': 'base64url-challenge',
        'rpId': 'cctv.example.com',
        'allowCredentials': <Object>[],
      });
    });

    test('rejects a missing challenge_id', () {
      expect(
        () => HubSightPasskeyOptions.fromResponse({
          'publicKey': {'challenge': 'challenge'},
        }),
        throwsFormatException,
      );
    });

    test('rejects an empty challenge_id', () {
      expect(
        () => HubSightPasskeyOptions.fromResponse({
          'challenge_id': '   ',
          'publicKey': {'challenge': 'challenge'},
        }),
        throwsFormatException,
      );
    });

    test('rejects a missing or invalid publicKey object', () {
      expect(
        () => HubSightPasskeyOptions.fromResponse({
          'challenge_id': 'challenge-123',
        }),
        throwsFormatException,
      );
      expect(
        () => HubSightPasskeyOptions.fromResponse({
          'challenge_id': 'challenge-123',
          'publicKey': 'not-an-object',
        }),
        throwsFormatException,
      );
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return NativePasskeyService();
});

class HubSightPasskeyOptions {
  const HubSightPasskeyOptions({
    required this.challengeId,
    required this.publicKey,
  });

  factory HubSightPasskeyOptions.fromResponse(Map<String, dynamic> response) {
    final challengeId = response['challenge_id'];
    final publicKey = response['publicKey'];

    if (challengeId is! String || challengeId.trim().isEmpty) {
      throw const FormatException(
        'Passkey options are missing a valid challenge_id.',
      );
    }
    if (publicKey is! Map) {
      throw const FormatException(
        'Passkey options are missing a valid publicKey object.',
      );
    }

    return HubSightPasskeyOptions(
      challengeId: challengeId,
      publicKey: Map<String, dynamic>.from(publicKey),
    );
  }

  final String challengeId;
  final Map<String, dynamic> publicKey;
}

abstract class PasskeyService {
  Future<String> register(Map<String, dynamic> publicKey);

  Future<String> authenticate(Map<String, dynamic> publicKey);
}

class NativePasskeyService implements PasskeyService {
  NativePasskeyService({PasskeyAuthenticator? authenticator})
      : _authenticator = authenticator ?? PasskeyAuthenticator();

  final PasskeyAuthenticator _authenticator;

  @override
  Future<String> register(Map<String, dynamic> publicKey) async {
    final request = RegisterRequestType.fromJson(publicKey);
    final response = await _authenticator.register(request);
    return response.toJsonString();
  }

  @override
  Future<String> authenticate(Map<String, dynamic> publicKey) async {
    final request = AuthenticateRequestType.fromJson(
      publicKey,
      mediation: MediationType.Optional,
      preferImmediatelyAvailableCredentials: false,
      canBeSecurityKey: true,
    );
    final response = await _authenticator.authenticate(request);
    return response.toJsonString();
  }
}

class PushPreferences {
  final bool family;
  final bool guest;
  final bool stranger;
  final bool system;

  PushPreferences({
    this.family = true,
    this.guest = true,
    this.stranger = true,
    this.system = true,
  });

  factory PushPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PushPreferences();
    return PushPreferences(
      family: json['family'] ?? true,
      guest: json['guest'] ?? true,
      stranger: json['stranger'] ?? true,
      system: json['system'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'family': family,
    'guest': guest,
    'stranger': stranger,
    'system': system,
  };
}

class User {
  final String id;
  final String username;
  final String? email;
  final String role;
  final String locale;
  final String timezone;
  final PushPreferences pushPreferences;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    this.email,
    this.role = 'admin',
    this.locale = 'vi',
    this.timezone = 'UTC+7',
    PushPreferences? pushPreferences,
    this.avatarUrl,
  }) : pushPreferences = pushPreferences ?? PushPreferences();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? 'admin',
      email: json['email'],
      role: json['role'] ?? 'admin',
      locale: json['locale'] ?? 'vi',
      timezone: json['timezone'] ?? 'UTC+7',
      pushPreferences: PushPreferences.fromJson(json['push_preferences']),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'role': role,
    'locale': locale,
    'timezone': timezone,
    'push_preferences': pushPreferences.toJson(),
    'avatar_url': avatarUrl,
  };
}

class LoginResponse {
  final String token;
  final User? user;

  LoginResponse({
    required this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? json['access_token'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}


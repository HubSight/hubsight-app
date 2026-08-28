import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/fcm_service.dart';
import 'core/storage/storage_service.dart';
import 'features/auth/login_screen.dart';
import 'features/config/server_config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local preferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HubSightApp(),
    ),
  );
}

class HubSightApp extends ConsumerStatefulWidget {
  const HubSightApp({super.key});

  @override
  ConsumerState<HubSightApp> createState() => _HubSightAppState();
}

class _HubSightAppState extends ConsumerState<HubSightApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM Push Notifications (resilient if config added later)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final hasServer = storage.hasServerUrl();

    return MaterialApp(
      title: 'HubSight CCTV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE85D10)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      // Set to vi by default as per mockups, or let the system decide
      locale: const Locale('vi'),
      home: hasServer
          ? const LoginScreen()
          : const ServerConfigScreen(isInitialSetup: true),
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/config/ad_config.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/title_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AdMob 初期化 (広告有効時のみ)
  if (AdConfig.adsEnabled && (Platform.isIOS || Platform.isAndroid)) {
    await MobileAds.instance.initialize();
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WalkPetApp(),
    ),
  );
}

class WalkPetApp extends ConsumerWidget {
  const WalkPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return MaterialApp(
      title: 'あるくペット',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8F5E9),
          foregroundColor: Color(0xFF2E7D32),
          elevation: 0,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFFF5),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: onboardingCompleted
          ? const TitleScreen()
          : const OnboardingScreen(),
    );
  }
}

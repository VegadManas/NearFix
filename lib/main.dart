import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen/home_screen.dart';
import 'onboarding_screen/onboarding_screen.dart';
import 'authentication/sign_in.dart'; // Import your Login/SignIn screen
import 'supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This function now returns a String to decide which screen to show
  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();

    bool hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!hasSeenOnboarding) return 'onboarding';
    if (!isLoggedIn) return 'login';
    return 'home';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String>(
        future: _getInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Decide which screen to show based on the saved data
          if (snapshot.data == 'onboarding') {
            return const OnboardingScreen();
          } else if (snapshot.data == 'login') {
            return const LoginScreen(); // Your Login Screen
          } else {
            return const HomeScreen(); // Or ProfileScreen
          }
        },
      ),
    );
  }
}

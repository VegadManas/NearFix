import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../authentication/sign_in.dart';
import '../home_screen/home_screen.dart';
const Color primaryBtnColor = Color.fromARGB(255, 51, 54, 93);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  int currentPage = 0;

  final List<String> images = [
    "assets/on2.png",
    "assets/on3.png",
    "assets/on1.png",
  ];




  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);

    // Check if they are already logged in (unlikely on first run, but good practice)
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // ✅ If not logged in, send them to LoginScreen after onboarding
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
  PageViewModel _buildPage(String image) {
    return PageViewModel(
      title: "",
      body: "",
      decoration: const PageDecoration(
        fullScreen: true,
        contentMargin: EdgeInsets.zero,
        imagePadding: EdgeInsets.zero,
        bodyPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
      ),
      image: SizedBox.expand(
        child: Image.asset(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        key: introKey,

        globalBackgroundColor: Colors.white,

        pages: images.map(_buildPage).toList(),

        onChange: (index) {
          setState(() {
            currentPage = index;
          });
        },
        showNextButton: false,
        showDoneButton: false,
        dotsDecorator: const DotsDecorator(
          activeColor: Colors.black,
          color: Colors.black26,
        ),
        globalFooter: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (currentPage == images.length - 1) {
                  _completeOnboarding();
                } else {
                  introKey.currentState?.next();
                }
              },
              child: Text(
                currentPage == images.length - 1
                    ? "Get Started"
                    : "Next",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

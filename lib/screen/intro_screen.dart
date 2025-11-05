import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';

import 'login_page.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntroductionScreen(
      globalBackgroundColor: theme.colorScheme.background,
      pages: [
        PageViewModel(
          title: "Expenses Group",
          body:
              "Organize your expenses into shared or personal groups for better tracking and collaboration.",
          image: _buildLottie('assets/lottie/group.json'),
          decoration: _getPageDecoration(theme),
        ),
        PageViewModel(
          title: "Expense Reminder",
          body:
              "Never miss a bill or payment again. Set reminders and manage your expenses smartly.",
          image: _buildLottie('assets/lottie/reminder.json'),
          decoration: _getPageDecoration(theme),
        ),
        PageViewModel(
          title: "Savings Goal",
          body:
              "Plan your savings, set achievable targets, and visualize your progress easily.",
          image: _buildLottie('assets/lottie/goals.json'),
          decoration: _getPageDecoration(theme),
        ),
        PageViewModel(
          title: "Charts & Reports Export",
          body:
              "Analyze your spending habits using rich charts and export detailed financial reports.",
          image: _buildLottie('assets/lottie/chart.json'),
          decoration: _getPageDecoration(theme),
        ),
        PageViewModel(
          title: "Light & Dark Theme",
          body:
              "Enjoy your experience in light or dark mode — perfectly tuned for comfort and clarity.",
          image: _buildLottie('assets/lottie/theme.json'),
          decoration: _getPageDecoration(theme),
          footer: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              onPressed: () => _onIntroEnd(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              icon: Icon(FontAwesomeIcons.check),
              label: const Text(
                "GET STARTED",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
      dotsDecorator: DotsDecorator(
        size: const Size(10, 10),
        color: Colors.grey.shade400,
        activeSize: const Size(22, 10),
        activeColor: theme.colorScheme.primary,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      curve: Curves.bounceInOut,
      animationDuration: 500,
    );
  }

  static Widget _buildLottie(String assetPath) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Lottie.asset(assetPath, height: 260, repeat: true),
    );
  }

  static PageDecoration _getPageDecoration(ThemeData theme) {
    return PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      bodyTextStyle: TextStyle(fontSize: 17.5),
      imagePadding: const EdgeInsets.only(top: 40),
    );
  }

  void _onIntroEnd(BuildContext context) async {
    var box = await Hive.openBox('appBox');
    box.put('hasSeenIntro', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

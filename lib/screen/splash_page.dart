import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wisepaise/screen/expense_search_page.dart';

class SplashPage extends StatelessWidget {
  bool conn;

  SplashPage({super.key, required this.conn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Center(
                child: Hero(
                  tag: 'logo',
                  transitionOnUserGestures: true,
                  child: Image.asset(
                    !isDark
                        ? 'assets/logos/logo_light.png'
                        : 'assets/logos/logo_dark.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Spacer(),
              conn
                  ? PulsingWarningContainer(
                    message: 'Not connected to the internet',
                  )
                  : CupertinoActivityIndicator(),
              SizedBox(height: 25.0),
            ],
          ),
        ),
      ),
    );
  }
}

class PulsingWarningContainer extends StatefulWidget {
  final String message;

  const PulsingWarningContainer({super.key, required this.message});

  @override
  State<PulsingWarningContainer> createState() =>
      _PulsingWarningContainerState();
}

class _PulsingWarningContainerState extends State<PulsingWarningContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // infinite pulse

    // Glow opacity: 0.6 → 1.0
    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Scale: 0.98 → 1.02 for subtle breathing
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(10.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.red.withOpacity(_glowAnimation.value)
                          : Colors.redAccent.withOpacity(_glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.white54,
                ),
                const SizedBox(width: 10.0),
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/connectivity_provider.dart';
import 'package:wisepaise/providers/notification_provider.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/screen/dashboard_page.dart';
import 'package:wisepaise/screen/login_page.dart';
import 'package:wisepaise/screen/home_page.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisepaise/screen/splash_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  await Hive.openBox('settings');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ApiProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  GoogleSignInAccount? _initialUser;
  bool _checking = true;
  bool? _previousConnection;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    await Future.delayed(Duration(seconds: 1));
    try {
      final user = await auth.getSignedInUser();
      setState(() {
        _initialUser = user;
        _checking = false;
      });
    } catch (e) {
      debugPrint("Silent sign-in error: $e");
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Consumer<ConnectivityProvider>(
      builder: (_, conn, __) {
        final isConnected = conn.isConnected;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_previousConnection == true && !isConnected) {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) => SplashPage(conn: true)),
            );
          }

          if (_previousConnection == false && isConnected) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final isLoggedIn = await auth.isUserLoggedIn(); // <-- new method (see below)

            if (isLoggedIn) {
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (_) => const MyDashboardPage()),
              );
            } else {
              navigatorKey.currentState?.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          }


          _previousConnection = isConnected;
        });

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: settings.themeMode,
          // 🌞 Light theme
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: GoogleFonts.rubik().fontFamily,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),

          // 🌙 Dark theme
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: GoogleFonts.rubik().fontFamily,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          home:
              _checking
                  ? SplashPage(conn: false)
                  : StreamBuilder<GoogleSignInAccount?>(
                    stream: _googleSignIn.onCurrentUserChanged,
                    initialData: _initialUser,
                    builder: (context, snapshot) {
                      Widget rootPage =
                          snapshot.hasData
                              ? const MyDashboardPage()
                              : const LoginPage();

                      return rootPage;
                    },
                  ),
        );
      },
    );
  }
}

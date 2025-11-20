import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:wisepaise/models/user_model.dart';
import 'package:wisepaise/providers/api_provider.dart';
import 'package:wisepaise/providers/connectivity_provider.dart';
import 'package:wisepaise/services/notification_service.dart';
import 'package:wisepaise/providers/settings_provider.dart';
import 'package:wisepaise/screen/create_expense_group_page.dart';
import 'package:wisepaise/screen/create_expense_page.dart';
import 'package:wisepaise/screen/create_reminder_page.dart';
import 'package:wisepaise/screen/create_savings_goal_page.dart';
import 'package:wisepaise/screen/intro_screen.dart';
import 'package:wisepaise/screen/login_page.dart';
import 'package:wisepaise/screen/home_page.dart';
import 'package:wisepaise/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisepaise/screen/splash_page.dart';

import 'models/reminder_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  NotificationService().init();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  var box = await Hive.openBox('appBox');

  bool hasSeenIntro = box.get('hasSeenIntro', defaultValue: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ApiProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
      ],
      child: MyApp(hasSeenIntro: hasSeenIntro),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenIntro;

  const MyApp({super.key, required this.hasSeenIntro});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  GoogleSignInAccount? _initialUser;
  bool _checking = true;
  bool? _previousConnection;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final QuickActions quickActions = const QuickActions();
  String shortcut = 'no action set';

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
    quickActions.initialize((String? shortcutType) {
      setState(() {
        shortcut = shortcutType ?? 'none';
      });

      if (shortcutType == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final isLoggedIn = await auth.isUserLoggedIn();

        if (!isLoggedIn) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          return;
        }

        switch (shortcutType) {
          case 'add_expense':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder:
                    (context) => CreateExpensePage(
                      expense: {},
                      group: {},
                      showGroup: true,
                    ),
              ),
            );
            break;
          case 'add_reminder':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder:
                    (context) =>
                        CreateReminderPage(reminder: ReminderModel.empty()),
              ),
            );
            break;
          case 'create_group':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => CreateExpenseGroupPage(group: {}),
              ),
            );
            break;
          case 'create_goal':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => CreateSavingsGoalPage(goal: {}),
              ),
            );
            break;
        }
      });
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'create_group',
        localizedTitle: 'Create a Group',
        icon: 'people',
      ),
      const ShortcutItem(
        type: 'create_goal',
        localizedTitle: 'Set a Goal',
        icon: 'goal',
      ),
      const ShortcutItem(
        type: 'add_reminder',
        localizedTitle: 'Set a Reminder',
        icon: 'alarm',
      ),

      const ShortcutItem(
        type: 'add_expense',
        localizedTitle: 'Add an Expense',
        icon: 'receipt',
      ),
    ]);
  }

  Future<void> _initGoogleSignIn() async {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    await Future.delayed(Duration(seconds: 1));
    try {
      final user = await auth.getSignedInUser();
      setState(() {
        _initialUser = user;
        _checking = false;
        auth.setUser(
          UserModel(
            userId: user!.id,
            userName: user.displayName!,
            userEmail: user.email,
            userImageUrl: user.photoUrl!,
            userCreatedOn: '',
          ).toJson(),
        );
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
            final isLoggedIn =
                await auth.isUserLoggedIn(); // <-- new method (see below)

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
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🌞 Light theme
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(backgroundColor: Colors.white),
            useMaterial3: true,
            fontFamily: GoogleFonts.karla().fontFamily,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),

          // 🌙 Dark theme
          darkTheme: ThemeData(
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: AppBarTheme(backgroundColor: Colors.black),
            useMaterial3: true,
            fontFamily: GoogleFonts.karla().fontFamily,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          home:
              !widget.hasSeenIntro
                  ? IntroScreen()
                  : _checking
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

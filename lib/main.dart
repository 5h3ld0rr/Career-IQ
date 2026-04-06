import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/core/theme/theme.dart';
import 'package:careeriq/features/auth/providers/auth_provider.dart';
import 'package:careeriq/features/jobs/providers/job_provider.dart';
import 'package:careeriq/features/ai_assistant/providers/ai_provider.dart';
import 'package:careeriq/core/providers/theme_provider.dart';
import 'package:careeriq/features/notifications/providers/notification_provider.dart';
import 'package:careeriq/features/splash/screens/splash_screen.dart';
import 'package:careeriq/features/auth/screens/login_screen.dart';
import 'package:careeriq/features/auth/screens/signup_screen.dart';
import 'package:careeriq/core/shell/main_wrapper.dart';
import 'package:careeriq/features/salary_roi/screens/salary_roi_screen.dart';
import 'package:careeriq/features/salary_roi/providers/salary_provider.dart';
import 'package:careeriq/features/chat/providers/chat_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:careeriq/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:careeriq/features/recruiter/screens/ats_dashboard_screen.dart';
import 'package:careeriq/features/jobs/screens/details/job_details_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
  } catch (e) {
    debugPrint('Google Sign In initialization failed: $e');
  }

  try {
    if (Firebase.apps.isEmpty) {
      debugPrint('Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase Initialized.');
      } catch (e) {
        if (e.toString().contains('duplicate-app')) {
          debugPrint('Firebase already initialized natively.');
        } else {
          rethrow;
        }
      }
    } else {
      debugPrint('Firebase already initialized.');
    }

    debugPrint('Activating App Check...');
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
    debugPrint('App Check Activated.');
  } catch (e) {
    debugPrint('Firebase/AppCheck initialization FAILED: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SalaryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: CareerIQApp(),
    ),
  );
}

class CareerIQApp extends StatelessWidget {
  CareerIQApp({super.key});

  final GlobalKey<MainWrapperState> mainWrapperKey =
      GlobalKey<MainWrapperState>();

  void handleNotificationClick(String? payload) {
    debugPrint("Notification clicked with payload: $payload");
    if (payload == null) return;

    if (payload.startsWith('/ats/')) {
      final jobId = payload.replaceFirst('/ats/', '');
      final context = navigatorKey.currentContext;
      if (context != null) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isRecruiter) {
          mainWrapperKey.currentState?.setSelectedIndex(1);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ATSDashboardScreen(initialJobId: jobId),
                ),
              );
            }
          });
        }
      }
    } else if (payload == '/tracker') {
      mainWrapperKey.currentState?.setSelectedIndex(1);
    } else if (payload.startsWith('/tracker/')) {
      final appId = payload.replaceFirst('/tracker/', '');
      debugPrint("Deep linking to application: $appId");
      mainWrapperKey.currentState?.setSelectedIndex(1);
    } else if (payload.startsWith('/job/')) {
      final jobId = payload.replaceFirst('/job/', '');
      final context = navigatorKey.currentContext;
      if (context != null) {
        Provider.of<JobProvider>(context, listen: false)
            .getJobById(jobId)
            .then((job) {
          if (job != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => JobDetailsScreen(job: job)),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).initializeService((route) {
        if (route != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamed(route);
        }
      });
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'CareerIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/main': (context) => const MainWrapper(),
        '/salary_roi': (context) => const SalaryROIScreen(),
      },
    );
  }
}

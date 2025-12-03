import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'utils/shared_prefs.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/welcome/welcome_carousel.dart';
import 'screens/user_setup/user_setup_carousel.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await SharedPrefs.init();
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',  // You can later convert this to dynamic routing
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/welcomeCarousel': (_) => const WelcomeCarousel(),
        '/userSetupCarousel': (_) => const UserSetupCarousel(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

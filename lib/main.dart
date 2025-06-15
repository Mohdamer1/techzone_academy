import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAPWnVj91vkgjJvMmQ1an6jD0lZRPdT0-E",
        appId: "1:1073198072794:android:6ca1436932f43665ebf6e3",
        messagingSenderId: "1073198072794",
        projectId: "techzone-ef2d1",
        storageBucket: "techzone-ef2d1.appspot.com",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'TechZone Academy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B80EE)),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
} 
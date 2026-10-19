import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_app.dart';
import 'repositories/memory_repository.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_memory_service.dart';
import 'viewmodels/memory_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/add_memory_viewmodel.dart';

// Following MVVM Architecture Pattern
// Firebase backend integrated with Authentication and Firestore
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MemoryBoxApp());
}

class MemoryBoxApp extends StatelessWidget {
  const MemoryBoxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final firebaseAuthService = FirebaseAuthService();
    final firestoreMemoryService = FirestoreMemoryService();
    final memoryRepository = MemoryRepository(
        firestoreMemoryService, firebaseAuthService);

    return MultiProvider(
      providers: [
        // Service providers
        Provider<FirebaseAuthService>.value(value: firebaseAuthService),
        Provider<FirestoreMemoryService>.value(value: firestoreMemoryService),

        // Repository providers
        Provider<MemoryRepository>.value(value: memoryRepository),

        // ViewModel providers
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(firebaseAuthService),
        ),
        ChangeNotifierProxyProvider<MemoryRepository, MemoryViewModel>(
          create: (_) => MemoryViewModel(memoryRepository),
          update: (_, repository, __) => MemoryViewModel(repository),
        ),
        ChangeNotifierProvider<AddMemoryViewModel>(
          create: (_) => AddMemoryViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Memory Box',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // No fontFamily override - allows iOS emojis to render natively
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({Key? key}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  String _currentScreen = 'home'; // 'home', 'auth', 'app'

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: true);
    final memoryViewModel =
        Provider.of<MemoryViewModel>(context, listen: false);

    // Handle authentication state changes
    if (authViewModel.isAuthenticated) {
      // Reinitialize memory repository when user logs in
      if (_currentScreen != 'app') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          memoryViewModel.reinitialize();
          setState(() {
            _currentScreen = 'app';
          });
        });
      }
      // Show MainApp if authenticated
      if (_currentScreen == 'app') {
        return const MainApp();
      }
    } else {
      // Clear memory repository when user logs out
      if (_currentScreen == 'app') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          memoryViewModel.reinitialize();
          setState(() {
            _currentScreen = 'home';
          });
        });
      }
      // Show AuthScreen or HomeScreen if not authenticated
      if (_currentScreen == 'auth') {
        return const AuthScreen();
      }
    }

    switch (_currentScreen) {
      case 'home':
        return HomeScreen(
          onEnter: () {
            setState(() {
              _currentScreen = 'auth';
            });
          },
        );
      case 'auth':
        return const AuthScreen();
      case 'app':
        return const MainApp();
      default:
        return HomeScreen(
          onEnter: () {
            setState(() {
              _currentScreen = 'auth';
            });
          },
        );
    }
  }
}

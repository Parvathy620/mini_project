import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_providers.dart';
import 'core/services/auth_service.dart'; // Still used in _checkSessionRestore
import 'features/common/screens/unified_login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'core/widgets/app_background.dart';
import 'core/widgets/runway_reveal.dart';
import 'core/widgets/luxury_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'features/common/screens/complete_password_reset_screen.dart';

import 'features/service_provider/screens/sp_dashboard_screen.dart';
import 'features/tourist/screens/tourist_dashboard_screen.dart';
import 'features/admin/screens/dashboard_screen.dart';

// ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
    runApp(const MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error initializing app: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getAppProviders(),
      child: MaterialApp(
        title: 'Navika',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20), // Deep Forest Green
            brightness: Brightness.dark,
            primary: const Color(0xFF66BB6A), // Soft Emerald
            secondary: const Color(0xFFE8F5E9), // Light Mint
            surface: const Color(0xFF1B5E20),
          ),
          primaryColor: const Color(0xFF66BB6A),
          scaffoldBackgroundColor: const Color(0xFF051F20), // Deep Jungle Green
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            },
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkSessionRestore();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialUri = await _appLinks.getInitialLink(); // Changed to getInitialLink(), getInitialAppLink is deprecated in v6
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      if (kDebugMode) print('Deep Link Error: $e');
    }

    // Listen for new links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) print('Received Deep Link: $uri');
    
    // Unwrapping Nested Firebase Link 
    // Format: https://host/__/auth/links?link=REAL_ACTION_URL
    Uri targetUri = uri;
    if (uri.queryParameters.containsKey('link')) {
      final innerLink = uri.queryParameters['link'];
      if (innerLink != null) {
        targetUri = Uri.parse(innerLink);
        if (kDebugMode) print('Unwrapped Inner Link: $targetUri');
      }
    }

    // Check for Firebase Auth Action Link params
    final mode = targetUri.queryParameters['mode'];
    final oobCode = targetUri.queryParameters['oobCode'];

    if (mode == 'resetPassword' && oobCode != null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompletePasswordResetScreen(oobCode: oobCode),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkSessionRestore() async {
    // Wait briefly for smooth splash
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    
    if (user != null) {
       // Check last route if user is still valid
       final prefs = await SharedPreferences.getInstance();
       final lastRoute = prefs.getString('last_route') ?? '';
       
       if (mounted && lastRoute.isNotEmpty) {
         Widget? targetScreen;
         if (lastRoute == 'provider') targetScreen = const SPDashboardScreen();
         if (lastRoute == 'tourist') targetScreen = const TouristDashboardScreen();
         if (lastRoute == 'admin') targetScreen = const DashboardScreen();
         
         if (targetScreen != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => targetScreen!),
            );
            return;
         }
       }
    }
  }

  void _handleGetStarted() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Base Premium Background
          const AppBackground(child: SizedBox.expand()),

          // 2. Static Floor Effect (Optional - keeping static gradient for depth)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Static Plane & Globe Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.public,
                        size: 100,
                        color: const Color(0xFF50C878).withOpacity(0.8), // Emerald
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Glass Welcome Card (Animated)
                  RunwayReveal(
                    delayMs: 200,
                    slideUp: true,
                    child: LuxuryGlass(
                      opacity: 0.05,
                      blur: 20,
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          Text(
                            'NAVIKA',
                            style: GoogleFonts.outfit(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Premium Travel Experience',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: 1,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.white.withOpacity(0.5), Colors.transparent],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your journey begins with a single tap.\nExperience the future of travel.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white60,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // "Get Started" Button (Compact)
                  GestureDetector(
                    onTap: _handleGetStarted,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF50C878).withOpacity(0.9), // Emerald
                            const Color(0xFF2E7D32).withOpacity(0.9), // Forest Green
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF50C878).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GET STARTED',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded, 
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

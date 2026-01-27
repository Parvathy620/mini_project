import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/admin_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/data_service.dart';
import 'features/common/screens/unified_login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'core/widgets/app_background.dart';
import 'core/widgets/runway_reveal.dart';
import 'core/widgets/luxury_glass.dart';

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
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DataService>(create: (_) => DataService()),
        Provider<AdminService>(create: (_) => AdminService()),
      ],
      child: MaterialApp(
        title: 'Navika',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF37474F), // Professional Slate
            brightness: Brightness.dark,
            primary: const Color(0xFF64B5F6), // Soft Blue Accent
            secondary: const Color(0xFFCFD8DC), // Light Slate Accent
            surface: const Color(0xFF263238),
          ),
          primaryColor: const Color(0xFF64B5F6),
          scaffoldBackgroundColor: const Color(0xFF102027), // Deep Blue-Grey
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

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _runwayController;
  late Animation<double> _runwayAnimation;
  bool _isTakingOff = false;

  @override
  void initState() {
    super.initState();
    // Continuous runway light movement
    _runwayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _runwayAnimation = Tween<double>(begin: 0, end: 1).animate(_runwayController);
  }

  @override
  void dispose() {
    _runwayController.dispose();
    super.dispose();
  }

  void _handleGetStarted() async {
    setState(() => _isTakingOff = true);
    // Simulate acceleration delay before navigation
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const UnifiedLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
      // Reset state if pop back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isTakingOff = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Base Premium Background
          const AppBackground(child: SizedBox.expand()),

          // 2. Runway Floor Effect (Bottom perspective)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateX(1.2), // Tilt to make it look like a floor
              alignment: Alignment.bottomCenter,
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
                child: Stack(
                  children: [
                    // Moving Runway Lights
                    AnimatedBuilder(
                      animation: _runwayAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: List.generate(5, (index) {
                            return Positioned(
                              top: ((index * 0.2 + _runwayAnimation.value) % 1.0) * 400, // Move down
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 40,
                                  color: Colors.white.withOpacity(
                                    (1 - ((index * 0.2 + _runwayAnimation.value) % 1.0)).clamp(0, 0.5) // Fade as it gets closer/lower
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
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
                  
                  // Animated Plane Icon (The "Hero")
                  AnimatedScale(
                    scale: _isTakingOff ? 5.0 : 1.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInExpo,
                    child: AnimatedOpacity(
                      opacity: _isTakingOff ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 400),
                      child: const RunwayReveal(
                        delayMs: 200,
                        child: Icon(
                          Icons.airplanemode_active_rounded,
                          size: 100,
                          color: Color(0xFF38BDF8), // Sky Blue
                          shadows: [
                            Shadow(color: Color(0xFF38BDF8), blurRadius: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Glass Welcome Card
                  AnimatedOpacity(
                    opacity: _isTakingOff ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: RunwayReveal(
                      delayMs: 600,
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
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // "Get Started" Accelerating Button
                  AnimatedOpacity(
                    opacity: _isTakingOff ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: RunwayReveal(
                      delayMs: 1000,
                      slideUp: true,
                      child: GestureDetector(
                        onTap: _handleGetStarted,
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF38BDF8).withOpacity(0.8),
                                const Color(0xFF6366F1).withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: -5,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: -2,
                                offset: const Offset(0, 2),
                              )
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Button Shine Plane
                              Positioned(
                                top: 0,
                                width: 200,
                                height: 35,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                                  ),
                                ),
                              ),
                              
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'GET STARTED',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded, 
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

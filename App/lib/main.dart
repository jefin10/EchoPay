import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import 'verify_otp_page.dart';
import 'voiceToText/voiceToText.dart';
import 'payToContacts/payToContacts.dart';
import 'payToPhoneNumber/payToPhonenumber.dart';
import 'payToUpiId/payToUpiId.dart';


void main() {
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: _isLoggedIn ? '/biometric' : '/signup',
      routes: {
        '/signup': (context) => const SignupPage(),
        '/verify': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
          return VerifyOtpPage(
            fullName: args?['fullName'] ?? '',
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/biometric': (context) => const BiometricAuthScreen(),
        '/main': (context) => MyHomePage(title: 'UPI Voice App'),
      },
    );
  }
}

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authStatus = 'Use your device\'s biometric authentication (fingerprint, face, etc.)';

  @override
  void initState() {
    super.initState();
    _authenticateWithBiometrics();
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    
    try {
      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Checking biometric availability...';
      });

      // Check if device supports biometric authentication
      final bool isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) {
        setState(() {
          _authStatus = 'Device does not support biometric authentication. Tap to continue.';
          _isAuthenticating = false;
        });
        return;
      }

      // Check if biometric authentication is available
      final bool canUseBiometrics = await auth.canCheckBiometrics;
      if (!canUseBiometrics) {
        setState(() {
          _authStatus = 'Biometric authentication not available. Tap to continue.';
          _isAuthenticating = false;
        });
        return;
      }

      // Get available biometric types
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        setState(() {
          _authStatus = 'No biometric authentication set up. Tap to continue.';
          _isAuthenticating = false;
        });
        return;
      }

      setState(() {
        _authStatus = 'Use your fingerprint sensor or face unlock to continue...';
      });

      // Perform authentication with better error handling
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your UPI Voice App',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (authenticated) {
        setState(() {
          _authStatus = 'Authentication successful!';
        });
        // Save login status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        // Small delay to show success message
        await Future.delayed(const Duration(milliseconds: 500));
        // Navigate to main app
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'UPI Voice App'),
            ),
          );
        }
      } else {
        setState(() {
          _authStatus = 'Authentication cancelled. Try your biometric sensor or continue without auth.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      print('Authentication error: $e'); // Debug print
      setState(() {
        _isAuthenticating = false;
        if (e.toString().contains('no_fragment_activity')) {
          _authStatus = 'App configuration issue. Please restart the app. Tap to continue.';
        } else if (e.toString().contains('NotAvailable') || e.toString().contains('not_available')) {
          _authStatus = 'Biometric authentication not available. Tap to continue.';
        } else if (e.toString().contains('NotEnrolled') || e.toString().contains('not_enrolled')) {
          _authStatus = 'No biometrics enrolled. Please set up fingerprint/face unlock in settings. Tap to continue.';
        } else if (e.toString().contains('PermanentlyLockedOut') || e.toString().contains('permanently_locked_out')) {
          _authStatus = 'Authentication locked. Please try again later. Tap to continue.';
        } else if (e.toString().contains('LockedOut') || e.toString().contains('locked_out')) {
          _authStatus = 'Too many attempts. Please try again later. Tap to continue.';
        } else {
          _authStatus = 'Authentication error. Try your biometric sensor or continue without auth.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon/Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.security,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              
              // App Title
              const Text(
                'UPI Voice App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              
              // Authentication Status
              Text(
                _authStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              
              // Device-specific instructions
              if (!_isAuthenticating && !_authStatus.contains('successful'))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Biometric sensor locations:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Back of device (rear fingerprint)\n• Home button\n• Power button\n• Face camera (front)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              
              // Biometric Icon
              if (_isAuthenticating)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                )
              else
                GestureDetector(
                  onTap: _authenticateWithBiometrics,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 40,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TAP TO\nAUTHENTICATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Manual continue button (always visible for easy access)
              if (!_isAuthenticating)
                Column(
                  children: [
                    if (_authStatus.contains('Tap to continue') || _authStatus.contains('Try your biometric sensor'))
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyHomePage(title: 'UPI Voice App'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Continue Without Authentication'),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyHomePage(title: 'UPI Voice App'),
                          ),
                        );
                      },
                      child: const Text(
                        'Skip Authentication',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isSignedUp', false); // Clear signup status on logout
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpeechScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Go to Voice to Text',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  PayToContactsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Pay to Contacts',
                style: TextStyle(fontSize: 16),
              ),
            ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PayToPhonenumberPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Pay to Phone Number',
                  style: TextStyle(fontSize: 16),
                ),
              ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PayToUpiIdPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Pay to UPI ID',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

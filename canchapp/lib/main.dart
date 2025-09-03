//lib/main.dart
/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/register_type_screen.dart';
import 'screens/register_player_screen.dart'; // Nueva importación
import 'screens/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/register_owner_screen.dart';
import 'providers/theme_provider.dart';
import 'screens/create_field_screen.dart';
import 'screens/fields_list_screen.dart';
import 'screens/field_detail_screen.dart';
import 'screens/client/field_reservation_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/payment_accounts_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CanchApp',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterTypeScreen(),
        '/register-player': (context) => const RegisterPlayerScreen(),
        '/register-owner': (context) => const RegisterOwnerScreen(), // Nueva ruta
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/client-home': (context) => const ClientHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/owner-home': (context) => const OwnerHomeScreen(), //
        '/create_field': (context) => const CreateFieldScreen(),
        '/fields_list': (context) => const FieldsListScreen(),
        '/field_detail': (context) => const FieldDetailScreen(),
        '/field-reservation': (context) => const FieldReservationScreen(),
        '/my-reservations': (context) => const MyReservationsScreen(),
        '/payment-accounts': (context) => const PaymentAccountsScreen(),
      },
    );
  }
}*/

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/register_type_screen.dart';
import 'screens/register_player_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/register_owner_screen.dart';
import 'providers/theme_provider.dart';
import 'screens/create_field_screen.dart';
import 'screens/fields_list_screen.dart';
import 'screens/field_detail_screen.dart';
import 'screens/client/field_reservation_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/payment_accounts_screen.dart';

// ===== Firebase =====
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


// Handler de mensajes en segundo plano (DEBE estar en top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Aquí puedes hacer logging del payload si quieres
  // debugPrint('BG message: ${message.messageId} data: ${message.data}');
}

// Para poder navegar fuera de un BuildContext (p. ej., al tocar notificación)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones generadas por FlutterFire
  await Firebase.initializeApp();

  // Registra el handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    // 1) Solicita permisos (iOS y Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // debugPrint('Permisos FCM: ${settings.authorizationStatus}');

    // 2) Obtén token del dispositivo (envíalo a tu backend)
    _token = await _fcm.getToken();
    // debugPrint('FCM token: $_token');

    print("............$_token");

    // Refresco de token (importante si rota)
    _fcm.onTokenRefresh.listen((t) {
      _token = t;
      // TODO: envía t al backend para mantenerlo actualizado
    });

    // 3) Mensajes en FOREGROUND (no hay banner del sistema)
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final title = msg.notification?.title ?? 'Notificación';
      final body = msg.notification?.body ?? '';

      if (!mounted) return;
      ScaffoldMessenger.of(navigatorKey.currentContext ?? context)
          .showSnackBar(SnackBar(content: Text('$title: $body')));
      // Si quieres navegar por data:
      // final route = msg.data['route']; if (route != null) navigatorKey.currentState?.pushNamed(route);
    });

    // 4) App abierta al TOCAR la notificación (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 5) App iniciada DESDE una notificación (estado terminado)
    final initialMsg = await _fcm.getInitialMessage();
    if (initialMsg != null) {
      _handleNotificationTap(initialMsg);
    }

    // 6) (Opcional) suscripción a topics
    // await _fcm.subscribeToTopic('todos');
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null && route is String && route.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(route);
    } else {
      // Ruta por defecto si no viene 'route'
      navigatorKey.currentState?.pushNamed('/client-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CanchApp',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF059669), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterTypeScreen(),
        '/register-player': (context) => const RegisterPlayerScreen(),
        '/register-owner': (context) => const RegisterOwnerScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/client-home': (context) => const ClientHomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/owner-home': (context) => const OwnerHomeScreen(),
        '/create_field': (context) => const CreateFieldScreen(),
        '/fields_list': (context) => const FieldsListScreen(),
        '/field_detail': (context) => const FieldDetailScreen(),
        '/field-reservation': (context) => const FieldReservationScreen(),
        '/my-reservations': (context) => const MyReservationsScreen(),
        '/payment-accounts': (context) => const PaymentAccountsScreen(),
      },
    );
  }
}

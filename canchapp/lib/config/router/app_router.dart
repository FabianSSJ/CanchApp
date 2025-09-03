import 'package:canchapp/screens/client_home_screen.dart';
import 'package:canchapp/screens/create_field_screen.dart';
import 'package:canchapp/screens/field_detail_screen.dart';
import 'package:canchapp/screens/fields_list_screen.dart';
import 'package:canchapp/screens/forgot_password_screen.dart';
import 'package:canchapp/screens/login_screen.dart';
import 'package:canchapp/screens/owner_home_screen.dart';
import 'package:canchapp/screens/profile_screen.dart';
import 'package:canchapp/screens/register_owner_screen.dart';
import 'package:canchapp/screens/register_player_screen.dart';
import 'package:canchapp/screens/register_screen.dart';
import 'package:canchapp/screens/register_type_screen.dart' hide RegisterTypeScreen;
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      // builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/register-type',
      builder: (context, state) => const RegisterTypeScreen(),
    ),
    GoRoute(
      path: '/register-player',
      builder: (context, state) => const RegisterPlayerScreen(),
    ),
    GoRoute(
      path: '/register-owner',
      builder: (context, state) => const RegisterOwnerScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/client-home',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/owner-home',
      builder: (context, state) {
        final userData = state.extra as Map<String, dynamic>?;
       // return OwnerHomeScreen(userData: userData);
      },
    ),
    GoRoute(
      path: '/fields-list',
      builder: (context, state) => const FieldsListScreen(),
    ),
    GoRoute(
      path: '/field-detail/:id',
      builder: (context, state) {
        return const FieldDetailScreen();
      },
    ),
    GoRoute(
      path: '/create-field',
      redirect: (context, state) { // NEW: Redirección si no hay sesión
        if (state.extra == null) {
          return '/login';
        }
        return null;
      },
      builder: (context, state) {
        final userData = state.extra as Map<String, dynamic>?;
        //return CreateFieldScreen(userData: userData);
      },
    ),
    GoRoute(
      path: '/profile',
      redirect: (context, state) { // NEW: Redirección si no hay sesión
        if (state.extra == null) {
          return '/login';
        }
        return null;
      },
      builder: (context, state) {
        final userData = state.extra as Map<String, dynamic>?;
        //return ProfileScreen(userData: userData); // UPDATED: Pasa userData
      },
    ),
  ],
);
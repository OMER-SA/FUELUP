import 'dart:developer' as developer;
import 'package:diet_app/components/bottom_navigation_bar.dart';
import 'package:diet_app/components/kitchen_layout.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/screens/authentication/auth.dart';
import 'package:diet_app/screens/authentication/forgot_password.dart';
import 'package:diet_app/screens/authentication/login.dart';
import 'package:diet_app/screens/authentication/signup.dart';
import 'package:diet_app/screens/customer/cart/cart.dart';
import 'package:diet_app/screens/customer/cart/checkout.dart';
import 'package:diet_app/screens/customer/home/home_page.dart';
import 'package:diet_app/screens/customer/home/meal_detail.dart';
import 'package:diet_app/screens/customer/order_screen.dart';
import 'package:diet_app/screens/customer/profile/bmi_history_screen.dart';
import 'package:diet_app/screens/customer/profile/calorie_calculator_screen.dart';
import 'package:diet_app/screens/customer/profile/dietary_preferences_screen.dart';
import 'package:diet_app/screens/customer/profile/goal_setting_screen.dart';
import 'package:diet_app/screens/customer/profile/update_address.dart';
import 'package:diet_app/screens/customer/profile/update_alergies.dart';
import 'package:diet_app/screens/customer/profile/update_email.dart';
import 'package:diet_app/screens/customer/profile/update_name.dart';
import 'package:diet_app/screens/customer/profile/update_phone.dart';
import 'package:diet_app/screens/customer/profile/update_physical_indormation.dart';
import 'package:diet_app/screens/kitchen/kitchenHome/edit_meal.dart';
import 'package:diet_app/screens/kitchen/kitchen_orders_screen.dart';
import 'package:diet_app/screens/kitchen/kitchen_profile/kitchen_update_address.dart';
import 'package:diet_app/screens/kitchen/kitchen_profile/kitchen_update_name.dart';
import 'package:diet_app/screens/kitchen/kitchen_add_meal.dart';
import 'package:diet_app/screens/kitchen/kitchenHome/kitchen_home.dart';
import 'package:diet_app/screens/kitchen/kitchen_profile/kitchen_profile.dart';
import 'package:diet_app/screens/customer/profile/profile_page.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/screens/kitchen/kitchen_profile/kitchen_update_phone.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  // Router configuration for the app.

  getRouterConfig(UserIdProvider userProvider) {
    return GoRouter(
      initialLocation: '/auth/login',
      refreshListenable: userProvider,
      redirect: (context, state) {
        // DO NOT add custom auto-login logic.
        // DO NOT restore session from local storage.
        // FirebaseAuth is the only source of truth.
        final location = state.matchedLocation;
        final currentUser = FirebaseAuth.instance.currentUser;
        final isAuthentic = currentUser != null;

        // DEFINITIVE EARLY EXIT — runs on EVERY router evaluation, before any
        // other logic. Prevents the infinite loop caused by userProvider
        // calling notifyListeners() during data loading: each call re-triggers
        // GoRouter's redirect, and state.matchedLocation can momentarily report
        // a stale value. Once the user is on the right route, we stop all
        // further redirect work immediately.
        //
        // Use isAuthentic (FirebaseAuth) not userProvider.getUuid here —
        // getUuid may still be null while Firebase auth is already confirmed,
        // which would cause the guard to fail and fall through to the loop.
        final role = userProvider.getRole;

        if (isAuthentic && role == 'customer') {
          if (location.startsWith('/home') ||
              location.startsWith('/profile') ||
              location.startsWith('/cart') ||
              location.startsWith('/orders')) {
            developer.log('🧭 ROUTER_NO_REDIRECT: location=$location');
            return null;
          }
        }
        if (isAuthentic && role == 'cheff' && location.startsWith('/kitchen')) {
          developer.log('🧭 ROUTER_NO_REDIRECT: location=$location');
          return null;
        }

        final isForgotPasswordRoute = location == '/auth/forgotPassword';
        final isLoginRoute = location == '/auth/login';
        final isAuthRoute = isLoginRoute ||
            location == '/auth/signUp' ||
            location == '/auth/forgotPassword';

        developer.log('AUTH_CHECK_START: location=$location');
        if (currentUser != null) {
          developer.log('AUTH_USER_FOUND: uid=${currentUser.uid}');
        } else {
          developer.log('AUTH_NO_USER');
        }
        developer.log('🧭 ROUTER_REDIRECT: location=$location, isAuthentic=$isAuthentic');

        // Keep forgot-password flow in auth even if a stale session exists.
        if (isForgotPasswordRoute) {
          developer.log('🧭 ROUTER_FORGOT_PASSWORD_FLOW');
          return null;
        }

        if (userProvider.isLoggingOut) {
          developer.log('🧭 ROUTER_LOGOUT_IN_PROGRESS_SKIP_AUTOLOGIN');
          developer.log('ROUTER_REDIRECT_LOGIN');
          return '/auth/login';
        }

        if (isAuthentic && isLoginRoute) {
          if (role == null) return null; // wait for role to load
          final destination = role == 'cheff' ? '/kitchen/home' : '/home';
          developer.log('🧭 ROUTER_AUTH_ROUTE_REDIRECT: from=$location, role=$role, to=$destination');
          return destination;
        }

        if (!isAuthentic) {
          if (!isAuthRoute) {
            developer.log('ROUTER_REDIRECT_LOGIN');
            developer.log('🧭 ROUTER_UNAUTHENTICATED_REDIRECT: from=$location, to=/auth/login');
            return '/auth/login';
          }
          if (isLoginRoute) {
            developer.log('ROUTER_REDIRECT_LOGIN');
          }
          developer.log('🧭 ROUTER_NO_REDIRECT: location=$location');
          return null;
        }

        if (isAuthRoute && isAuthentic) {
          if (role == null) return null; // wait for role to load
          final destination = role == 'cheff' ? '/kitchen/home' : '/home';
          developer.log('🧭 ROUTER_AUTH_ROUTE_REDIRECT: from=$location, role=$role, to=$destination');
          return destination;
        }

        // Prevent role cross-contamination: redirect chefs away from customer
        // routes and customers away from kitchen routes.
        if (isAuthentic) {
          if (role == null) return null; // don't guard until role is known
          final isKitchenRoute = location.startsWith('/kitchen');
          final isCustomerRoute = !isKitchenRoute && !isAuthRoute;
          if (role == 'cheff' && isCustomerRoute) {
            developer.log('🧭 ROUTER_ROLE_GUARD: chef blocked from $location → /kitchen/home');
            return '/kitchen/home';
          }
          if (role != 'cheff' && isKitchenRoute) {
            developer.log('🧭 ROUTER_ROLE_GUARD: customer blocked from $location → /home');
            return '/home';
          }
        }

        developer.log('🧭 ROUTER_NO_REDIRECT: location=$location');
        return null;
      },
      routes: <RouteBase>[
        ShellRoute(
          builder: (context, state, child) =>
              AuthenticationScreen(child: child),
          routes: [
            GoRoute(
                path: '/auth/login',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: LoginScreen()),
                routes: []),
            GoRoute(
              path: '/auth/signUp',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: SignUpScreen()),
            ),
            GoRoute(
              path: '/auth/forgotPassword',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: ForgotPasswordScreen()),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) =>
              BottomNavigationBarPage(state: state, child: child),
          routes: [
            GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'meal-detail',
                    pageBuilder: (context, state) => MaterialPage(
                        child: MealDetailScreen(
                      meal: state.extra as Map<String, dynamic>,
                    )),
                  ),
                ]),
            GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'updateName',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: UpdateNameScreen()),
                  ),
                  GoRoute(
                    path: 'updateEmail',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: UpdateEmailScreen()),
                  ),
                  GoRoute(
                    path: 'updatePhone',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: UpdatePhoneScreen()),
                  ),
                  GoRoute(
                    path: 'updateAddress',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: UpdateAddress()),
                  ),
                  GoRoute(
                    path: 'updatePhysicalInformation',
                    pageBuilder: (context, state) => MaterialPage(
                        child: UpdatePhysicalIndormationScren(
                      age: context.read<CustomerProvider>().getAge ?? 0,
                      height: context.read<CustomerProvider>().getHeight ?? 0.0,
                      weight: context.read<CustomerProvider>().getWeight ?? 0,
                    )),
                  ),
                  GoRoute(
                    path: 'updateAlergies',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: UpdateAlergiesScreen()),
                  ),
                  GoRoute(
                    path: 'bmiHistory',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: BmiHistoryScreen()),
                  ),
                  GoRoute(
                    path: 'goalSetting',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: GoalSettingScreen()),
                  ),
                  GoRoute(
                    path: 'calorieCalculator',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: CalorieCalculatorScreen()),
                  ),
                  GoRoute(
                    path: 'dietaryPreferences',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: DietaryPreferencesScreen()),
                  ),
                ]),
            GoRoute(
              path: '/orders',
              pageBuilder: (context, state) =>
                  const MaterialPage(child: OrderScreen()),
            ),
            GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: CheckoutScreen()),
                  )
                ]),
          ],
        ),

        //============= Kitchen Routes ==================
        ShellRoute(
            pageBuilder: (context, state, child) => MaterialPage(
                  child: KitchenLayout(
                    state: state,
                    child: child,
                  ),
                ),
            routes: [
              GoRoute(
                  path: "/kitchen/home",
                  pageBuilder: (context, state) =>
                      const MaterialPage(child: KitchenHomeScreen()),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      pageBuilder: (context, state) => MaterialPage(
                          child: EditMealScreen(
                        meal: state.extra as Map<String, dynamic>,
                      )),
                    )
                  ]),
              GoRoute(
                path: "/kitchen/addMeal",
                pageBuilder: (context, state) =>
                    const MaterialPage(child: KitchenAddMealScreen()),
              ),
              GoRoute(
                path: "/kitchen/orders",
                pageBuilder: (context, state) =>
                    const MaterialPage(child: KitchenOrdersScreen()),
              ),
              GoRoute(
                path: "/kitchen/profile",
                pageBuilder: (context, state) =>
                    const MaterialPage(child: KitchenProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'updateName',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: KitchenUpdateNameScreen()),
                  ),
                  GoRoute(
                    path: 'updateAddress',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: KitchenUpdateAddress()),
                  ),
                  GoRoute(
                    path: 'updatePhone',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: KitchenUpdatePhoneScreen()),
                  ),
                ],
              ),
            ])
      ],
    );
  }
}

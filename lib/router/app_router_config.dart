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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  getRouterConfig(UserIdProvider userProvider) {
    return GoRouter(
      initialLocation: '/auth/login',
      refreshListenable: userProvider,
      redirect: (context, state) async {
        final isAuthentic = userProvider.uid != null;
        final isAuthRoute = state.matchedLocation == '/auth/login' ||
            state.matchedLocation == '/auth/signUp' ||
            state.matchedLocation == '/auth/forgotPassword';

        if (!isAuthentic) {
          final autoLoginSuccessful = await userProvider.tryAutoLogin();
          if (autoLoginSuccessful) {
            print("autoLoginSuccessful: $autoLoginSuccessful");
            return userProvider.getRole == 'cheff' ? '/kitchen/home' : '/home';
          }
        }

        if (isAuthRoute && isAuthentic) {
          return userProvider.getRole == 'cheff' ? '/kitchen/home' : '/home';
        }

        if (!isAuthentic && !isAuthRoute) {
          return '/auth/login';
        }

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
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
        //============= Kitchen Routes ==================
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

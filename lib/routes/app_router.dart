import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/models/report.dart';
import 'package:invoice_pro/providers/auth_provider.dart';
import 'package:invoice_pro/providers/onboarding_provider.dart';
import 'package:invoice_pro/routes/app_routes.dart';
import 'package:invoice_pro/routes/auth_redirect.dart';
import 'package:invoice_pro/screens/auth/email_verification_screen.dart';
import 'package:invoice_pro/screens/auth/forgot_password_screen.dart';
import 'package:invoice_pro/screens/auth/login_screen.dart';
import 'package:invoice_pro/screens/auth/register_screen.dart';
import 'package:invoice_pro/screens/customers/customer_detail_screen.dart';
import 'package:invoice_pro/screens/customers/customer_form_screen.dart';
import 'package:invoice_pro/screens/customers/customers_screen.dart';
import 'package:invoice_pro/screens/dashboard/dashboard_screen.dart';
import 'package:invoice_pro/screens/error/not_found_screen.dart';
import 'package:invoice_pro/screens/expenses/expense_detail_screen.dart';
import 'package:invoice_pro/screens/expenses/expense_form_screen.dart';
import 'package:invoice_pro/screens/expenses/expenses_screen.dart';
import 'package:invoice_pro/screens/invoices/invoice_detail_screen.dart';
import 'package:invoice_pro/screens/invoices/invoice_form_screen.dart';
import 'package:invoice_pro/screens/invoices/invoice_pdf_preview_screen.dart';
import 'package:invoice_pro/screens/invoices/invoices_screen.dart';
import 'package:invoice_pro/screens/invoices/payment_form_screen.dart';
import 'package:invoice_pro/screens/notifications/notifications_screen.dart';
import 'package:invoice_pro/screens/onboarding/onboarding_screen.dart';
import 'package:invoice_pro/screens/products/product_detail_screen.dart';
import 'package:invoice_pro/screens/products/product_form_screen.dart';
import 'package:invoice_pro/screens/products/products_screen.dart';
import 'package:invoice_pro/screens/profile/business_profile_screen.dart';
import 'package:invoice_pro/screens/profile/profile_screen.dart';
import 'package:invoice_pro/screens/reports/report_detail_screen.dart';
import 'package:invoice_pro/screens/reports/report_pdf_preview_screen.dart';
import 'package:invoice_pro/screens/reports/reports_screen.dart';
import 'package:invoice_pro/screens/shell/app_shell.dart';
import 'package:invoice_pro/screens/splash/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create({
    required OnboardingProvider onboardingProvider,
    required AuthProvider authProvider,
    String initialLocation = AppRoutes.splash,
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      refreshListenable: Listenable.merge([onboardingProvider, authProvider]),
      redirect: (context, state) {
        return AuthRedirect.resolve(
          location: state.matchedLocation,
          onboardingCompleted: onboardingProvider.isCompleted,
          authStatus: authProvider.status,
        );
      },
      errorBuilder: (context, state) => const NotFoundScreen(),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => const EmailVerificationScreen(),
        ),
        GoRoute(
          path: AppRoutes.businessProfile,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const BusinessProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ExpensesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const ExpenseFormScreen(),
            ),
            GoRoute(
              path: ':expenseId',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => ExpenseDetailScreen(
                expenseId: state.pathParameters['expenseId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => ExpenseFormScreen(
                    expenseId: state.pathParameters['expenseId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.reports,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ReportsScreen(),
          routes: [
            GoRoute(
              path: ':kind',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final kind = ReportKindX.fromPath(state.pathParameters['kind']);
                if (kind == null) return const NotFoundScreen();
                return ReportDetailScreen(kind: kind);
              },
              routes: [
                GoRoute(
                  path: 'pdf',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra;
                    return ReportPdfPreviewScreen(
                      args: extra is ReportPdfArgs ? extra : null,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.dashboard,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: DashboardScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.invoices,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: InvoicesScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => InvoiceFormScreen(
                        customerId: state.uri.queryParameters['customerId'],
                      ),
                    ),
                    GoRoute(
                      path: ':invoiceId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => InvoiceDetailScreen(
                        invoiceId: state.pathParameters['invoiceId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => InvoiceFormScreen(
                            invoiceId: state.pathParameters['invoiceId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'pdf',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => InvoicePdfPreviewScreen(
                            invoiceId: state.pathParameters['invoiceId']!,
                          ),
                        ),
                        GoRoute(
                          path: 'pay',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => PaymentFormScreen(
                            invoiceId: state.pathParameters['invoiceId']!,
                            settleInFull: state.uri.queryParameters['full'] == '1',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.customers,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: CustomersScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const CustomerFormScreen(),
                    ),
                    GoRoute(
                      path: ':customerId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => CustomerDetailScreen(
                        customerId: state.pathParameters['customerId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => CustomerFormScreen(
                            customerId: state.pathParameters['customerId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.products,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: ProductsScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const ProductFormScreen(),
                    ),
                    GoRoute(
                      path: ':productId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => ProductDetailScreen(
                        productId: state.pathParameters['productId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) => ProductFormScreen(
                            productId: state.pathParameters['productId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  pageBuilder: (context, state) => const NoTransitionPage<void>(
                    child: ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

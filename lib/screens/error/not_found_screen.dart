import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_pro/core/constants/app_strings.dart';
import 'package:invoice_pro/core/widgets/app_states.dart';
import 'package:invoice_pro/routes/app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: AppErrorState(
        title: AppStrings.pageNotFound,
        onRetry: () => context.go(AppRoutes.dashboard),
      ),
    );
  }
}

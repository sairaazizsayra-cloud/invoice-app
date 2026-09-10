import 'package:flutter/material.dart';
import 'package:invoice_pro/core/utils/responsive.dart';

class AppPaddedBody extends StatelessWidget {
  const AppPaddedBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

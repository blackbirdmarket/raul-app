import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'app_button.dart';

/// Estado vacio o de error, con una accion opcional.
///
/// Una pantalla sin datos nunca deberia quedar en blanco: el usuario no
/// distingue "no hay nada" de "se rompio algo". Este widget siempre explica
/// cual de los dos es.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppConstants.spaceLg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text(
              title,
              style: texts.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppConstants.spaceSm),
              Text(
                message!,
                style: texts.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppConstants.spaceLg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

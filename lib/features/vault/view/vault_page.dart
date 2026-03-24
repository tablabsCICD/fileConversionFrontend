import 'package:flutter/material.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Private Vault")),
      body: Center(
        child: Text("🔐 Vault Unlocked", style: theme.textTheme.titleLarge),
      ),
    );
  }
}

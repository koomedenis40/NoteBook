import 'package:flutter/material.dart';
import 'package:mynotes/views/notes/private_view.dart';

Future<bool> showSetPasswordDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final emailController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Recovery Email for Private Notes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Recovery Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await privateManager.setPassword('', '', emailController.text); // Password fields ignored
                debugPrint('Set recovery email dialog result: $success');
                Navigator.of(context).pop(success);
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> showVerifyPasswordDialog(BuildContext context, PrivateNotesManager privateManager, {String title = 'Enter Password'}) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Enter Password'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final recoveryMessage = await privateManager.recoverPassword();
                if (context.mounted) {
                  Navigator.of(context).pop(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(recoveryMessage)),
                  );
                }
              },
              child: const Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final isValid = await privateManager.verifyPassword(passwordController.text);
                debugPrint('Verify password dialog result: $isValid');
                Navigator.of(context).pop(isValid);
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ) ??
      false;
}
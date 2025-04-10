import 'package:flutter/material.dart';
import 'package:mynotes/views/notes/private_view.dart';

Future<bool> showSetPasswordDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final emailController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Set Private Notes Password'),
          contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: emailController,
                  obscureText: false,
                  decoration: const InputDecoration(labelText: 'Email to Send Reset Link'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () async {
                    final success = await privateManager.setPassword(
                      passwordController.text,
                      confirmController.text,
                      emailController.text,
                    );
                    Navigator.of(dialogContext).pop(success);
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> showLockNoteDialog(BuildContext context, PrivateNotesManager privateManager, bool isPrivate) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Builder(
          builder: (innerContext) => AlertDialog(
            title: const Text('Lock Note'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Enter Your Password'),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        final recoveryMessage = await privateManager.recoverPassword(); // No context needed
                        if (innerContext.mounted) {
                          Navigator.of(innerContext).pop(false);
                          ScaffoldMessenger.of(innerContext).showSnackBar(
                            SnackBar(content: Text(recoveryMessage)),
                          );
                        }
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(innerContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final isValid = await privateManager.verifyPassword(passwordController.text);
                          debugPrint('Lock note dialog result: $isValid');
                          Navigator.of(innerContext).pop(isValid);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> showPrivateNotesPasswordDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Builder(
          builder: (innerContext) => AlertDialog(
            title: const Text('Enter Your Password'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Enter Your Password'),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        final recoveryMessage = await privateManager.recoverPassword(); // No context needed
                        if (innerContext.mounted) {
                          Navigator.of(innerContext).pop(false);
                          ScaffoldMessenger.of(innerContext).showSnackBar(
                            SnackBar(content: Text(recoveryMessage)),
                          );
                        }
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(innerContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final isValid = await privateManager.verifyPassword(passwordController.text);
                          debugPrint('Private notes password dialog result: $isValid');
                          Navigator.of(innerContext).pop(isValid);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<bool> showUnlockNoteDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Builder(
          builder: (innerContext) => AlertDialog(
            title: const Text('Unlock Note'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Enter Your Password'),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        final recoveryMessage = await privateManager.recoverPassword(); // No context needed
                        if (innerContext.mounted) {
                          Navigator.of(innerContext).pop(false);
                          ScaffoldMessenger.of(innerContext).showSnackBar(
                            SnackBar(content: Text(recoveryMessage)),
                          );
                        }
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(innerContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          final isValid = await privateManager.verifyPassword(passwordController.text);
                          debugPrint('Unlock note dialog result: $isValid');
                          Navigator.of(innerContext).pop(isValid);
                        },
                        child: const Text('Unlock'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}
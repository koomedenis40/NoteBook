import 'package:flutter/material.dart';
import 'package:mynotes/views/notes/private_view.dart';

Future<bool> showSetPasswordDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final emailController = TextEditingController();

return await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Set Private Notes Password'),
    contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 0), // Reduced top padding from 18 to 8
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8), // Slight indent for Password
          child: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8), // Slight indent for Confirm Password
          child: TextField(
            controller: confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8), // Slight indent for Confirm Password
          child: TextField(
            controller: emailController,
            obscureText: false,
            decoration: const InputDecoration(labelText: 'Email to Send Reset Link'),
          ),
        ),
        const SizedBox(height: 16), // Kept vertical gap between TextField and buttons
      ],
    ),
    actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    actions: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end, // Aligns buttons to the right
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 4), // Controlled horizontal gap between Cancel and Set
          TextButton(
            onPressed: () async {
              final success = await privateManager.setPassword(
                passwordController.text,
                confirmController.text,
                emailController.text,
              );
              Navigator.of(context).pop(success);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    ],
  ),
) ?? false;
}

Future<bool> showLockNoteDialog(BuildContext context, PrivateNotesManager privateManager, bool isPrivate) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lock Note'), // Always "Lock Note" for note card
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
                      final recoveryMessage = await privateManager.recoverPassword(context);
                      if (context.mounted) {
                        Navigator.of(context).pop(false);
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final isValid = await privateManager.verifyPassword(passwordController.text);
                        debugPrint('Lock note dialog result: $isValid');
                        Navigator.of(context).pop(isValid);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> showPrivateNotesPasswordDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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
                      final recoveryMessage = await privateManager.recoverPassword(context);
                      if (context.mounted) {
                        Navigator.of(context).pop(false);
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final isValid = await privateManager.verifyPassword(passwordController.text);
                        debugPrint('Private notes password dialog result: $isValid');
                        Navigator.of(context).pop(isValid);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> showUnlockNoteDialog(BuildContext context, PrivateNotesManager privateManager) async {
  final passwordController = TextEditingController();

  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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
                      final recoveryMessage = await privateManager.recoverPassword(context);
                      if (context.mounted) {
                        Navigator.of(context).pop(false);
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final isValid = await privateManager.verifyPassword(passwordController.text);
                        debugPrint('Unlock note dialog result: $isValid');
                        Navigator.of(context).pop(isValid);
                      },
                      child: const Text('Unlock'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ) ??
      false;
}
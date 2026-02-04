import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/features/auth/data/auth_service.dart';

class OtpVerificationScreen extends HookConsumerWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final authService = ref.watch(authServiceProvider);

    void handleVerify() async {
      if (codeController.text.length < 6) {
        errorMessage.value = 'Veuillez entrer le code à 6 chiffres';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await authService.verifyCode(email, codeController.text);
        if (context.mounted) {
          context.go(AppRouter.home);
        }
      } catch (e) {
        errorMessage.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Code de vérification',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Un code a été envoyé à :\n$email',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code à 6 chiffres',
                errorText: errorMessage.value,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              maxLength: 6,
              onSubmitted: (_) => handleVerify(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading.value ? null : handleVerify,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('Vérifier'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      try {
                        await authService.login(email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nouveau code envoyé'),
                            ),
                          );
                        }
                      } catch (e) {
                        errorMessage.value = e.toString();
                      }
                    },
              child: const Text('Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NovadisApp());

    // Vérifie que l'application démarre sans erreur
    // On devrait voir l'écran de login par défaut ou au moins le titre de l'app si on cherchait dans le MaterialApp
    // Pour l'instant, on vérifie juste que le widget se construit.
    expect(find.byType(NovadisApp), findsOneWidget);
  });
}

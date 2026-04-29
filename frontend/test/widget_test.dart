import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:novadis_cri/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Inject mock environment variables for tests
    dotenv.testLoad(fileInput: '''
API_URL=http://test-api.example.com/api
''');

    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: NovadisApp()));
    await tester.pumpAndSettle();

    // Vérifie que l'application démarre sans erreur
    expect(find.byType(NovadisApp), findsOneWidget);
  });
}

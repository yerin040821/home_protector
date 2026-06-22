import 'package:flutter_test/flutter_test.dart';
import 'package:home_protector/main.dart';
import 'package:provider/provider.dart';
import 'package:home_protector/providers/app_provider.dart';

void main() {
  testWidgets('HomeProtector app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const HomeProtectorApp(),
      ),
    );
    expect(find.text('HomeProtector'), findsWidgets);
  });
}

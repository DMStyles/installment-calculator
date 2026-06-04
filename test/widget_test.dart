import 'package:flutter_test/flutter_test.dart';
import 'package:installment_calculator/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InstallmentApp());

    // Verify that the title is present
    expect(find.text('Calculator'), findsOneWidget);
  });
}

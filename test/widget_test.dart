import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets('VoiceReaderApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VoiceReaderApp());

    // Verify that Create account screen is displayed.
    expect(find.text('Create account'), findsOneWidget);
  });
}

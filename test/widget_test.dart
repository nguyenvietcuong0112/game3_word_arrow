import 'package:flutter_test/flutter_test.dart';
import 'package:words_arrow_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WordsArrowApp());
  });
}

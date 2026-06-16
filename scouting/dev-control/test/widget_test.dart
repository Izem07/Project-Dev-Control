import 'package:flutter_test/flutter_test.dart';
import 'package:scoutops_admin_menu/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ScoutOpsAdminApp());
    expect(find.text('SCOUTOPS'), findsOneWidget);
  });
}

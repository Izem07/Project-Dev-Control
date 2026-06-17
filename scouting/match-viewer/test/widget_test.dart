import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/app.dart';
import 'package:match_record/data/data_store.dart';
import 'package:match_record/data/json_persistence.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    final dataStore = DataStore(JsonPersistence(directoryPath: '/tmp'));
    await tester.pumpWidget(MatchRecordApp(dataStore: dataStore));
    expect(find.byType(MatchRecordApp), findsOneWidget);
  });
}

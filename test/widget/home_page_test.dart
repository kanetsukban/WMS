import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wms/providers/counter_provider.dart';
import 'package:wms/screens/home/home_page.dart';

void main() {
  testWidgets('HomePage shows counter and increments', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CounterProvider(),
        child: MaterialApp(home: HomePage()),
      ),
    );

    // เริ่มต้น counter = 0
    expect(find.text('0'), findsOneWidget);

    // กดปุ่ม Increment
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // ค่า counter เปลี่ยนเป็น 1
    expect(find.text('1'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
//import 'package:wms/main.dart'; // แก้เป็นชื่อจริงของ project
import 'package:flutter/material.dart';
import 'package:wms/app.dart';   // ✅ ชี้ไปที่ app.dart ของคุณ

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Login → Home → Profile → Logout flow", (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // --- Login ---
    expect(find.text("Login"), findsOneWidget);
    await tester.tap(find.text("Login"));
    await tester.pumpAndSettle();

    // --- Home Page ---
    expect(find.text("Home Page"), findsOneWidget);

    // --- ไป Profile ---
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text("Profile"), findsOneWidget);

    // --- Logout ---
    await tester.tap(find.text("Logout"));
    await tester.pumpAndSettle();

    // --- กลับ Login ---
    expect(find.text("Login"), findsOneWidget);
  });
}

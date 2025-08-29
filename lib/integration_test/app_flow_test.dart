import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:wms/app.dart';
import 'package:wms/models/user.dart';
import 'package:wms/services/api_service.dart';
import 'package:wms/providers/auth_provider.dart';

class _MockApi extends Mock implements ApiService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login → Home(username) → Profile → Logout → back to Login', (tester) async {
    final api = _MockApi();

    // mock login/me/logout — ต้องส่ง firstName/lastName ตาม model ใหม่
    when(() => api.login('admin', '1234')).thenAnswer(
      (_) async => User(
        username: 'admin',
        firstName: '',
        lastName: '',
        email: 'admin@mc-hunter.com',
        token: 'tok',
      ),
    );

    when(() => api.getMeWithBearer('tok')).thenAnswer(
      (_) async => User(
        username: 'admin',
        firstName: '',
        lastName: '',
        email: 'admin@mc-hunter.com',
        token: 'tok',
      ),
    );

    when(() => api.logout('tok')).thenAnswer((_) async => Future.value());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(api: api),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle(); // Splash -> Login

    expect(find.text('Login'), findsOneWidget);

    // ถ้าหน้า Login ต้องกรอกเอง ให้ uncomment 2 บรรทัดนี้
    // await tester.enterText(find.byType(TextField).at(0), 'admin');
    // await tester.enterText(find.byType(TextField).at(1), '1234');

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Home
    expect(find.text('Home Page'), findsOneWidget);
    expect(find.text('admin'), findsWidgets); // ชื่อมุมขวาบน

    // ไป Profile
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.textContaining('Username: admin'), findsOneWidget);

    // Logout (กดปุ่มแล้วยืนยันใน dialog)
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout')); // ปุ่มใน dialog
    await tester.pumpAndSettle();

    // กลับ Login
    expect(find.text('Login'), findsOneWidget);
  });
}

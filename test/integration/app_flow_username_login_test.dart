import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:wms/app.dart';
import 'package:wms/models/user.dart';
import 'package:wms/providers/auth_provider.dart';
import 'package:wms/services/api_service.dart';

class _MockApi extends Mock implements ApiService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login (username) → Home → Profile (refresh) → Logout → back to Login',
      (tester) async {
    // --- Arrange
    final api = _MockApi();

    // ผู้ใช้สมมุติ
    const fakeUsername = 'admin';
    const fakeEmail = 'admin@mc-hunter.com';
    const fakeToken = 'tok';

    final fakeUser = User(
      username: fakeUsername,
      firstName: '',
      lastName: '',
      email: fakeEmail,
      token: fakeToken,
    );

    // 1) สร้าง AuthProvider ที่ใช้ API mock
    final auth = AuthProvider(api: api);

    // 2) Stub พฤติกรรมของ API:
    // - login ด้วย username เท่านั้น
    when(() => api.loginWithCredentials(
          username: fakeUsername,
          email: any(named: 'email'),
          password: '1234',
        )).thenAnswer((_) async => fakeUser);

    // - Profile refresh (เรียกเมื่อเข้า Profile)
    when(() => api.getUser(tokenHint: fakeToken)).thenAnswer((_) async => fakeUser);

    // - Logout
    when(() => api.logout()).thenAnswer((_) async {});

    // --- Act: เปิดแอป
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MyApp(),
      ),
    );

    // Splash → Login
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);

    // กรอก Username + Password
    // ช่องแรก: Username
    await tester.enterText(find.byType(TextField).at(0), fakeUsername);
    // ช่องสอง: Password
    await tester.enterText(find.byType(TextField).at(1), '1234');

    // กด Login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // --- Assert: เข้าหน้า Home (title "Main" จาก BottomNav index 0) และมีชื่อผู้ใช้มุมขวาบน
    expect(find.text('Main'), findsOneWidget);
    expect(find.text(fakeUsername), findsWidgets); // แสดงที่ AppBar actions

    // ไปหน้า Profile (ไอคอนรูปคนมุมขวาบน)
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    // อยู่หน้า Profile
    expect(find.text('Profile'), findsOneWidget);

    // มีข้อมูลผู้ใช้ (อย่างน้อย username/email โผล่)
    expect(find.text(fakeUsername), findsWidgets);
    expect(find.text(fakeEmail), findsWidgets);

    // กด Logout (จะมี dialog ยืนยัน)
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    // กดยืนยัน Logout ใน dialog
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Logout')); // ปุ่มยืนยันใน dialog
    await tester.pumpAndSettle();

    // กลับหน้า Login
    expect(find.text('Login'), findsOneWidget);

    // --- Verify: ตรวจว่าถูกเรียกตาม flow
    verify(() => api.loginWithCredentials(
          username: fakeUsername,
          email: any(named: 'email'),
          password: '1234',
        )).called(1);
    verify(() => api.getUser(tokenHint: fakeToken)).called(greaterThanOrEqualTo(1));
    verify(() => api.logout()).called(1);
  });
}

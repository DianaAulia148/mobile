import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import main.dart yang benar
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Aplikasi berhasil membuka RegisterPage',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GymApp());
    await tester.pumpAndSettle();

    // Pastikan MaterialApp muncul
    expect(find.byType(MaterialApp), findsOneWidget);

    // Karena initialRoute = /register
    expect(find.text("Buat Akun Baru"), findsOneWidget);

    // Pastikan field-text tersedia
    expect(find.widgetWithText(TextField, "Nama Lengkap"), findsOneWidget);
    expect(find.widgetWithText(TextField, "Email"), findsOneWidget);
    expect(find.widgetWithText(TextField, "Password"), findsOneWidget);

    // Pastikan tombol daftar tersedia
    expect(find.text("Daftar Sekarang"), findsOneWidget);
  });
}

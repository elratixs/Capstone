import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellq_app/core/api_client.dart';
import 'package:wellq_app/screens/login_screen.dart';

void main() {
  testWidgets('muestra el inicio de sesión en español', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(api: ApiClient(), onAuthenticated: (_) {}),
      ),
    );
    expect(find.text('Mi WellQ'), findsOneWidget);
    expect(find.text('Código de Clínica'), findsOneWidget);
    expect(find.text('Ingresar a mi portal'), findsOneWidget);
  });
}

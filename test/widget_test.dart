import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:javier_advmobprog/main.dart';
import 'package:javier_advmobprog/providers/cart_provider.dart';
import 'package:javier_advmobprog/providers/theme_provider.dart';

void main() {
  testWidgets('App boots to splash screen with providers available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('NUBD Exchange'), findsOneWidget);
  });
}

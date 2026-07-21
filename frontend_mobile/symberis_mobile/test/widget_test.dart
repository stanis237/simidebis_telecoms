import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simidebis_mobile/router/app_router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter,
      ),
    );
    expect(find.byType(MaterialApp), findsNothing); // router replaces MaterialApp
  });
}

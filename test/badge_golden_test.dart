import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/models/badge_data.dart';
import 'package:cracha_app/views/badge_view.dart';

// TESTE DIAGNÓSTICO TEMPORÁRIO — gera screenshot do BadgeView atual.
// Pode apagar depois do diagnóstico.
void main() {
  testWidgets('badge golden diagnostico', (tester) async {
    final badge = BadgeData(
      name: 'MARIANNE PAULA SANTOS DA COSTA',
      role: 'ASSESSORA DE GABINETE DA SECRETARIA',
      department: 'SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF808080),
          body: Center(
            child: BadgeView(
              badgeData: badge,
              onImageTap: () {},
              onNameTap: () {},
              onRoleTap: () {},
              onDepartmentTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BadgeView),
      matchesGoldenFile('goldens/badge_view.png'),
    );
  });
}

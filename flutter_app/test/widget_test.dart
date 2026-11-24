import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/model/prediction_api.dart';

void main() {
  testWidgets('Validates inputs and renders the API result', (tester) async {
    Map<String, num>? request;
    await tester.pumpWidget(
      MyApp(
        predict: (values) async {
          request = values;
          return PredictionResult.fromJson({
            'predicted_class': 1,
            'model_score': 0.63,
            'bmi': 24.91,
          });
        },
      ),
    );
    final button = find.text('예측하기');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(request, isNull);
    expect(find.text('정수를 입력해 주세요.'), findsOneWidget);

    const values = {
      'glucose_mg_dl': 135.5,
      'height_cm': 170,
      'weight_kg': 72,
      'age_years': 45,
    };
    for (final entry in values.entries) {
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value.toString());
    }
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(request, values);
    expect(find.text('당뇨로 분류됨'), findsOneWidget);
    expect(find.text('모델 예측  63.0%'), findsOneWidget);
    expect(find.textContaining('BMI'), findsNothing);
  });
}

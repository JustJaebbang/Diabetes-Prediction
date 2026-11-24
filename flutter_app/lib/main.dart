import 'package:flutter/material.dart';

import 'model/prediction_api.dart';
import 'view/prediction_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.predict = requestPrediction});

  final Predict predict;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff146858)),
      scaffoldBackgroundColor: const Color(0xfff4f7f5),
    );
    return MaterialApp(
      title: '당뇨 예측',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: PredictionPage(predict: predict),
    );
  }
}

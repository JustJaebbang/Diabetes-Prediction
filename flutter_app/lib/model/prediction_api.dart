import 'dart:async';
import 'dart:convert';
import 'dart:io';

const predictionFields = [
  PredictionField('glucose_mg_dl', '혈당', 'mg/dL'),
  PredictionField('height_cm', '키', 'cm', minimum: 1, maximum: 300),
  PredictionField('weight_kg', '몸무게', 'kg', maximum: 1000),
  PredictionField('age_years', '만 나이', '세', integer: true, maximum: 130),
];

class PredictionField {
  const PredictionField(
    this.key,
    this.label,
    this.unit, {
    this.integer = false,
    this.minimum,
    this.maximum,
  });

  final String key;
  final String label;
  final String unit;
  final bool integer;
  final num? minimum;
  final num? maximum;

  num? parse(String text) =>
      integer ? int.tryParse(text.trim()) : double.tryParse(text.trim());

  String? validate(String? text) {
    final value = parse(text ?? '');
    if (value == null || !value.isFinite) {
      return integer ? '정수를 입력해 주세요.' : '숫자를 입력해 주세요.';
    }
    final min = minimum;
    final max = maximum;
    if (min == null ? value <= 0 : value < min) {
      return min == null ? '0보다 큰 값을 입력해 주세요.' : '$min 이상 입력해 주세요.';
    }
    if (max != null && value > max) return '$max 이하로 입력해 주세요.';
    return null;
  }
}

class PredictionResult {
  const PredictionResult({
    required this.predictedClass,
    this.score,
    this.notice,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final predictedClass = json['predicted_class'];
    if (predictedClass is! int ||
        (predictedClass != 0 && predictedClass != 1)) {
      throw const FormatException('Unknown class');
    }
    final score = json['model_score'];
    final notice = json['notice'];
    return PredictionResult(
      predictedClass: predictedClass,
      score: score is num ? score.toDouble() : null,
      notice: notice is String && notice.isNotEmpty ? notice : null,
    );
  }

  final int predictedClass;
  final double? score;
  final String? notice;
}

typedef Predict = Future<PredictionResult> Function(Map<String, num> values);

Future<PredictionResult> requestPrediction(Map<String, num> values) async {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  final baseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : Platform.isAndroid
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';
  final client = HttpClient();
  try {
    return await (() async {
      final request = await client.postUrl(
        Uri.parse(baseUrl).resolve('/predict'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(values));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      switch (response.statusCode) {
        case 200:
          return PredictionResult.fromJson(
            jsonDecode(body) as Map<String, dynamic>,
          );
        case 422:
          throw const PredictionException('서버가 입력값을 받지 못했어요. 입력 항목을 확인해 주세요.');
        case 503:
          throw const PredictionException('예측 모델이 아직 준비되지 않았어요.');
        default:
          throw const PredictionException('예측을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
    })().timeout(const Duration(seconds: 15));
  } on TimeoutException {
    throw const PredictionException('서버 응답 시간이 초과됐어요.');
  } on IOException {
    throw const PredictionException('서버에 연결할 수 없어요. 서버 주소와 실행 상태를 확인해 주세요.');
  } on FormatException {
    throw const PredictionException('서버 응답 형식을 확인해 주세요.');
  } on TypeError {
    throw const PredictionException('서버 응답 형식을 확인해 주세요.');
  } finally {
    client.close(force: true);
  }
}

class PredictionException implements Exception {
  const PredictionException(this.message);
  final String message;
}

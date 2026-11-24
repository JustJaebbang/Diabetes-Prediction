import 'package:flutter/foundation.dart';

import '../model/prediction_api.dart';

class PredictionViewModel extends ChangeNotifier {
  PredictionViewModel(this._predict);

  final Predict _predict;
  bool _disposed = false;
  bool _loading = false;
  String? _error;
  PredictionResult? _result;

  bool get loading => _loading;
  String? get error => _error;
  PredictionResult? get result => _result;

  Future<void> submit(Map<String, num> values) async {
    if (_loading || _disposed) return;
    _loading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      _result = await _predict(values);
    } on PredictionException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

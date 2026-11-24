import 'package:flutter/material.dart';

import '../model/prediction_api.dart';
import '../vm/prediction_view_model.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key, required this.predict});
  final Predict predict;

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _form = GlobalKey<FormState>();
  final _controllers = {
    for (final field in predictionFields) field.key: TextEditingController(),
  };
  late final _viewModel = PredictionViewModel(
    (values) => widget.predict(values),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _viewModel.submit({
      for (final field in predictionFields)
        field.key: field.parse(_controllers[field.key]!.text)!,
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => _buildPage(context),
  );

  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final result = _viewModel.result;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Icon(
                          Icons.monitor_heart_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '당뇨 예측',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('측정값을 입력하면 모델의 분류 결과를 확인할 수 있어요.'),
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    color: colors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final field in predictionFields)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  key: ValueKey(field.key),
                                  controller: _controllers[field.key],
                                  enabled: !_viewModel.loading,
                                  validator: field.validate,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: !field.integer,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: field.label,
                                    suffixText: field.unit,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            FilledButton(
                              onPressed: _viewModel.loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: Text(
                                _viewModel.loading ? '예측 중…' : '예측하기',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_viewModel.error case final error?) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(error, style: TextStyle(color: colors.error)),
                    ),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      color: colors.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Semantics(
                          liveRegion: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.predictedClass == 1
                                    ? '당뇨'
                                    : '정상',
                                style: theme.textTheme.titleLarge,
                              ),
                              if (result.score case final score?)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '모델 예측  ${(score * 100).toStringAsFixed(1)}%',
                                  ),
                                ),
                              if (result.notice case final notice?)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(notice),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '실험용 모델의 결과입니다. 당뇨 진단은 의료기관에서 확인하세요.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

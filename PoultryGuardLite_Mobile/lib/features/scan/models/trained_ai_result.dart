class TrainedAiResult {
  final bool isSuccess;
  final String diseaseName;
  final double confidence;
  final String message;

  const TrainedAiResult({
    required this.isSuccess,
    required this.diseaseName,
    required this.confidence,
    required this.message,
  });

  factory TrainedAiResult.failed({String? message}) {
    return TrainedAiResult(
      isSuccess: false,
      diseaseName: 'Unidentified',
      confidence: 42.15,
      message: message ?? 'The trained model could not confidently identify this image.',
    );
  }

  factory TrainedAiResult.success({
    required String diseaseName,
    required double confidence,
    String? message,
  }) {
    return TrainedAiResult(
      isSuccess: true,
      diseaseName: diseaseName,
      confidence: confidence,
      message: message ?? 'The trained AI model has analyzed the image successfully.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isSuccess': isSuccess,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'message': message,
    };
  }

  factory TrainedAiResult.fromMap(Map<String, dynamic>? map) {
    if (map == null) return TrainedAiResult.failed();
    return TrainedAiResult(
      isSuccess: map['isSuccess'] as bool? ?? false,
      diseaseName: map['diseaseName'] as String? ?? 'Unidentified',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      message: map['message'] as String? ?? '',
    );
  }
}

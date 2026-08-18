import 'dart:convert';

/// Structured response from Gemini Vision AI.
class AiScanResultModel {
  final String diseaseName;
  final int confidence;
  final String severity; // Low, Medium, High, Critical
  final String possibleCause;
  final String immediateAction;
  final String treatment;
  final String prevention;
  final bool isolationRequired;

  const AiScanResultModel({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.possibleCause,
    required this.immediateAction,
    required this.treatment,
    required this.prevention,
    required this.isolationRequired,
  });

  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'possibleCause': possibleCause,
      'immediateAction': immediateAction,
      'treatment': treatment,
      'prevention': prevention,
      'isolationRequired': isolationRequired,
    };
  }

  factory AiScanResultModel.fromMap(Map<String, dynamic> map) {
    return AiScanResultModel(
      diseaseName: map['diseaseName'] ?? 'Unknown',
      confidence: map['confidence']?.toInt() ?? 0,
      severity: map['severity'] ?? 'Unknown',
      possibleCause: map['possibleCause'] ?? '',
      immediateAction: map['immediateAction'] ?? '',
      treatment: map['treatment'] ?? '',
      prevention: map['prevention'] ?? '',
      isolationRequired: map['isolationRequired'] ?? false,
    );
  }

  factory AiScanResultModel.fromJson(String source) =>
      AiScanResultModel.fromMap(json.decode(source));
}

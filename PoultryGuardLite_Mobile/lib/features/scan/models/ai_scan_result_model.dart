import 'dart:convert';
import 'trained_ai_result.dart';

/// Structured response from AI Vision Analysis (Gemini API + Trained AI Model).
class AiScanResultModel {
  final String diseaseName;
  final int confidence;
  final String severity; // Low, Medium, High, Critical
  final String symptoms;
  final String possibleCause;
  final String immediateAction;
  final String treatment;
  final String prevention;
  final String recommendation;
  final bool isolationRequired;
  final TrainedAiResult? trainedAiResult;

  const AiScanResultModel({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    this.symptoms = '',
    required this.possibleCause,
    required this.immediateAction,
    required this.treatment,
    required this.prevention,
    this.recommendation = '',
    required this.isolationRequired,
    this.trainedAiResult,
  });

  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'symptoms': symptoms,
      'possibleCause': possibleCause,
      'immediateAction': immediateAction,
      'treatment': treatment,
      'prevention': prevention,
      'recommendation': recommendation,
      'isolationRequired': isolationRequired,
      if (trainedAiResult != null) 'trainedAiResult': trainedAiResult!.toMap(),
    };
  }

  factory AiScanResultModel.fromMap(Map<String, dynamic> map) {
    final dName = map['diseaseName'] as String? ?? 'Unknown';
    final immAction = map['immediateAction'] as String? ?? '';
    final treat = map['treatment'] as String? ?? '';

    return AiScanResultModel(
      diseaseName: dName,
      confidence: (map['confidence'] as num?)?.toInt() ?? 0,
      severity: map['severity'] as String? ?? 'Unknown',
      symptoms: map['symptoms'] as String? ?? _defaultSymptomsFor(dName),
      possibleCause: map['possibleCause'] as String? ?? '',
      immediateAction: immAction,
      treatment: treat,
      prevention: map['prevention'] as String? ?? '',
      recommendation: map['recommendation'] as String? ??
          (immAction.isNotEmpty ? immAction : treat),
      isolationRequired: map['isolationRequired'] as bool? ?? false,
      trainedAiResult: map['trainedAiResult'] != null
          ? TrainedAiResult.fromMap(map['trainedAiResult'] as Map<String, dynamic>?)
          : null,
    );
  }

  factory AiScanResultModel.fromJson(String source) =>
      AiScanResultModel.fromMap(json.decode(source) as Map<String, dynamic>);

  static String _defaultSymptomsFor(String disease) {
    final lower = disease.toLowerCase();
    if (lower.contains('ibh') || lower.contains('hepatitis')) {
      return 'Depression, Loss of appetite, Swollen liver, White patches on liver, Increased mortality';
    } else if (lower.contains('coccidiosis')) {
      return 'Bloody diarrhea, Weight loss, Lethargy, Ruffled feathers, Pale comb';
    } else if (lower.contains('coli') || lower.contains('e. coli')) {
      return 'Respiratory distress, Reduced feed intake, Diarrhea, Lethargy, Airsacculitis';
    } else if (lower.contains('yolk')) {
      return 'Swollen abdomen, Unabsorbed yolk sac, Weakness, High early mortality';
    }
    return 'Lethargy, Reduced feed intake, Abnormal droppings, Weakness';
  }

  AiScanResultModel copyWith({
    String? diseaseName,
    int? confidence,
    String? severity,
    String? symptoms,
    String? possibleCause,
    String? immediateAction,
    String? treatment,
    String? prevention,
    String? recommendation,
    bool? isolationRequired,
    TrainedAiResult? trainedAiResult,
  }) {
    return AiScanResultModel(
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      symptoms: symptoms ?? this.symptoms,
      possibleCause: possibleCause ?? this.possibleCause,
      immediateAction: immediateAction ?? this.immediateAction,
      treatment: treatment ?? this.treatment,
      prevention: prevention ?? this.prevention,
      recommendation: recommendation ?? this.recommendation,
      isolationRequired: isolationRequired ?? this.isolationRequired,
      trainedAiResult: trainedAiResult ?? this.trainedAiResult,
    );
  }
}

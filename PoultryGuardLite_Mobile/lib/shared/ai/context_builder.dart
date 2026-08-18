import '../rules/models/rule_context.dart';
import '../rules/rule_engine.dart';

class ContextBuilder {
  /// Summarizes the Rule Engine outputs into a clean JSON object
  /// ready to be injected into an AI prompt.
  static Map<String, dynamic> build(RuleContext context) {
    final metrics = RuleEngine.evaluate(context);
    
    // Add any AI-specific context transformations here
    return {
      'flockMetrics': metrics,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}

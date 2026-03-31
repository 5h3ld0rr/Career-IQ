import 'package:flutter/material.dart';
import '../models/salary_insight.dart';
import '../services/ai_service.dart';

class SalaryProvider with ChangeNotifier {
  final AIService _aiService = AIService();

  List<SalaryInsight> _insights = [];
  bool _isLoading = false;
  String? _error;

  List<SalaryInsight> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSalaryInsights({
    required List<String> userSkills,
    required List<String> targetJobTitles,
  }) async {
    // Fetch even if empty to provide general market insights

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await _aiService.getSalaryInsights(
        userSkills: userSkills,
        targetJobTitles: targetJobTitles,
      );

      if (_insights.isEmpty) {
        _error =
            "Could not generate insights. Please check your skills and try again.";
      }
    } catch (e) {
      _error = "An error occurred while analyzing salary ROI: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearInsights() {
    _insights = [];
    _error = null;
    notifyListeners();
  }
}

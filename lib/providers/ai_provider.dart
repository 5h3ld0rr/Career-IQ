import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIProvider with ChangeNotifier {
  final AIService _aiService = AIService();
  
  List<String> _currentTips = [];
  bool _isLoading = false;
  String? _analysisResult;

  List<String> get currentTips => _currentTips;
  bool get isLoading => _isLoading;
  String? get analysisResult => _analysisResult;

  Future<void> fetchTips(String category) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentTips = await _aiService.getTipsForCategory(category);
    } catch (e) {
      debugPrint('Error fetching AI tips: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeResume(String content) async {
    _isLoading = true;
    _analysisResult = null;
    notifyListeners();

    try {
      _analysisResult = await _aiService.analyzeResume(content);
    } catch (e) {
      _analysisResult = "Analysis failed. Please try again later.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

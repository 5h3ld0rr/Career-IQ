import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIProvider with ChangeNotifier {
  final AIService _aiService = AIService();

  List<String> _currentTips = [];
  bool _isLoading = false;
  String? _analysisResult;

  String? _coverLetter;
  Map<String, dynamic>? _skillsGap;
  List<Map<String, dynamic>> _extractedSkills = [];
  bool _isGenerating = false;
  Map<String, dynamic> _recruiterMarketInsights = {};

  List<String> get currentTips => _currentTips;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  Map<String, dynamic> get recruiterMarketInsights => _recruiterMarketInsights;
  String? get analysisResult => _analysisResult;
  String? get coverLetter => _coverLetter;
  Map<String, dynamic>? get skillsGap => _skillsGap;
  List<Map<String, dynamic>> get extractedSkills => _extractedSkills;

  Future<void> extractSkills(String content) async {
    _isLoading = true;
    _extractedSkills = [];
    notifyListeners();

    try {
      _extractedSkills = await _aiService.extractSkillsFromResume(content);
    } catch (e) {
      debugPrint('Error extracting skills: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeGeneralMarketGap(String resumeContent) async {
    _isLoading = true;
    _skillsGap = null;
    notifyListeners();

    try {
      _skillsGap = await _aiService.analyzeSkillsGap(
        resumeContent: resumeContent,
        jobDescription: "General Industry Standards for high-growth tech and business roles 2026",
      );
    } catch (e) {
      debugPrint('Error in general market analysis: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTips(String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentTips = await _aiService.getTipsForCategory(category);
    } catch (e) {
      debugPrint('Error fetching AI tips: $e');
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

  Future<void> analyzeSkillsGap({
    required String resumeContent,
    required String jobDescription,
  }) async {
    _isLoading = true;
    _skillsGap = null;
    notifyListeners();

    try {
      _skillsGap = await _aiService.analyzeSkillsGap(
        resumeContent: resumeContent,
        jobDescription: jobDescription,
      );
    } catch (e) {
      debugPrint('Error in skills gap analysis: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateCoverLetter({
    required String resumeContent,
    required String jobDescription,
  }) async {
    _isLoading = true;
    _coverLetter = null;
    notifyListeners();

    try {
      _coverLetter = await _aiService.generateCoverLetter(
        resumeContent: resumeContent,
        jobDescription: jobDescription,
      );
    } catch (e) {
      _coverLetter = "Failed to generate cover letter. Please try again later.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getInterviewPrep({
    required String companyName,
    required String jobDescription,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _aiService.generateInterviewPrep(
        companyName: companyName,
        jobDescription: jobDescription,
      );
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Recruiter AI Hub Wrappers ---

  Future<Map<String, dynamic>> generateJobDescription({
    required String title,
    required String company,
    required String requirements,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      return await _aiService.generateJobDescription(
        title: title,
        company: company,
        requirements: requirements,
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> scoreResume({
    required String resumeContent,
    required String jobDescription,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      return await _aiService.scoreResume(
        resumeContent: resumeContent,
        jobDescription: jobDescription,
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> getMarketInsights({
    required String jobTitle,
    required String location,
  }) async {
    _isGenerating = true;
    notifyListeners();
    try {
      _recruiterMarketInsights = await _aiService.getMarketInsights(
        jobTitle: jobTitle,
        location: location,
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}

import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class AIService {
  // TODO: Replace with your actual Gemini API Key or load from secure storage
  static const String _apiKey = 'REPLACE_WITH_YOUR_GEMINI_API_KEY';

  final GenerativeModel _model;

  AIService()
    : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

  static const List<String> _generalTips = [
    "Use strong action verbs list like 'managed', 'developed', 'coordinated'.",
    "Quantify your achievements (e.g., 'Increased efficiency by 20%').",
    "Tailor your resume for each specific job description.",
    "Keep your resume to 1-2 pages maximum.",
    "Ensure your contact information is up to date and professional.",
    "Use a clean, easy-to-read font and consistent formatting.",
    "Highlight your most relevant skills at the top.",
  ];

  static const Map<String, List<String>> _skillTips = {
    "Design": [
      "Include a link to your online portfolio (e.g., Behance, Dribbble).",
      "Mention specific design tools you are expert in (Figma, Adobe XD).",
      "Showcase your understanding of user-centered design principles.",
    ],
    "Tech": [
      "List your GitHub profile or technical blog.",
      "Detail your experience with specific frameworks and languages.",
      "Mention your participation in hackathons or open-source projects.",
    ],
    "Marketing": [
      "Showcase your experience with SEO and SEM tools.",
      "Highlight your creativity in past successful campaigns.",
      "Mention your expertise in social media analytics.",
    ],
  };

  Future<List<String>> getTipsForCategory(String category) async {
    // We can still return these quickly, or even use Gemini to generate custom tips
    final categoryTips = _skillTips[category] ?? [];
    return [..._generalTips, ...categoryTips]..shuffle();
  }

  Future<String> analyzeResume(String content) async {
    if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      return "Please configure your Gemini API Key in AIService to enable real AI analysis.";
    }

    try {
      final prompt =
          "Analyze the following resume content and provide constructive feedback, highlighting strengths and areas for improvement. Keep it professional and encouraging:\n\n$content";
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "AI couldn't generate a response at this time.";
    } catch (e) {
      return "Error analyzing resume: $e";
    }
  }

  Future<Map<String, dynamic>> analyzeSkillsGap({
    required String resumeContent,
    required String jobDescription,
  }) async {
    if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      return {
        "matchPercentage": 0,
        "currentSkills": [],
        "missingSkills": [],
        "recommendations": ["Please configure your Gemini API Key."]
      };
    }

    try {
      final prompt = """
      Compare the following resume content with the job description.
      Provide a JSON response with the following keys:
      - 'matchPercentage': an integer from 0-100 indicating how well the candidate matches the job.
      - 'currentSkills': a list of skills from the resume that are relevant to the job.
      - 'missingSkills': a list of skills mentioned in the job description but missing from the resume.
      - 'recommendations': a list of 3 actionable steps to bridge the skill gap.

      Resume Content:
      $resumeContent

      Job Description:
      $jobDescription

      Return ONLY the JSON.
      """;
      
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "{}";
      
      // Basic JSON parsing from response text
      // In a production app, use a proper JSON decoder with error handling
      return _parseJsonResponse(text);
    } catch (e) {
      return {
        "matchPercentage": 0,
        "currentSkills": [],
        "missingSkills": [],
        "recommendations": ["Error analyzing skills gap: $e"]
      };
    }
  }

  Map<String, dynamic> _parseJsonResponse(String text) {
    // Simple extraction if the AI wraps JSON in backticks
    String jsonStr = text;
    if (text.contains("```json")) {
      jsonStr = text.split("```json")[1].split("```")[0];
    } else if (text.contains("```")) {
      jsonStr = text.split("```")[1].split("```")[0];
    }
    
    // In a real scenario, use jsonDecode
    // For now, I'll assume it's valid JSON or return default
    try {
      return json.decode(jsonStr.trim()) as Map<String, dynamic>;
    } catch (_) {
      return {
        "matchPercentage": 50,
        "currentSkills": ["Parsing Error"],
        "missingSkills": ["Check API structure"],
        "recommendations": ["Try again later"]
      };
    }
  }

  Future<String> generateCoverLetter({
    required String resumeContent,
    required String jobDescription,
  }) async {
    if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      return "Please configure your Gemini API Key in AIService to enable AI cover letter generation.";
    }

    try {
      final prompt =
          "Based on the following resume and job description, generate a professional and compelling cover letter:\n\nResume:\n$resumeContent\n\nJob Description:\n$jobDescription";
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "AI couldn't generate a cover letter.";
    } catch (e) {
      return "Error generating cover letter: $e";
    }
  }
}

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/salary_insight.dart';

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

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
      return _parseJsonResponse(response.text ?? "{}");
    } catch (e) {
      return {
        "matchPercentage": 0,
        "currentSkills": [],
        "missingSkills": [],
        "recommendations": ["Error analyzing skills gap: $e"]
      };
    }
  }

  Future<List<SalaryInsight>> getSalaryInsights({
    required List<String> userSkills,
    required List<String> targetJobTitles,
  }) async {
    if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      return [];
    }

    try {
      final prompt = """
      Act as a specialized Job Market Analyst. 
      Analyze the following user skills and target job titles to provide 3-5 high-impact salary insights for someone looking to grow their career.
      For each insight, provide:
      - 'skillName': The name of a high-value skill (could be one they have or one they SHOULD add).
      - 'currentMarketValue': Estimated annual salary increase in USD for having this skill.
      - 'potentialIncreasePercentage': Percentage growth in salary if this skill is mastered.
      - 'trendData': A list of 6 monthly data points (representing growth trend over last 6 months, normalized 0-100).
      - 'aiRecommendation': A 1-sentence strategic advice on why this skill is valuable.

      User Skills: ${userSkills.join(', ')}
      Target Titles: ${targetJobTitles.join(', ')}

      Return the response as a JSON list of objects with these keys. 
      Return ONLY the JSON list.
      """;

      final response = await _model.generateContent([Content.text(prompt)]);
      final List<dynamic> jsonList = _parseJsonListResponse(response.text ?? "[]");
      
      return jsonList.map((e) => SalaryInsight.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print("Error in getSalaryInsights: $e");
      return [];
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

  Future<Map<String, dynamic>> generateInterviewPrep({
    required String companyName,
    required String jobDescription,
  }) async {
    final prompt = """
    Generate interview preparation details for a candidate interviewing at $companyName for the following role:
    
    Job Description:
    $jobDescription

    Provide the response in JSON format with these exact keys:
    - 'companySummary': A brief, 2-3 sentence overview of what the company does (if you know it, or a generic professional guess based on the description).
    - 'commonQuestions': A list of 5-7 most likely behavioral or technical interview questions for this specific role.
    - 'preparationTips': A list of 3-5 specific tips for this interview.

    Return ONLY the JSON.
    """;

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text ?? "{}");
    } catch (e) {
      return {
        "companySummary": "Could not fetch company details.",
        "commonQuestions": [],
        "preparationTips": ["Error generating prep: $e"]
      };
    }
  }

  Future<List<String>> generateMockInterviewQuestions({
    required String role,
    required String experienceLevel,
  }) async {
    final prompt = """
    Generate exactly 5 targeted interview questions for a $experienceLevel $role role. 
    Mix technical/role-specific questions with behavioral ones.
    Return only a JSON list of strings.
    """;
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final list = _parseJsonListResponse(response.text ?? "[]");
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint("Error generating mock questions: $e");
      return [
        "Tell me about a challenging project you've worked on recently.",
        "How do you handle disagreements within a technical team?",
        "What is your approach to learning new technologies?",
        "Where do you see yourself in the next 3 to 5 years?",
        "Why do you want for this role?"
      ];
    }
  }

  Future<Map<String, dynamic>> analyzeInterviewSession({
    required List<Map<String, String>> conversation,
  }) async {
    final conversationStr = conversation.map((e) => "Q: ${e['question']}\nA: ${e['answer']}").join("\n\n");
    
    final prompt = """
    As an expert interviewer and career coach, analyze the following interview conversation. 
    
    $conversationStr
    
    Provide a score (0-100) and 3-5 high-impact insights into the candidate's performance.
    Return only JSON with these keys:
    - 'score': (double)
    - 'insights': list of objects with {'icon': (Ionicons/Material icon name string, like 'checkmark_circle_outline' or 'bulb_outline'), 'title': (String), 'subtitle': (String), 'color': (one of 'blue', 'orange', 'red', 'green', 'indigo')}
    
    Return ONLY the JSON.
    """;
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text ?? "{}");
    } catch (e) {
      debugPrint("Error analyzing interview: $e");
      return {
        'score': 0.0,
        'insights': [
          {'icon': 'warning', 'title': 'Analysis Error', 'subtitle': 'Could not analyze session due to an error.', 'color': 'red'}
        ]
      };
    }
  }

  Map<String, dynamic> _parseJsonResponse(String text) {
    String jsonStr = text;
    if (text.contains("```json")) {
      jsonStr = text.split("```json")[1].split("```")[0];
    } else if (text.contains("```")) {
      jsonStr = text.split("```")[1].split("```")[0];
    }
    
    try {
      return json.decode(jsonStr.trim()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  List<dynamic> _parseJsonListResponse(String text) {
    String jsonStr = text;
    if (text.contains("```json")) {
      jsonStr = text.split("```json")[1].split("```")[0];
    } else if (text.contains("```")) {
      jsonStr = text.split("```")[1].split("```")[0];
    }
    
    try {
      return json.decode(jsonStr.trim()) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }
}

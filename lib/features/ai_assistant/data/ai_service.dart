import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:careeriq/features/salary_roi/data/salary_model.dart';
import 'package:careeriq/features/ai_assistant/data/open_router_service.dart';

class AIService {
  final OpenRouterService _openRouter = OpenRouterService();

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
    try {
      final prompt =
          "Analyze the following resume content and provide constructive feedback, highlighting strengths and areas for improvement. Keep it professional and encouraging:\n\n$content";
      return await _openRouter.generateResponse(prompt);
    } catch (e) {
      return "Error analyzing resume: $e";
    }
  }

  Future<List<Map<String, dynamic>>> extractSkillsFromResume(
    String content,
  ) async {
    if (content.isEmpty) return [];

    try {
      final prompt =
          """
      Extract the top 3-5 professional skills from this resume. 
      For each skill, provide a 'skill' name and a 'match' percentage (0-100) indicating how prominently it's mentioned.
      Return the response as a JSON list of objects with keys 'skill' (String) and 'match' (int).
      Resume Content:
      $content
      
      Return ONLY the JSON list.
      """;

      final response = await _openRouter.generateResponse(prompt);
      final list = _safeParseJson(response);
      return list is List
          ? list.map((e) => e as Map<String, dynamic>).toList()
          : [];
    } catch (e) {
      debugPrint("Error extracting skills: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeSkillsGap({
    required String resumeContent,
    required String jobDescription,
  }) async {
    try {
      final prompt =
          """
      Compare the following resume content with the job description.
      Provide a JSON response with the following keys:
      - 'matchPercentage': an integer from 0-100 indicating how well the candidate matches the job.
      - 'summary': a 1-sentence professional qualitative summary of the overall fit.
      - 'currentSkills': a list of skills from the resume that are relevant to the job.
      - 'missingSkills': a list of skills mentioned in the job description but missing from the resume.
      - 'recommendations': a list of 3 actionable steps to bridge the skill gap.

      Resume Content:
      $resumeContent

      Job Description:
      $jobDescription

      Return ONLY the JSON.
      """;

      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is Map<String, dynamic>
          ? result
          : {
              "matchPercentage": 0,
              "summary": "AI error parsing fit.",
              "currentSkills": [],
              "missingSkills": [],
              "recommendations": [],
            };
    } catch (e) {
      return {
        "matchPercentage": 0,
        "summary": "Error: $e",
        "currentSkills": [],
        "missingSkills": [],
        "recommendations": ["Error analyzing skills gap: $e"],
      };
    }
  }

  Future<List<SalaryInsight>> getSalaryInsights({
    required List<String> userSkills,
    required List<String> targetJobTitles,
  }) async {
    try {
      final prompt =
          """
      Act as a specialized Career ROI and Market Value Analyst. 
      Analyze the following professional profile data and target roles to provide 3-5 high-impact salary insights.
      
      User Skills Profile: ${userSkills.isEmpty ? "General Digital & Soft Skills" : userSkills.join(', ')}
      Target Career Titles: ${targetJobTitles.isEmpty ? "High-Growth Tech & Business Roles" : targetJobTitles.join(', ')}

      For each insight, provide:
      - 'skillName': A high-value skill.
      - 'currentMarketValue': Estimated annual salary increase in USD for having this skill.
      - 'potentialIncreasePercentage': Percentage growth in salary if this skill is mastered (e.g., 15.5).
      - 'trendData': A list of exactly 6 monthly data points (representing value trend over last 6 months, normalized 0-100).
      - 'aiRecommendation': A 1-sentence strategic advice on why this skill is a high-ROI investment.

      Return the response as a JSON list of objects with these exact keys. 
      Return ONLY the JSON list.
      """;

      final response = await _openRouter.generateResponse(prompt);
      final jsonList = _safeParseJson(response);

      if (jsonList is List) {
        return jsonList
            .map((e) => SalaryInsight.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error in getSalaryInsights: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> generateJobDescription({
    required String title,
    required String company,
    required String requirements,
  }) async {
    final prompt =
        """
    Generate a professional Job Description.
    Title: $title
    Company: $company
    Key Requirements: $requirements

    Provide JSON with:
    - 'description': Professional overview
    - 'responsibilities': (List<String>)
    - 'requirements': (List<String>)
    - 'salaryRange': Estimated market range
    
    Return ONLY the JSON.
    """;

    try {
      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is Map<String, dynamic>
          ? result
          : {"error": "Invalid format from AI"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> scoreResume({
    required String resumeContent,
    required String jobDescription,
  }) async {
    final prompt =
        """
    Act as an expert Recruiter ATS. Score this resume against the JD.
    Resume: $resumeContent
    JD: $jobDescription

    Provide JSON with:
    - 'overallScore': (int 0-100)
    - 'keyMatches': (List<String>)
    - 'missingCritical': (List<String>)
    - 'verdict': (Short hiring recommendation)
    
    Return ONLY the JSON.
    """;

    try {
      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is Map<String, dynamic>
          ? result
          : {"error": "Invalid format from AI"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMarketInsights({
    required String jobTitle,
    required String location,
  }) async {
    final prompt =
        """
    Provide modern, high-accuracy (2026 Q1-Q2) hiring market insights for:
    Role: $jobTitle
    Location: $location (Adjust values if location is Global/Remote vs specific)

    Provide JSON with these EXACT keys:
    - 'avgSalary': (String, e.g. "\$140k - \$195k")
    - 'salaryReasoning': (String, a short 1-sentence explanation of why this range exists in 2026, e.g. "Driven by high demand for specialized AI architects.")
    - 'demandLevel': (Low/Medium/High)
    - 'demandReasoning': (String, a short 1-sentence explanation of current demand trends)
    - 'topSkills': (List<String>, top 3 trending skills for this role)
    - 'hiringDifficulty': (int 1-10)
    - 'remoteTrends': (String, current status of remote/hybrid for this specific role)
    
    Return ONLY the JSON.
    """;

    try {
      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is Map<String, dynamic>
          ? result
          : {"error": "Invalid format from AI"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  dynamic _safeParseJson(String text) {
    if (text.isEmpty) return null;

    String jsonStr = text;
    final jsonBlockMatch = RegExp(
      r"```(?:json)?\s*([\s\S]*?)\s*```",
    ).firstMatch(text);
    if (jsonBlockMatch != null) {
      jsonStr = jsonBlockMatch.group(1) ?? text;
    }

    try {
      return json.decode(jsonStr.trim());
    } catch (e) {
      debugPrint("Primary JSON parse failed: $e. Attempting fallback.");
      try {
        int firstBrace = jsonStr.indexOf('{');
        int firstBracket = jsonStr.indexOf('[');
        int lastBrace = jsonStr.lastIndexOf('}');
        int lastBracket = jsonStr.lastIndexOf(']');

        int start = -1;
        int end = -1;

        if (firstBrace != -1 &&
            (firstBracket == -1 || firstBrace < firstBracket)) {
          start = firstBrace;
          end = lastBrace;
        } else if (firstBracket != -1) {
          start = firstBracket;
          end = lastBracket;
        }

        if (start != -1 && end != -1 && end > start) {
          return json.decode(jsonStr.substring(start, end + 1));
        }
      } catch (e2) {
        debugPrint("JSON recovery failed: $e2");
      }
      return null;
    }
  }

  Future<int> calculateJobMatchScore({
    required String resumeContent,
    required String jobDescription,
  }) async {
    if (resumeContent.isEmpty) return 0;
    try {
      final prompt =
          "Return ONLY an integer 0-100 score matching this Resume and JD:\nResume: $resumeContent\nJD: $jobDescription";
      final response = await _openRouter.generateResponse(prompt);
      return int.tryParse(
            RegExp(r'\d+').firstMatch(response)?.group(0) ?? '0',
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  Future<String> generateCoverLetter({
    required String resumeContent,
    required String jobDescription,
  }) async {
    try {
      final prompt =
          "Generate a professional cover letter for this resume and JD:\nResume: $resumeContent\nJD: $jobDescription";
      return await _openRouter.generateResponse(prompt);
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<Map<String, dynamic>> generateInterviewPrep({
    required String companyName,
    required String jobDescription,
  }) async {
    final prompt =
        """
    Prep JSON for $companyName:
    JD: $jobDescription
    Keys: 'companySummary', 'commonQuestions' (list), 'preparationTips' (list)
    """;
    try {
      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is Map<String, dynamic>
          ? result
          : {"error": "Invalid format"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  Future<List<String>> generateMockInterviewQuestions({
    required String role,
    required String experienceLevel,
  }) async {
    final prompt =
        "List exactly 5 mock interview questions for $experienceLevel $role as JSON list of strings.";
    try {
      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is List ? result.map((e) => e.toString()).toList() : [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeInterviewSession({
    required List<Map<String, String>> conversation,
  }) async {
    final conversationStr = conversation
        .map((e) => "Q: ${e['question']}\nA: ${e['answer']}")
        .join("\n\n");
    final prompt =
        "Analyze this interview. JSON keys: 'score' (double), 'insights' (list). Insights have 'icon', 'title', 'subtitle', 'color'.\n$conversationStr";
    try {
      final response = await _openRouter.generateResponse(prompt);
      final result = _safeParseJson(response);
      return result is Map<String, dynamic>
          ? result
          : {'score': 0.0, 'insights': []};
    } catch (e) {
      debugPrint("Error analyzing interview: $e");
      return {'score': 0.0, 'insights': []};
    }
  }
}

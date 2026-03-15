class AIService {
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
    await Future.delayed(const Duration(milliseconds: 500));
    final categoryTips = _skillTips[category] ?? [];
    return [..._generalTips, ...categoryTips]..shuffle();
  }

  Future<String> analyzeResume(String content) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulated AI analysis based on keywords
    if (content.toLowerCase().contains("figma")) {
      return "Your resume looks strong in Design! Consider adding more details about your prototyping process.";
    } else if (content.toLowerCase().contains("flutter")) {
      return "Great technical profile. Make sure to emphasize your experience with state management libraries like Bloc or Provider.";
    } else {
      return "Solid foundation. To stand out, try adding more specific results you achieved in your previous roles.";
    }
  }
}

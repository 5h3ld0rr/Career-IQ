class SalaryInsight {
  final String skillName;
  final double currentMarketValue;
  final double potentialIncreasePercentage;
  final List<double> trendData;
  final String aiRecommendation;

  SalaryInsight({
    required this.skillName,
    required this.currentMarketValue,
    required this.potentialIncreasePercentage,
    required this.trendData,
    required this.aiRecommendation,
  });

  factory SalaryInsight.fromJson(Map<String, dynamic> json) {
    return SalaryInsight(
      skillName: json['skillName'] ?? '',
      currentMarketValue: (json['currentMarketValue'] ?? 0.0).toDouble(),
      potentialIncreasePercentage: (json['potentialIncreasePercentage'] ?? 0.0)
          .toDouble(),
      trendData: (json['trendData'] as List? ?? [])
          .map<double>((e) => (e ?? 0.0).toDouble())
          .toList(),
      aiRecommendation: json['aiRecommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillName': skillName,
      'currentMarketValue': currentMarketValue,
      'potentialIncreasePercentage': potentialIncreasePercentage,
      'trendData': trendData,
      'aiRecommendation': aiRecommendation,
    };
  }
}

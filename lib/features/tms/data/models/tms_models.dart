/// Data models for the TMS (Traders Microfinance Suite) module.

class TmsApplication {
  final String? tmsId;
  final String? requestId;
  final String? shopId;
  final String? businessName;
  final double requestedLoanAmount;
  final double recommendedLoanAmount;
  final double maxLoanLimit;
  final double loanScore;
  final bool loanEligibility;
  final String eligibilityStatus;
  final String? applicationStatus;
  final String? dateCreated;

  const TmsApplication({
    this.tmsId,
    this.requestId,
    this.shopId,
    this.businessName,
    required this.requestedLoanAmount,
    required this.recommendedLoanAmount,
    required this.maxLoanLimit,
    required this.loanScore,
    required this.loanEligibility,
    required this.eligibilityStatus,
    this.applicationStatus,
    this.dateCreated,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory TmsApplication.fromJson(Map<String, dynamic> j) {
    final eligible = j['loan_eligibility'];
    return TmsApplication(
      tmsId: j['tms_id']?.toString(),
      requestId: j['request_id']?.toString(),
      shopId: j['shop_id']?.toString(),
      businessName: j['business_name']?.toString(),
      requestedLoanAmount: _d(j['requested_loan_amount']),
      recommendedLoanAmount: _d(j['recommended_loan_amount']),
      maxLoanLimit: _d(j['max_loan_limit']),
      loanScore: _d(j['loan_score']),
      loanEligibility: eligible == 1 || eligible == true || eligible == '1',
      eligibilityStatus: j['eligibility_status']?.toString() ?? '',
      applicationStatus: j['application_status']?.toString() ?? j['status']?.toString(),
      dateCreated: j['date_created']?.toString() ?? j['created_at']?.toString(),
    );
  }
}

// Central Pool Fee Model (FM-FEE-01 through FM-FEE-06 Ratified Baseline)
// Invariant: Member-paid fee outside Contribution C.
// RawFee = C * FeeRateBps / 10,000 -> RoundHalfUp -> min(max(Fee, MinFee), MaxFee).
// Fee does NOT modify C, E, TotalPot, paired allocations, or duration N.

class FeeConfigModel {
  final String feeConfigId;
  final int version;
  final int feeRateBps; // 10,000 bps = 100% (e.g. 200 bps = 2.0%)
  final int? minFeeMinor; // in integer minor units (piasters)
  final int? maxFeeMinor; // in integer minor units (piasters)
  final String currency;
  final String roundingPolicy; // 'ROUND_HALF_UP'
  final DateTime? effectiveAt;

  const FeeConfigModel({
    required this.feeConfigId,
    this.version = 1,
    required this.feeRateBps,
    this.minFeeMinor,
    this.maxFeeMinor,
    this.currency = 'EGP',
    this.roundingPolicy = 'ROUND_HALF_UP',
    this.effectiveAt,
  });

  factory FeeConfigModel.fromJson(Map<String, dynamic> json) {
    return FeeConfigModel(
      feeConfigId: json['feeConfigId'] as String? ?? json['fee_config_id'] as String? ?? 'default_fee_cfg',
      version: (json['version'] ?? 1) as int,
      feeRateBps: (json['feeRateBps'] ?? json['fee_rate_bps'] ?? 0) as int,
      minFeeMinor: (json['minFeeMinor'] ?? json['min_fee_minor']) as int?,
      maxFeeMinor: (json['maxFeeMinor'] ?? json['max_fee_minor']) as int?,
      currency: json['currency'] as String? ?? 'EGP',
      roundingPolicy: json['roundingPolicy'] as String? ?? json['rounding_policy'] as String? ?? 'ROUND_HALF_UP',
      effectiveAt: json['effectiveAt'] != null
          ? DateTime.parse(json['effectiveAt'] as String)
          : (json['effective_at'] != null ? DateTime.parse(json['effective_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'fee_config_id': feeConfigId,
    'version': version,
    'fee_rate_bps': feeRateBps,
    'min_fee_minor': minFeeMinor,
    'max_fee_minor': maxFeeMinor,
    'currency': currency,
    'rounding_policy': roundingPolicy,
    'effective_at': effectiveAt?.toIso8601String(),
  };

  /// Calculates the exact fee in integer minor units using Round Half Up and optional bounds.
  int calculateFeeMinor(int contributionMinor) {
    if (contributionMinor <= 0 || feeRateBps <= 0) {
      if (minFeeMinor != null && minFeeMinor! > 0) return minFeeMinor!;
      return 0;
    }

    // Integer-safe Round Half Up for positive numbers: (Numerator + 5000) ~/ 10000
    final rawNumerator = contributionMinor * feeRateBps;
    final calculatedFee = (rawNumerator + 5000) ~/ 10000;

    var finalFee = calculatedFee;
    if (minFeeMinor != null && finalFee < minFeeMinor!) {
      finalFee = minFeeMinor!;
    }
    if (maxFeeMinor != null && finalFee > maxFeeMinor!) {
      finalFee = maxFeeMinor!;
    }
    return finalFee;
  }

  /// Calculates total periodic member outflow (C + FinalFee).
  int calculatePeriodicOutflowMinor(int contributionMinor) {
    return contributionMinor + calculateFeeMinor(contributionMinor);
  }

  /// Standard fallback configuration when explicit server config is pending.
  static FeeConfigModel standardDefault({
    int feeRateBps = 200,
    int? minFeeMinor,
    int? maxFeeMinor,
  }) => FeeConfigModel(
    feeConfigId: 'cfg_standard_v1',
    version: 1,
    feeRateBps: feeRateBps,
    minFeeMinor: minFeeMinor,
    maxFeeMinor: maxFeeMinor,
    currency: 'EGP',
  );

  /// Mandatory Disclosures
  static const String mandatoryDisclosureEn =
      'The platform fee is paid separately and does not change your contribution or allocation amount.';
  static const String mandatoryDisclosureAr =
      'رسوم المنصة تدفع بشكل منفصل ولا تغير مبلغ مساهمتك أو استحقاقك.';

  static const String disclosureUnavailableEn =
      'Applicable fee according to current configuration.';
  static const String disclosureUnavailableAr =
      'الرسوم المطبقة وفقاً للإعدادات الحالية.';

  static const String mandatoryFeeDisclosureEn = mandatoryDisclosureEn;
  static const String mandatoryFeeDisclosureAr = mandatoryDisclosureAr;
  static const String feeConfigUnavailableEn = disclosureUnavailableEn;
  static const String feeConfigUnavailableAr = disclosureUnavailableAr;
}

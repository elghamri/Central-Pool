// Central Pool Contribution Tier Model (FM-04 Option A Ratified Baseline)
// Invariant: Product/catalog abstraction over scalar integer minor units (C).
// Zero floating-point financial authority; strictly currency-bound.

class ContributionTierModel {
  final String tierId;
  final int contributionMinor;
  final String currency;
  final String tierDisplayName;
  final String lifecycleState; // 'ACTIVE' | 'DISABLED' | 'DRAFT'
  final String? description;
  final String? badge;
  final int displayOrder;
  final bool isEnabled;

  const ContributionTierModel({
    required this.tierId,
    required this.contributionMinor,
    required this.currency,
    required this.tierDisplayName,
    this.lifecycleState = 'ACTIVE',
    this.description,
    this.badge,
    this.displayOrder = 0,
    this.isEnabled = true,
  });

  String get displayName => tierDisplayName;
  String get formattedAmount {
    final wholeUnits = (contributionMinor / 100).round();
    if (wholeUnits >= 1000) {
      final thousands = wholeUnits ~/ 1000;
      final remainder = (wholeUnits % 1000).toString().padLeft(3, '0');
      return '$thousands,$remainder $currency';
    }
    return '$wholeUnits $currency';
  }
  bool get isActive => isEnabled && lifecycleState == 'ACTIVE';
  bool get isDisabled => !isEnabled || lifecycleState == 'DISABLED';
  bool get isDraft => lifecycleState == 'DRAFT';

  factory ContributionTierModel.fromJson(Map<String, dynamic> json) {
    final enabled = json['isEnabled'] ?? json['is_enabled'] ?? (json['lifecycleState'] != 'DISABLED' && json['lifecycle_state'] != 'DISABLED');
    return ContributionTierModel(
      tierId: json['tierId'] as String? ?? json['tier_id'] as String? ?? '',
      contributionMinor: (json['contributionMinor'] ?? json['contribution_minor'] ?? 0) as int,
      currency: json['currency'] as String? ?? 'EGP',
      tierDisplayName: json['tierDisplayName'] as String? ?? json['tier_display_name'] as String? ?? json['displayName'] as String? ?? '',
      lifecycleState: json['lifecycleState'] as String? ?? json['lifecycle_state'] as String? ?? 'ACTIVE',
      description: json['description'] as String?,
      badge: json['badge'] as String?,
      displayOrder: (json['displayOrder'] ?? json['display_order'] ?? 0) as int,
      isEnabled: enabled is bool ? enabled : true,
    );
  }

  Map<String, dynamic> toJson() => {
    'tier_id': tierId,
    'contribution_minor': contributionMinor,
    'currency': currency,
    'tier_display_name': tierDisplayName,
    'lifecycle_state': lifecycleState,
    'description': description,
    'badge': badge,
    'display_order': displayOrder,
    'is_enabled': isEnabled,
  };

  /// Exactly five ratified production contribution tiers in EGP (FM-04 Ratified Baseline).
  static const List<ContributionTierModel> approvedProductionTiers = [
    ContributionTierModel(
      tierId: 'tier_500',
      contributionMinor: 50000,
      currency: 'EGP',
      tierDisplayName: '500 EGP',
      displayOrder: 1,
      description: '500 EGP per month',
    ),
    ContributionTierModel(
      tierId: 'tier_1000',
      contributionMinor: 100000,
      currency: 'EGP',
      tierDisplayName: '1,000 EGP',
      displayOrder: 2,
      badge: 'MOST_POPULAR',
      description: '1,000 EGP per month',
    ),
    ContributionTierModel(
      tierId: 'tier_1500',
      contributionMinor: 150000,
      currency: 'EGP',
      tierDisplayName: '1,500 EGP',
      displayOrder: 3,
      description: '1,500 EGP per month',
    ),
    ContributionTierModel(
      tierId: 'tier_2500',
      contributionMinor: 250000,
      currency: 'EGP',
      tierDisplayName: '2,500 EGP',
      displayOrder: 4,
      description: '2,500 EGP per month',
    ),
    ContributionTierModel(
      tierId: 'tier_5000',
      contributionMinor: 500000,
      currency: 'EGP',
      tierDisplayName: '5,000 EGP',
      displayOrder: 5,
      description: '5,000 EGP per month',
    ),
  ];

  static List<ContributionTierModel> get activeProductionTiers =>
      approvedProductionTiers.where((t) => t.isActive).toList();

  static ContributionTierModel? findByContributionMinor(int minor, {String currency = 'EGP'}) {
    for (final tier in approvedProductionTiers) {
      if (tier.contributionMinor == minor && tier.currency == currency) {
        return tier;
      }
    }
    return null;
  }

  static ContributionTierModel? findByTierId(String tierId) {
    for (final tier in approvedProductionTiers) {
      if (tier.tierId == tierId || tier.tierId == 'tier_egp_${tierId.replaceAll('tier_', '')}') {
        return tier;
      }
    }
    return null;
  }

  static bool isApprovedTier(int minor, {String currency = 'EGP'}) {
    return findByContributionMinor(minor, currency: currency) != null;
  }
}

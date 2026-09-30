import '../models/funding_models.dart';

/// Sealed state hierarchy for Member Funding & Payout Lifecycle (Slice 4).
abstract class FundingState {
  const FundingState();
}

/// Initial or active loading state.
class FundingLoading extends FundingState {
  final String message;

  const FundingLoading({this.message = 'Loading funding lifecycle and allocation state...'});
}

/// Fully resolved funding lifecycle state.
class FundingLoaded extends FundingState {
  final FundingOverview overview;
  final int currentViewIndex; // 0 = Overview, 1 = Eligibility, 2 = Allocation, 3 = Tracker, 4 = Settlement, 5 = Obligation, 6 = Audit

  const FundingLoaded({
    required this.overview,
    this.currentViewIndex = 0,
  });

  FundingLoaded copyWith({
    FundingOverview? overview,
    int? currentViewIndex,
  }) {
    return FundingLoaded(
      overview: overview ?? this.overview,
      currentViewIndex: currentViewIndex ?? this.currentViewIndex,
    );
  }
}

/// Error state when funding lifecycle records cannot be loaded.
class FundingError extends FundingState {
  final String errorMessage;
  final String? correlationId;
  final bool isRetryable;

  const FundingError({
    required this.errorMessage,
    this.correlationId,
    this.isRetryable = true,
  });
}

/// Empty state when no funding cycle or allocation exists for member.
class FundingEmpty extends FundingState {
  final String message;

  const FundingEmpty({
    this.message = 'No active cooperative allocation found for your member profile.',
  });
}

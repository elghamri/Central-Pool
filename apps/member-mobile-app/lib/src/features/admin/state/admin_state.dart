import '../models/admin_models.dart';

/// Sealed State Hierarchy for Business Admin Console (Slice 5).
abstract class AdminState {
  const AdminState();
}

/// Loading state for the admin module.
class AdminLoading extends AdminState {
  final String message;

  const AdminLoading({this.message = 'Loading organization metrics and administrative state...'});
}

/// Loaded state with complete operational records.
class AdminLoaded extends AdminState {
  final AdminOrgOverview overview;
  final AdminOrgProfile profile;
  final List<AdminMemberListItem> members;
  final List<AdminMemberListItem> filteredMembers;
  final List<AdminCycleSummary> cycles;
  final AdminTreasuryOverview treasury;
  final AdminMemberListItem? selectedMember;
  final AdminCycleSummary? selectedCycle;
  final int activeTab; // 0 = Overview, 1 = Members, 2 = Cycles, 3 = Treasury, 4 = Profile
  final bool isActionInProgress;
  final String? actionMessage;
  final String searchQuery;
  final String kycFilter;

  const AdminLoaded({
    required this.overview,
    required this.profile,
    required this.members,
    required this.filteredMembers,
    required this.cycles,
    required this.treasury,
    this.selectedMember,
    this.selectedCycle,
    this.activeTab = 0,
    this.isActionInProgress = false,
    this.actionMessage,
    this.searchQuery = '',
    this.kycFilter = 'ALL',
  });

  AdminLoaded copyWith({
    AdminOrgOverview? overview,
    AdminOrgProfile? profile,
    List<AdminMemberListItem>? members,
    List<AdminMemberListItem>? filteredMembers,
    List<AdminCycleSummary>? cycles,
    AdminTreasuryOverview? treasury,
    AdminMemberListItem? selectedMember,
    bool clearSelectedMember = false,
    AdminCycleSummary? selectedCycle,
    bool clearSelectedCycle = false,
    int? activeTab,
    bool? isActionInProgress,
    String? actionMessage,
    String? searchQuery,
    String? kycFilter,
  }) {
    return AdminLoaded(
      overview: overview ?? this.overview,
      profile: profile ?? this.profile,
      members: members ?? this.members,
      filteredMembers: filteredMembers ?? this.filteredMembers,
      cycles: cycles ?? this.cycles,
      treasury: treasury ?? this.treasury,
      selectedMember: clearSelectedMember ? null : (selectedMember ?? this.selectedMember),
      selectedCycle: clearSelectedCycle ? null : (selectedCycle ?? this.selectedCycle),
      activeTab: activeTab ?? this.activeTab,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      actionMessage: actionMessage ?? this.actionMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      kycFilter: kycFilter ?? this.kycFilter,
    );
  }
}

/// Error state when admin data cannot be loaded.
class AdminError extends AdminState {
  final String errorMessage;
  final String? correlationId;
  final bool isRetryable;

  const AdminError({
    required this.errorMessage,
    this.correlationId,
    this.isRetryable = true,
  });
}

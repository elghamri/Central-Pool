import 'package:flutter/foundation.dart';

/// Commercial lifecycle & operational readiness state machine.
enum CommercialPlatformState {
  development,
  pilot,
  preProduction,
  commercialPendingExternalApproval,
  commercialReady,
  commercialActive,
  suspended,
  emergencyLockdown;

  String get displayName {
    switch (this) {
      case CommercialPlatformState.development:
        return 'Development (Local Sandbox)';
      case CommercialPlatformState.pilot:
        return 'Controlled Field Pilot';
      case CommercialPlatformState.preProduction:
        return 'Commercial Pre-Production';
      case CommercialPlatformState.commercialPendingExternalApproval:
        return 'Commercial (Pending Partner Sign-Off)';
      case CommercialPlatformState.commercialReady:
        return 'Commercial Ready (Staged)';
      case CommercialPlatformState.commercialActive:
        return 'Commercial Active (Live Money)';
      case CommercialPlatformState.suspended:
        return 'Operationally Suspended';
      case CommercialPlatformState.emergencyLockdown:
        return 'Emergency Financial Lockdown';
    }
  }

  bool get isRealMoneyPermitted => this == CommercialPlatformState.commercialActive;
  bool get isLockdownActive => this == CommercialPlatformState.emergencyLockdown;
}

/// External dependency lifecycle status enumeration.
enum ExternalDependencyState {
  notStarted,
  requested,
  received,
  underReview,
  evidencePending,
  verified,
  rejected,
  expired,
  revoked;

  bool get isVerified => this == ExternalDependencyState.verified;
}

/// Evidence status enumeration for Phase 39/40 evidence intake registry.
enum EvidenceStatus {
  notStarted,
  notSubmitted,
  submitted,
  requested,
  received,
  underReview,
  verified,
  rejected,
  expired,
  revoked;

  bool get isVerified => this == EvidenceStatus.verified;
}

/// Phase 41 Strict Evidence Lifecycle State Machine.
enum Phase41EvidenceLifecycleState {
  evidencePending,
  evidenceSubmitted,
  hashVerified,
  issuerVerified,
  independentReview,
  approved,
  activationEligible,
  rejected,
  expired,
  revoked,
  superseded,
  hashMismatch,
  issuerUnverified,
  reviewFailed;

  bool get isTerminalOrRejected =>
      this == Phase41EvidenceLifecycleState.rejected ||
      this == Phase41EvidenceLifecycleState.expired ||
      this == Phase41EvidenceLifecycleState.revoked ||
      this == Phase41EvidenceLifecycleState.superseded ||
      this == Phase41EvidenceLifecycleState.hashMismatch ||
      this == Phase41EvidenceLifecycleState.issuerUnverified ||
      this == Phase41EvidenceLifecycleState.reviewFailed;

  bool get isActivationEligible => this == Phase41EvidenceLifecycleState.activationEligible;
}

/// Phase 42 Production Checklist Status Enumeration.
enum ProductionChecklistStatus {
  blocked,
  pending,
  submitted,
  verified,
  approved,
  expired,
  revoked,
  rejected,
  superseded,
  passed;

  bool get isSatisfied => this == ProductionChecklistStatus.passed || this == ProductionChecklistStatus.approved || this == ProductionChecklistStatus.verified;
}

/// Phase 42 Controlled Go-Live 20-Step Activation Sequence.
enum Phase42ActivationWorkflowStep {
  step01FreezeDeploymentCandidate,
  step02CaptureFingerprint,
  step03CaptureFinancialIntegritySnapshot,
  step04VerifyExternalEvidence,
  step05VerifyProductionConfig,
  step06VerifySecretsReferences,
  step07VerifyWebhookSecurity,
  step08VerifyKycAmlConnectivity,
  step09VerifyBankFboConfig,
  step10RunFinancialRegressionSuite,
  step11RunAdversarialTests,
  step12RunBackupRestoreVerification,
  step13ConfirmMonitoringAlerting,
  step14FirstActivationRequest,
  step15IndependentSecondPersonApproval,
  step16GenerateActivationSnapshot,
  step17EnableProductionIfAllPassed,
  step18ExecuteFirstTransactionValidation,
  step19PostActivationMonitoring,
  step20AutomaticLockdownOnFailure;
}

/// Phase 43 Incident Severity Enumeration.
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  bool get isCritical => this == IncidentSeverity.critical;
}

/// Phase 43 Incident Status Enumeration.
enum IncidentStatus {
  open,
  investigating,
  mitigated,
  resolved;

  bool get isResolved => this == IncidentStatus.resolved;
}

/// Phase 43 Deployment Environment Matrix Classification.
enum DeploymentEnvironmentType {
  local,
  development,
  staging,
  nonMoneyPilot,
  production;

  bool get isProduction => this == DeploymentEnvironmentType.production;
  bool get isNonMoneyPilot => this == DeploymentEnvironmentType.nonMoneyPilot;
}

/// Phase 43 Operational Incident Model.
@immutable
class OperationalIncident {
  final String id;
  final String title;
  final String affectedSubsystem;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String assignedOperator;
  final String remediationAction;
  final DateTime timestamp;
  final DateTime? resolvedAt;

  const OperationalIncident({
    required this.id,
    required this.title,
    required this.affectedSubsystem,
    required this.severity,
    required this.status,
    required this.assignedOperator,
    required this.remediationAction,
    required this.timestamp,
    this.resolvedAt,
  });
}

/// Phase 43 Non-Money Pilot Simulation Record.
@immutable
class NonMoneyPilotSimulationRecord {
  final String simulationId;
  final String circleId;
  final int period;
  final int totalContributedMinor;
  final int totalDisbursedMinor;
  final bool isSimulated; // MUST BE TRUE
  final DateTime timestamp;
  final int reconciliationDeltaMinor; // MUST BE 0

  const NonMoneyPilotSimulationRecord({
    required this.simulationId,
    required this.circleId,
    required this.period,
    required this.totalContributedMinor,
    required this.totalDisbursedMinor,
    this.isSimulated = true,
    required this.timestamp,
    this.reconciliationDeltaMinor = 0,
  });

  bool get isBalanced => reconciliationDeltaMinor == 0 && totalContributedMinor == totalDisbursedMinor;
}

/// Phase 42 Production Checklist Item Model.
@immutable
class ProductionChecklistItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final ProductionChecklistStatus status;
  final bool isBlocking;
  final String? notes;
  final DateTime? updatedAt;

  const ProductionChecklistItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    this.isBlocking = true,
    this.notes,
    this.updatedAt,
  });
}

/// Issuer Verification State.
enum IssuerVerificationState {
  issuerDeclared,
  manualVerificationRequired,
  issuerVerified,
  issuerRejected;

  bool get isVerified => this == IssuerVerificationState.issuerVerified;
}

/// Dual-Control Role Assignment for multi-party approval.
enum DualControlRole {
  generalCounsel,
  complianceOfficer,
  finOpsLead,
  securityOfficer,
  riskManager,
  executiveDirector;
}

/// Explicit Evidence Approval State.
enum EvidenceApprovalStatus {
  pending,
  approved,
  rejected;

  bool get isApproved => this == EvidenceApprovalStatus.approved;
}

/// Evidence environment classification to prevent demo/test/sandbox contamination.
enum EvidenceEnvironment {
  demo,
  test,
  sandbox,
  pilot,
  production;

  bool get isProduction => this == EvidenceEnvironment.production;
}

/// Dual-Control / Multi-Person activation state machine.
enum DualControlActivationState {
  notRequested,
  requested,
  firstApprovalComplete,
  underReview,
  approved,
  rejected,
  activated,
  revoked;

  bool get isApproved => this == DualControlActivationState.approved;
  bool get isActivated => this == DualControlActivationState.activated;
}

/// Bank / ODFI integration readiness status enumeration.
enum BankIntegrationStatus {
  unconfigured,
  configuredNotVerified,
  verifiedSandbox,
  productionPending,
  productionVerified;

  bool get isProductionVerified => this == BankIntegrationStatus.productionVerified;
}

/// Commercial Activation Gate evaluation decision.
enum CommercialGateDecision {
  commercialActivationBlocked,
  commercialActivationEligible;

  bool get isEligible => this == CommercialGateDecision.commercialActivationEligible;
}

/// KYC / AML compliance status enumeration.
enum KycVerificationStatus {
  none,
  notVerified,
  pending,
  approved,
  verified,
  failed,
  rejected,
  expired,
  manualReviewRequired,
  reviewRequired;

  bool get isEligibleForFinancialOperations =>
      this == KycVerificationStatus.approved || this == KycVerificationStatus.verified;
}

/// Dual-Control Activation Record enforcing two-person / dual-approver rule.
@immutable
class DualControlActivationRecord {
  final String requestId;
  final String requestedBy;
  final String? approvedBy; // Approver 1
  final String? secondApprovedBy; // Approver 2 (Optional / Multi-approver)
  final DualControlRole? approver1Role;
  final DualControlRole? approver2Role;
  final DualControlActivationState state;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? secondApprovedAt;
  final DateTime? activatedAt;
  final String reason;
  final String activationVersion;
  final List<String> evidenceSnapshot;
  final String configurationHash;

  const DualControlActivationRecord({
    required this.requestId,
    required this.requestedBy,
    this.approvedBy,
    this.secondApprovedBy,
    this.approver1Role,
    this.approver2Role,
    this.state = DualControlActivationState.requested,
    required this.requestedAt,
    this.approvedAt,
    this.secondApprovedAt,
    this.activatedAt,
    required this.reason,
    required this.activationVersion,
    required this.evidenceSnapshot,
    required this.configurationHash,
  });

  /// Evaluates whether the two-person rule is strictly satisfied (requester != approvers).
  bool get isDualControlSatisfied {
    final validState = state == DualControlActivationState.approved || state == DualControlActivationState.activated;
    if (!validState || approvedBy == null || approvedBy!.isEmpty) {
      return false;
    }
    // Requester must not be approver
    if (requestedBy == approvedBy) {
      return false;
    }
    // If second approver exists, it must not equal requester or approver 1
    if (secondApprovedBy != null && secondApprovedBy!.isNotEmpty) {
      if (secondApprovedBy == requestedBy || secondApprovedBy == approvedBy) {
        return false;
      }
    }
    return true;
  }

  DualControlActivationRecord copyWith({
    DualControlActivationState? state,
    String? approvedBy,
    String? secondApprovedBy,
    DualControlRole? approver1Role,
    DualControlRole? approver2Role,
    DateTime? approvedAt,
    DateTime? secondApprovedAt,
    DateTime? activatedAt,
  }) {
    return DualControlActivationRecord(
      requestId: requestId,
      requestedBy: requestedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      secondApprovedBy: secondApprovedBy ?? this.secondApprovedBy,
      approver1Role: approver1Role ?? this.approver1Role,
      approver2Role: approver2Role ?? this.approver2Role,
      state: state ?? this.state,
      requestedAt: requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      secondApprovedAt: secondApprovedAt ?? this.secondApprovedAt,
      activatedAt: activatedAt ?? this.activatedAt,
      reason: reason,
      activationVersion: activationVersion,
      evidenceSnapshot: evidenceSnapshot,
      configurationHash: configurationHash,
    );
  }
}

/// Individual External Dependency Record.
@immutable
class ExternalDependencyRecord {
  final String id; // e.g. EXT-01
  final String name;
  final String category; // Legal, Banking, Custody, Payments, KYC/AML, Security, Insurance
  final ExternalDependencyState status;
  final String owner;
  final String requiredEvidence;
  final String? evidenceReference;
  final DateTime? verificationTimestamp;
  final bool isBlocking;

  const ExternalDependencyRecord({
    required this.id,
    required this.name,
    required this.category,
    this.status = ExternalDependencyState.notStarted,
    required this.owner,
    required this.requiredEvidence,
    this.evidenceReference,
    this.verificationTimestamp,
    this.isBlocking = true,
  });

  ExternalDependencyRecord copyWith({
    ExternalDependencyState? status,
    String? evidenceReference,
    DateTime? verificationTimestamp,
  }) {
    return ExternalDependencyRecord(
      id: id,
      name: name,
      category: category,
      status: status ?? this.status,
      owner: owner,
      requiredEvidence: requiredEvidence,
      evidenceReference: evidenceReference ?? this.evidenceReference,
      verificationTimestamp: verificationTimestamp ?? this.verificationTimestamp,
      isBlocking: isBlocking,
    );
  }
}

/// Authoritative External Evidence Record for Phase 39/40/41/42/43 Evidence Intake Control.
@immutable
class ExternalEvidenceRecord {
  final String id; // EXT-01 .. EXT-07
  final String name;
  final String category;
  final EvidenceStatus status;
  final Phase41EvidenceLifecycleState lifecycleState;
  final IssuerVerificationState issuerState;
  final EvidenceApprovalStatus approvalStatus;
  final String requiredEvidence;
  final String? evidenceReference;
  final String? evidenceHash;
  final String? issuer;
  final String? issuerType;
  final DateTime? issuedAt;
  final DateTime? effectiveDate;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final String? submittedBy;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? verificationMethod;
  final EvidenceEnvironment environment;
  final String? notes;
  final String? rejectionReason;
  final String? supersedesEvidenceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isBlocking;

  const ExternalEvidenceRecord({
    required this.id,
    required this.name,
    required this.category,
    this.status = EvidenceStatus.notStarted,
    this.lifecycleState = Phase41EvidenceLifecycleState.evidencePending,
    this.issuerState = IssuerVerificationState.issuerDeclared,
    this.approvalStatus = EvidenceApprovalStatus.pending,
    required this.requiredEvidence,
    this.evidenceReference,
    this.evidenceHash,
    this.issuer,
    this.issuerType,
    this.issuedAt,
    this.effectiveDate,
    this.expiresAt,
    this.submittedAt,
    this.submittedBy,
    this.reviewedAt,
    this.reviewedBy,
    this.verifiedAt,
    this.verifiedBy,
    this.verificationMethod,
    this.environment = EvidenceEnvironment.production,
    this.notes,
    this.rejectionReason,
    this.supersedesEvidenceId,
    this.createdAt,
    this.updatedAt,
    this.isBlocking = true,
  });

  /// Evaluates whether the evidence genuinely satisfies production commercial activation.
  bool get isProductionVerified {
    // Must be verified status and not rejected
    final isStateVerified = status == EvidenceStatus.verified && approvalStatus != EvidenceApprovalStatus.rejected;
    final isProd = environment == EvidenceEnvironment.production;
    final hasValidHash = evidenceHash != null && evidenceHash!.isNotEmpty && !evidenceHash!.startsWith('md5:');
    final hasVerifier = verifiedAt != null;

    // Check expiration if expiresAt is specified
    final isNotExpired = expiresAt == null || expiresAt!.isAfter(DateTime.now());

    return isStateVerified && isProd && hasValidHash && hasVerifier && isNotExpired;
  }

  ExternalEvidenceRecord copyWith({
    EvidenceStatus? status,
    Phase41EvidenceLifecycleState? lifecycleState,
    IssuerVerificationState? issuerState,
    EvidenceApprovalStatus? approvalStatus,
    String? evidenceReference,
    String? evidenceHash,
    String? issuer,
    String? issuerType,
    DateTime? issuedAt,
    DateTime? effectiveDate,
    DateTime? expiresAt,
    DateTime? submittedAt,
    String? submittedBy,
    DateTime? reviewedAt,
    String? reviewedBy,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? verificationMethod,
    EvidenceEnvironment? environment,
    String? notes,
    String? rejectionReason,
    String? supersedesEvidenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBlocking,
  }) {
    return ExternalEvidenceRecord(
      id: id,
      name: name,
      category: category,
      status: status ?? this.status,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      issuerState: issuerState ?? this.issuerState,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      requiredEvidence: requiredEvidence,
      evidenceReference: evidenceReference ?? this.evidenceReference,
      evidenceHash: evidenceHash ?? this.evidenceHash,
      issuer: issuer ?? this.issuer,
      issuerType: issuerType ?? this.issuerType,
      issuedAt: issuedAt ?? this.issuedAt,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expiresAt: expiresAt ?? this.expiresAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      environment: environment ?? this.environment,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      supersedesEvidenceId: supersedesEvidenceId ?? this.supersedesEvidenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBlocking: isBlocking ?? this.isBlocking,
    );
  }
}

/// Comprehensive Phase 40/41/42/43 Commercial Activation Snapshot Model.
@immutable
class Phase40ActivationSnapshot {
  final String snapshotId;
  final DateTime timestamp;
  final String appVersion;
  final String backendVersion;
  final String dbMigrationVersion;
  final String financialCoreChecksum;
  final String testStatus;
  final String invariantStatus;
  final String reconciliationStatus;
  final Map<String, String> externalDependencyStatuses;
  final Map<String, String> evidenceHashes;
  final String securityStatus;
  final String observabilityStatus;
  final String disasterRecoveryStatus;
  final String dualControlStatus;
  final CommercialGateDecision activationDecision;

  const Phase40ActivationSnapshot({
    required this.snapshotId,
    required this.timestamp,
    required this.appVersion,
    required this.backendVersion,
    required this.dbMigrationVersion,
    required this.financialCoreChecksum,
    required this.testStatus,
    required this.invariantStatus,
    required this.reconciliationStatus,
    required this.externalDependencyStatuses,
    required this.evidenceHashes,
    required this.securityStatus,
    required this.observabilityStatus,
    required this.disasterRecoveryStatus,
    required this.dualControlStatus,
    required this.activationDecision,
  });
}

/// Real-Money Kill Switch and 16-Point Commercial Readiness Gate (Fail-Closed).
@immutable
class CommercialGateConfiguration {
  final CommercialPlatformState platformState;
  final bool realMoneyEnabled; // MUST BE FALSE by default
  final bool isBankingPartnerApproved;
  final bool isPaymentProcessorLive;
  final bool isKycAmlLive;
  final bool isAmlOfacScreeningLive;
  final bool isLegalSignoffComplete;
  final bool isSecurityPenTestComplete;
  final bool isProductionInfrastructureApproved;
  final bool isReconciliationReadinessVerified;
  final bool isFboCustodyVerified;
  final bool isSecretsManagementVerified;
  final bool isWebhookSecurityVerified;
  final bool isObservabilityVerified;
  final bool isBackupRestoreVerified;
  final bool isEmergencyLockdownVerified;
  final bool isIncidentResponseReady;
  final bool isCustomerSupportReady;
  final bool isPrivacyTermsPublished;
  final String activeEnvironment; // 'dev', 'test', 'sandbox', 'pilot', 'staging', 'prod'
  final List<ExternalEvidenceRecord>? evidenceRecords;
  final DualControlActivationRecord? dualControlRecord;

  const CommercialGateConfiguration({
    this.platformState = CommercialPlatformState.preProduction,
    this.realMoneyEnabled = false,
    this.isBankingPartnerApproved = false,
    this.isPaymentProcessorLive = false,
    this.isKycAmlLive = false,
    this.isAmlOfacScreeningLive = false,
    this.isLegalSignoffComplete = false,
    this.isSecurityPenTestComplete = false,
    this.isProductionInfrastructureApproved = false,
    this.isReconciliationReadinessVerified = false,
    this.isFboCustodyVerified = false,
    this.isSecretsManagementVerified = false,
    this.isWebhookSecurityVerified = false,
    this.isObservabilityVerified = false,
    this.isBackupRestoreVerified = false,
    this.isEmergencyLockdownVerified = false,
    this.isIncidentResponseReady = false,
    this.isCustomerSupportReady = false,
    this.isPrivacyTermsPublished = false,
    this.activeEnvironment = 'staging',
    this.evidenceRecords,
    this.dualControlRecord,
  });

  /// Evaluates the 16-point mandatory commercial activation gate (FAILS CLOSED).
  CommercialGateDecision evaluateActivationGate() {
    // If evidence records are provided, every blocking dependency must be genuinely production verified
    if (evidenceRecords != null && evidenceRecords!.isNotEmpty) {
      final hasUnverifiedEvidence = evidenceRecords!.any((rec) => rec.isBlocking && !rec.isProductionVerified);
      if (hasUnverifiedEvidence) {
        return CommercialGateDecision.commercialActivationBlocked;
      }
    }

    // If dual-control record is provided, it must be validly approved with distinct person rule
    if (dualControlRecord != null && !dualControlRecord!.isDualControlSatisfied) {
      return CommercialGateDecision.commercialActivationBlocked;
    }

    final all16Passed = isLegalSignoffComplete &&
        isBankingPartnerApproved &&
        isFboCustodyVerified &&
        isPaymentProcessorLive &&
        isKycAmlLive &&
        isAmlOfacScreeningLive &&
        isSecretsManagementVerified &&
        isWebhookSecurityVerified &&
        isSecurityPenTestComplete &&
        isProductionInfrastructureApproved &&
        isReconciliationReadinessVerified &&
        isBackupRestoreVerified &&
        isIncidentResponseReady &&
        isCustomerSupportReady &&
        isPrivacyTermsPublished &&
        !platformState.isLockdownActive &&
        realMoneyEnabled &&
        activeEnvironment == 'prod';

    if (all16Passed) {
      return CommercialGateDecision.commercialActivationEligible;
    }
    return CommercialGateDecision.commercialActivationBlocked;
  }

  /// Evaluates whether real-money operations can execute.
  bool get canActivateRealMoney => evaluateActivationGate().isEligible;

  CommercialGateConfiguration copyWith({
    CommercialPlatformState? platformState,
    bool? realMoneyEnabled,
    bool? isBankingPartnerApproved,
    bool? isPaymentProcessorLive,
    bool? isKycAmlLive,
    bool? isAmlOfacScreeningLive,
    bool? isLegalSignoffComplete,
    bool? isSecurityPenTestComplete,
    bool? isProductionInfrastructureApproved,
    bool? isReconciliationReadinessVerified,
    bool? isFboCustodyVerified,
    bool? isSecretsManagementVerified,
    bool? isWebhookSecurityVerified,
    bool? isObservabilityVerified,
    bool? isBackupRestoreVerified,
    bool? isEmergencyLockdownVerified,
    bool? isIncidentResponseReady,
    bool? isCustomerSupportReady,
    bool? isPrivacyTermsPublished,
    String? activeEnvironment,
    List<ExternalEvidenceRecord>? evidenceRecords,
    DualControlActivationRecord? dualControlRecord,
  }) {
    return CommercialGateConfiguration(
      platformState: platformState ?? this.platformState,
      realMoneyEnabled: realMoneyEnabled ?? this.realMoneyEnabled,
      isBankingPartnerApproved: isBankingPartnerApproved ?? this.isBankingPartnerApproved,
      isPaymentProcessorLive: isPaymentProcessorLive ?? this.isPaymentProcessorLive,
      isKycAmlLive: isKycAmlLive ?? this.isKycAmlLive,
      isAmlOfacScreeningLive: isAmlOfacScreeningLive ?? this.isAmlOfacScreeningLive,
      isLegalSignoffComplete: isLegalSignoffComplete ?? this.isLegalSignoffComplete,
      isSecurityPenTestComplete: isSecurityPenTestComplete ?? this.isSecurityPenTestComplete,
      isProductionInfrastructureApproved:
          isProductionInfrastructureApproved ?? this.isProductionInfrastructureApproved,
      isReconciliationReadinessVerified:
          isReconciliationReadinessVerified ?? this.isReconciliationReadinessVerified,
      isFboCustodyVerified: isFboCustodyVerified ?? this.isFboCustodyVerified,
      isSecretsManagementVerified: isSecretsManagementVerified ?? this.isSecretsManagementVerified,
      isWebhookSecurityVerified: isWebhookSecurityVerified ?? this.isWebhookSecurityVerified,
      isObservabilityVerified: isObservabilityVerified ?? this.isObservabilityVerified,
      isBackupRestoreVerified: isBackupRestoreVerified ?? this.isBackupRestoreVerified,
      isEmergencyLockdownVerified: isEmergencyLockdownVerified ?? this.isEmergencyLockdownVerified,
      isIncidentResponseReady: isIncidentResponseReady ?? this.isIncidentResponseReady,
      isCustomerSupportReady: isCustomerSupportReady ?? this.isCustomerSupportReady,
      isPrivacyTermsPublished: isPrivacyTermsPublished ?? this.isPrivacyTermsPublished,
      activeEnvironment: activeEnvironment ?? this.activeEnvironment,
      evidenceRecords: evidenceRecords ?? this.evidenceRecords,
      dualControlRecord: dualControlRecord ?? this.dualControlRecord,
    );
  }
}

/// Provider-neutral payment intent model.
@immutable
class CommercialPaymentIntent {
  final String id;
  final String idempotencyKey;
  final String correlationId;
  final String circleId;
  final String memberId;
  final int period;
  final int amountMinor;
  final String status; // 'created', 'processing', 'succeeded', 'failed', 'returned'
  final DateTime timestamp;
  final bool isRealMoney;

  const CommercialPaymentIntent({
    required this.id,
    required this.idempotencyKey,
    required this.correlationId,
    required this.circleId,
    required this.memberId,
    required this.period,
    required this.amountMinor,
    this.status = 'created',
    required this.timestamp,
    this.isRealMoney = false,
  });
}

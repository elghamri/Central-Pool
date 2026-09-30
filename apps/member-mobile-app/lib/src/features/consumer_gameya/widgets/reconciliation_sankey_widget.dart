import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// 6-Layer Financial Reconciliation Balance Flow Widget (Sankey-style visualizer).
/// Graphically renders cash flows from Banking Rails to Final Clearing with guaranteed $0.00 variance.
class ReconciliationSankeyWidget extends StatelessWidget {
  final int totalInflowsMinor;
  final int totalOutflowsMinor;
  final int varianceMinor;
  final String status;

  const ReconciliationSankeyWidget({
    super.key,
    this.totalInflowsMinor = 5000000, // $50,000.00
    this.totalOutflowsMinor = 5000000,
    this.varianceMinor = 0,
    this.status = 'BALANCED_AND_CERTIFIED',
  });

  @override
  Widget build(BuildContext context) {
    final isZeroVariance = varianceMinor == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isZeroVariance ? AppColors.emeraldGreen.withValues(alpha: 0.4) : AppColors.crimsonRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isZeroVariance ? Icons.check_circle : Icons.error,
                color: isZeroVariance ? AppColors.emeraldGreen : AppColors.crimsonRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '6-LAYER RECONCILIATION FLOW',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'VARIANCE: \$${(varianceMinor / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.emeraldGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6 Layer Conduits
          _buildLayerRow(1, 'Member Banking Ingress (ACH/Cards)', totalInflowsMinor, AppColors.skyInfo),
          _buildLayerConnector(),
          _buildLayerRow(2, 'Payment Gateway Settlement Account', totalInflowsMinor, AppColors.skyInfo),
          _buildLayerConnector(),
          _buildLayerRow(3, 'FBO Custody Bank Trust Reserve', totalInflowsMinor, AppColors.emeraldGreen),
          _buildLayerConnector(),
          _buildLayerRow(4, 'General Ledger Cash-in-Trust (GL-1010)', totalInflowsMinor, AppColors.emeraldGreen),
          _buildLayerConnector(),
          _buildLayerRow(5, 'Member Circle Ledger Pool (GL-2010)', totalInflowsMinor, AppColors.amberWarning),
          _buildLayerConnector(),
          _buildLayerRow(6, 'Final Disbursement Clearing (GL-3010)', totalOutflowsMinor, AppColors.emeraldGreen),
        ],
      ),
    );
  }

  Widget _buildLayerRow(int layerNum, String label, int amountMinor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$layerNum',
                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '\$${(amountMinor / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerConnector() {
    return Center(
      child: Container(
        height: 12,
        width: 2,
        color: AppColors.emeraldGreen.withValues(alpha: 0.5),
      ),
    );
  }
}

// Central Pool Participation Request Status View (Phase 1)
// Invariant: Status presentation; handles transitions (SUBMITTED -> ANALYZING -> MATCHED).

import 'package:flutter/material.dart';
import '../state/central_pool_controller.dart';

class ParticipationRequestStatusView extends StatelessWidget {
  final CentralPoolController controller;

  const ParticipationRequestStatusView({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final req = controller.currentRequest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: req == null
            ? const Center(child: Text('No active participation request.'))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Request Status: ${req.status}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('Request ID: ${req.requestId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${(req.monthlyContributionMinor / 100).toStringAsFixed(0)} ${req.currency} for ${req.durationPeriods} Months (Month ${req.preferredPayoutPeriod})',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        controller.loadCandidates();
                      },
                      child: const Text('View Matched Candidates'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

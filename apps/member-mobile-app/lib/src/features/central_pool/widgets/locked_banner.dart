// Central Pool Locked Banner Widget (Step 11/12/13)
// PROVENANCE & SEMANTIC DEFINITION:
// - Renders a visible safety alert banner when system lockdown is active.
// - Client-side safety behavior to disable transactional UI and inform members.
// - NOT a backend circuit-breaker.

import 'package:flutter/material.dart';
import '../models/system_lockdown_model.dart';

class LockedBanner extends StatelessWidget {
  final SystemLockdownModel? lockdown;
  final bool isLocked;
  final String? customMessage;

  const LockedBanner({
    Key? key,
    this.lockdown,
    this.isLocked = false,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final active = isLocked || (lockdown?.isLocked ?? false);
    if (!active) return const SizedBox.shrink();

    final reason = customMessage ?? lockdown?.reason ?? 'System operations are temporarily paused by administration.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SYSTEM LOCKDOWN ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'READ ONLY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

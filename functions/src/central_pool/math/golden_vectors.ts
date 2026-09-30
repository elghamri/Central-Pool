/**
 * Central Pool Golden Vector Definitions & Provenance Metadata
 * Reference Baseline: services/cooperative-service/allocation_mathematical_kernel.go
 */

import { GoldenVectorStandard, GoldenVectorEdge, GoldenVectorInvalid } from './math_types';

export const GOLDEN_VECTORS_STANDARD: GoldenVectorStandard[] = [
  { id: 'GV-01', N: 3, C: 500, E: 1500, totalPot: 4500, centerPeriod: 2, centerPayout: 1500, splitPayout: 750, pairs: [[1, 3]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-02', N: 3, C: 10000, E: 30000, totalPot: 90000, centerPeriod: 2, centerPayout: 30000, splitPayout: 15000, pairs: [[1, 3]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-03', N: 3, C: 25000, E: 75000, totalPot: 225000, centerPeriod: 2, centerPayout: 75000, splitPayout: 37500, pairs: [[1, 3]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-04', N: 3, C: 50000, E: 150000, totalPot: 450000, centerPeriod: 2, centerPayout: 150000, splitPayout: 75000, pairs: [[1, 3]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-05', N: 3, C: 100000, E: 300000, totalPot: 900000, centerPeriod: 2, centerPayout: 300000, splitPayout: 150000, pairs: [[1, 3]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },

  { id: 'GV-06', N: 5, C: 500, E: 2500, totalPot: 12500, centerPeriod: 3, centerPayout: 2500, splitPayout: 1250, pairs: [[1, 5], [2, 4]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-07', N: 5, C: 10000, E: 50000, totalPot: 250000, centerPeriod: 3, centerPayout: 50000, splitPayout: 25000, pairs: [[1, 5], [2, 4]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-08', N: 5, C: 25000, E: 125000, totalPot: 625000, centerPeriod: 3, centerPayout: 125000, splitPayout: 62500, pairs: [[1, 5], [2, 4]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-09', N: 5, C: 50000, E: 250000, totalPot: 1250000, centerPeriod: 3, centerPayout: 250000, splitPayout: 125000, pairs: [[1, 5], [2, 4]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-10', N: 5, C: 100000, E: 500000, totalPot: 2500000, centerPeriod: 3, centerPayout: 500000, splitPayout: 250000, pairs: [[1, 5], [2, 4]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },

  { id: 'GV-11', N: 7, C: 500, E: 3500, totalPot: 24500, centerPeriod: 4, centerPayout: 3500, splitPayout: 1750, pairs: [[1, 7], [2, 6], [3, 5]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-12', N: 7, C: 10000, E: 70000, totalPot: 490000, centerPeriod: 4, centerPayout: 70000, splitPayout: 35000, pairs: [[1, 7], [2, 6], [3, 5]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-13', N: 7, C: 25000, E: 175000, totalPot: 1225000, centerPeriod: 4, centerPayout: 175000, splitPayout: 87500, pairs: [[1, 7], [2, 6], [3, 5]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-14', N: 7, C: 50000, E: 350000, totalPot: 2450000, centerPeriod: 4, centerPayout: 350000, splitPayout: 175000, pairs: [[1, 7], [2, 6], [3, 5]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-15', N: 7, C: 100000, E: 700000, totalPot: 4900000, centerPeriod: 4, centerPayout: 700000, splitPayout: 350000, pairs: [[1, 7], [2, 6], [3, 5]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },

  { id: 'GV-16', N: 10, C: 500, E: 5000, totalPot: 50000, centerPeriod: null, centerPayout: null, splitPayout: 2500, pairs: [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-17', N: 10, C: 10000, E: 100000, totalPot: 1000000, centerPeriod: null, centerPayout: null, splitPayout: 50000, pairs: [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-18', N: 10, C: 25000, E: 250000, totalPot: 2500000, centerPeriod: null, centerPayout: null, splitPayout: 125000, pairs: [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-19', N: 10, C: 50000, E: 500000, totalPot: 5000000, centerPeriod: null, centerPayout: null, splitPayout: 250000, pairs: [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-20', N: 10, C: 100000, E: 1000000, totalPot: 10000000, centerPeriod: null, centerPayout: null, splitPayout: 500000, pairs: [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },

  { id: 'GV-21', N: 11, C: 500, E: 5500, totalPot: 60500, centerPeriod: 6, centerPayout: 5500, splitPayout: 2750, pairs: [[1, 11], [2, 10], [3, 9], [4, 8], [5, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-22', N: 11, C: 10000, E: 110000, totalPot: 1210000, centerPeriod: 6, centerPayout: 110000, splitPayout: 55000, pairs: [[1, 11], [2, 10], [3, 9], [4, 8], [5, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-23', N: 11, C: 25000, E: 275000, totalPot: 3025000, centerPeriod: 6, centerPayout: 275000, splitPayout: 137500, pairs: [[1, 11], [2, 10], [3, 9], [4, 8], [5, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-24', N: 11, C: 50000, E: 550000, totalPot: 6050000, centerPeriod: 6, centerPayout: 550000, splitPayout: 275000, pairs: [[1, 11], [2, 10], [3, 9], [4, 8], [5, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-25', N: 11, C: 100000, E: 1100000, totalPot: 12100000, centerPeriod: 6, centerPayout: 1100000, splitPayout: 550000, pairs: [[1, 11], [2, 10], [3, 9], [4, 8], [5, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },

  { id: 'GV-26', N: 12, C: 500, E: 6000, totalPot: 72000, centerPeriod: null, centerPayout: null, splitPayout: 3000, pairs: [[1, 12], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-27', N: 12, C: 10000, E: 120000, totalPot: 1440000, centerPeriod: null, centerPayout: null, splitPayout: 60000, pairs: [[1, 12], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-28', N: 12, C: 25000, E: 300000, totalPot: 3600000, centerPeriod: null, centerPayout: null, splitPayout: 150000, pairs: [[1, 12], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-29', N: 12, C: 50000, E: 600000, totalPot: 7200000, centerPeriod: null, centerPayout: null, splitPayout: 300000, pairs: [[1, 12], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' },
  { id: 'GV-30', N: 12, C: 100000, E: 1200000, totalPot: 14400000, centerPeriod: null, centerPayout: null, splitPayout: 600000, pairs: [[1, 12], [2, 11], [3, 10], [4, 9], [5, 8], [6, 7]], source: 'FROZEN_GO', sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go', sourceFunction: 'GenerateCycleScheduleMatrix' }
];

export const GOLDEN_VECTORS_EDGE: GoldenVectorEdge[] = [
  {
    id: 'GV-EDGE-01',
    description: 'Smallest valid contribution with even split',
    N: 4,
    C: 2,
    E: 8,
    totalPot: 32,
    centerPeriod: null,
    splitPayout: 4,
    source: 'FROZEN_GO',
    sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go'
  },
  {
    id: 'GV-EDGE-02',
    description: 'Maximum safe contribution capacity for N=12',
    N: 12,
    C: 62549994824590,
    E: 750599937895080,
    totalPot: 9007199254740960,
    centerPeriod: null,
    splitPayout: 375299968947540,
    source: 'CONTRACT_DERIVED'
  }
];

export const GOLDEN_VECTORS_INVALID: GoldenVectorInvalid[] = [
  {
    id: 'GV-INV-01',
    description: 'Odd entitlement 50/50 rejection (N=3, C=1 => E=3)',
    N: 3,
    C: 1,
    goNativeBehavior: 'primaryMinor=1, mirrorMinor=2 (floor/remainder split)',
    contractError: 'ODD_ENTITLEMENT_REJECTED',
    source: 'CONTRACT_DERIVED'
  },
  {
    id: 'GV-INV-02',
    description: 'Underflow member count (N=1)',
    N: 1,
    C: 500,
    goNativeError: 'ErrInvalidMemberCount: member count N must be >= 2',
    contractError: 'INVALID_MEMBER_COUNT',
    source: 'FROZEN_GO',
    sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go'
  },
  {
    id: 'GV-INV-03',
    description: 'Overflow duration periods (N=13)',
    N: 13,
    C: 500,
    contractError: 'INVALID_MEMBER_COUNT',
    source: 'CONTRACT_DERIVED'
  },
  {
    id: 'GV-INV-04',
    description: 'Zero contribution (C=0)',
    N: 5,
    C: 0,
    goNativeError: 'ErrInvalidPeriodicContribution: periodic contribution must be positive and non-zero',
    contractError: 'INVALID_PERIODIC_CONTRIBUTION',
    source: 'FROZEN_GO',
    sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go'
  },
  {
    id: 'GV-INV-05',
    description: 'Negative contribution (C=-500)',
    N: 5,
    C: -500,
    goNativeError: 'ErrInvalidPeriodicContribution: periodic contribution must be positive and non-zero',
    contractError: 'INVALID_PERIODIC_CONTRIBUTION',
    source: 'FROZEN_GO',
    sourceFile: 'services/cooperative-service/allocation_mathematical_kernel.go'
  },
  {
    id: 'GV-INV-06',
    description: 'Unsafe integer multiplication overflow (N=12, C=10^15)',
    N: 12,
    C: 1_000_000_000_000_000,
    contractError: 'SAFE_INTEGER_OVERFLOW',
    source: 'CONTRACT_DERIVED'
  }
];

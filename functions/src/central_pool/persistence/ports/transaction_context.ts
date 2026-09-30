/**
 * Transaction Context Interface
 * Provides abstract transaction boundary abstraction without leaking Firestore transaction details
 * and without implementing business allocation confirmation logic.
 */

export interface TransactionRunner {
  run<T>(updateFunction: (context: unknown) => Promise<T>): Promise<T>;
}

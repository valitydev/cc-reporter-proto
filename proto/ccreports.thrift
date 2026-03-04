namespace java dev.vality.ccreporter

/**
 * Reports are always built from CCR internal current-state tables.
 * UI receives source_query back in Report to render period and retry the same request.
 */

typedef string Timestamp
typedef i64 ReportID
typedef string FileID
typedef string URL
typedef string ContinuationToken

exception InvalidRequest {
  1: required list<string> errors
}

exception ReportNotFound {}
exception FileNotFound {}

exception BadContinuationToken {
  1: required string reason
}

enum ReportType {
  payments_csv
  withdrawals_csv
}

enum ReportStatus {
  pending
  processing
  created
  failed
  canceled
  timed_out
  expired
}

struct TimeRange {
  1: required Timestamp from_time
  2: required Timestamp to_time
}

/**
 * Case-insensitive partial search across ids and human-readable names.
 */
struct SearchTermFilter {
  1: optional string shop_or_wallet_term
  2: optional string provider_term
  3: optional string terminal_term
  4: optional string trx_term
}

struct PaymentsSourceQuery {
  1: required TimeRange time_range
  2: optional list<string> party_ids
  3: optional list<string> shop_ids
  4: optional list<string> provider_ids
  5: optional list<string> terminal_ids
  6: optional list<string> trx_ids
  7: optional list<string> currencies
  8: optional list<string> statuses
  9: optional SearchTermFilter search_term
}

struct WithdrawalsSourceQuery {
  1: required TimeRange time_range
  2: optional list<string> party_ids
  3: optional list<string> wallet_ids
  4: optional list<string> provider_ids
  5: optional list<string> terminal_ids
  6: optional list<string> trx_ids
  7: optional list<string> currencies
  8: optional list<string> statuses
  9: optional SearchTermFilter search_term
}

union ReportSourceQuery {
  1: PaymentsSourceQuery payments
  2: WithdrawalsSourceQuery withdrawals
}

struct CreateReportRequest {
  1: required ReportType report_type
  2: required ReportSourceQuery source_query
  3: optional string timezone
  4: optional string idempotency_key
}

struct FileSignature {
  1: required string md5
  2: required string sha256
}

struct FileMeta {
  1: required FileID file_id
  2: required string filename
  3: required string content_type
  4: required FileSignature signature
  5: optional i64 size_bytes
  6: required Timestamp created_at
}

struct ErrorInfo {
  1: required string code
  2: required string message
}

struct Report {
  1: required ReportID report_id
  2: required ReportType report_type
  3: required ReportSourceQuery source_query
  4: required Timestamp created_at
  5: optional Timestamp started_at
  6: optional Timestamp finished_at
  7: required ReportStatus status
  8: optional list<FileMeta> files
  9: optional ErrorInfo error
  10: optional i64 rows_count
  11: optional Timestamp data_window_fixed_at
  12: optional Timestamp expires_at
}

struct GetReportsRequest {
  1: optional list<ReportStatus> statuses
  2: optional list<ReportType> report_types
  3: optional Timestamp created_from
  4: optional Timestamp created_to
  5: optional ContinuationToken continuation_token
  6: optional i32 limit
}

struct GetReportsResponse {
  1: required list<Report> reports
  2: optional ContinuationToken continuation_token
}

service Reporting {

  /**
   * Server validates that report_type matches the selected ReportSourceQuery branch.
   * timezone controls CSV rendering timezone and defaults to UTC.
   */
  ReportID CreateReport(1: CreateReportRequest request) throws (
    1: InvalidRequest ex1
  )

  Report GetReport(1: ReportID report_id) throws (
    1: ReportNotFound ex1
  )

  GetReportsResponse GetReports(1: GetReportsRequest request) throws (
    1: InvalidRequest ex1,
    2: BadContinuationToken ex2
  )

  void CancelReport(1: ReportID report_id) throws (
    1: ReportNotFound ex1
  )

  /**
   * requested_expires_at is advisory; server clamps TTL by configured maximum.
   */
  URL GeneratePresignedUrl(1: FileID file_id, 2: optional Timestamp requested_expires_at) throws (
    1: FileNotFound ex1,
    2: InvalidRequest ex2
  )
}

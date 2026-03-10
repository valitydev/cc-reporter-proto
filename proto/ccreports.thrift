namespace java dev.vality.ccreporter

/**
 * Reports are always built from CCR internal current-state tables.
 * UI receives query back in Report to render period and retry the same request.
 */

/**
 * RFC 3339 timestamp in UTC.
 * Example: 2016-03-22T06:12:27Z
 */
typedef string Timestamp
typedef i64 ReportID
typedef string FileID
typedef string URL
/** Opaque pagination token. */
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
  payments
  withdrawals
}

enum FileType {
  csv
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
struct PaymentsSearchFilter {
  1: optional string shop_term
  2: optional string provider_term
  3: optional string terminal_term
  4: optional string trx_term
}

/**
 * Case-insensitive partial search across ids and human-readable names.
 */
struct WithdrawalsSearchFilter {
  1: optional string wallet_term
  2: optional string provider_term
  3: optional string terminal_term
  4: optional string trx_term
}

struct PaymentsQuery {
  1: required TimeRange time_range
  2: optional list<string> party_ids
  3: optional list<string> shop_ids
  4: optional list<string> provider_ids
  5: optional list<string> terminal_ids
  6: optional list<string> trx_ids
  7: optional list<string> currencies
  8: optional list<string> statuses
  9: optional PaymentsSearchFilter filter
}

struct WithdrawalsQuery {
  1: required TimeRange time_range
  2: optional list<string> party_ids
  3: optional list<string> wallet_ids
  4: optional list<string> provider_ids
  5: optional list<string> terminal_ids
  6: optional list<string> trx_ids
  7: optional list<string> currencies
  8: optional list<string> statuses
  9: optional WithdrawalsSearchFilter filter
}

union ReportQuery {
  1: PaymentsQuery payments
  2: WithdrawalsQuery withdrawals
}

struct CreateReportRequest {
  /**
   * Server validates that report_type matches the selected ReportQuery branch.
   */
  1: required ReportType report_type
  2: required FileType file_type
  3: required ReportQuery query
  /**
   * timezone controls CSV rendering timezone and defaults to UTC.
   */
  4: optional string timezone
  5: optional string idempotency_key
}

struct FileSignature {
  1: required string md5
  2: required string sha256
}

struct FileMeta {
  1: required FileID file_id
  2: required FileType file_type
  3: required string filename
  4: required string content_type
  5: required FileSignature signature
  6: optional i64 size_bytes
  7: required Timestamp created_at
}

struct ErrorInfo {
  1: required string code
  2: required string message
}

struct Report {
  1: required ReportID report_id
  2: required ReportType report_type
  3: required FileType file_type
  4: required ReportQuery query
  5: required Timestamp created_at
  /**
   * Processing start time (when worker started execution of this report job).
   */
  6: optional Timestamp started_at
  /**
   * This is the timestamp that bounds "what data version" is visible to this report.
   */
  7: optional Timestamp data_snapshot_fixed_at
  8: optional Timestamp finished_at
  9: required ReportStatus status
  10: optional FileMeta file
  11: optional ErrorInfo error
  12: optional i64 rows_count
  13: optional Timestamp expires_at
}

struct GetReportsFilter {
  1: optional list<ReportStatus> statuses
  2: optional list<ReportType> report_types
  3: optional list<FileType> file_types
  4: optional Timestamp created_from
  5: optional Timestamp created_to
}

struct GetReportsMeta {
  1: optional ContinuationToken continuation_token
  /**
   * If omitted, server applies a configured default page size.
   */
  2: optional i32 limit
}

struct GetReportsRequest {
  1: optional GetReportsFilter filter
  2: optional GetReportsMeta meta
}

struct GetReportsResponse {
  1: required list<Report> reports
  2: optional ContinuationToken continuation_token
}

struct GetReportRequest {
  1: required ReportID report_id
}

struct CancelReportRequest {
  1: required ReportID report_id
}

struct GeneratePresignedUrlRequest {
  1: required FileID file_id
  /**
   * Optional requested URL expiry timestamp.
   * If omitted, server uses configured default TTL.
   */
  2: optional Timestamp requested_expires_at
}

service Reporting {

  ReportID CreateReport(1: CreateReportRequest request) throws (
    1: InvalidRequest ex1
  )

  Report GetReport(1: GetReportRequest request) throws (
    1: ReportNotFound ex1
  )

  GetReportsResponse GetReports(1: GetReportsRequest request) throws (
    1: InvalidRequest ex1,
    2: BadContinuationToken ex2
  )

  void CancelReport(1: CancelReportRequest request) throws (
    1: ReportNotFound ex1
  )

  URL GeneratePresignedUrl(1: GeneratePresignedUrlRequest request) throws (
    1: FileNotFound ex1,
    2: InvalidRequest ex2
  )
}

# Changelog

Entries are ordered newest first. Format: `## [YYYY-MM-DD] — summary`.

## [2026-02-26] — Runtime & security updates

### Lambda runtime: `nodejs12.x` → `nodejs20.x`
- Node 12 reached end-of-life in April 2022
- Both `originRequest` and `originResponse` functions updated

### TLS minimum version: `TLSv1` → `TLSv1.2_2021`
- TLS 1.0 and 1.1 are deprecated and cryptographically broken (POODLE, BEAST, etc.)
- `TLSv1.2_2021` enforces TLS 1.2+ with modern cipher suites

### HTTP version: `http1.1` → `http2`
- HTTP/2 enables request multiplexing, header compression, and better performance for modern browsers

### `originRequest` handler (`lambda/handler.js`)
- Replaced a regex loop (iterating two patterns to reconstruct paths) with a single path calculation
- Behaviour is identical: extensionless URIs like `/about` resolve to `/about/index.html`; requests with a file extension are passed through unchanged

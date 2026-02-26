# cloudfrontEdge-s3-module

Terraform module that deploys a static website via CloudFront backed by S3, with Lambda@Edge for SPA routing and security headers.

## What it creates

| Resource | Purpose |
|---|---|
| S3 bucket | Stores static assets; private, accessible only via CloudFront OAI |
| CloudFront OAI | Origin Access Identity — restricts S3 access to CloudFront only |
| CloudFront distribution | CDN with HTTPS redirect, HTTP/2, custom domains |
| Lambda@Edge — `originRequest` | Rewrites extensionless paths to `path/index.html` |
| Lambda@Edge — `originResponse` | Adds security headers to every response |
| ACM certificate | Looked up by domain from existing issued certificates |
| Route53 records | A alias records for each domain name |

## Security headers added by `originResponse`

| Header | Value |
|---|---|
| `x-frame-options` | `SAMEORIGIN` |
| `strict-transport-security` | `max-age=15552000; includeSubDomains` |
| `x-content-type-options` | `nosniff` |
| `x-xss-protection` | `1; mode=block` |
| `content-security-policy` | Allowlisted sources for scripts, styles, fonts, images, and API connections |
| `Referrer-Policy` | `same-origin` |

Any 4xx/5xx response from S3 is redirected to `/index.html` so deep-links resolve correctly after a CloudFront miss.

## Variables

| Variable | Description |
|---|---|
| `name` | Name prefix for all resources |
| `domain_names` | List of domain aliases for CloudFront |
| `asset_folder` | Path to the built static assets to zip and upload |

## Changelog

### Runtime & security updates

**Lambda runtime**: `nodejs12.x` → `nodejs20.x`
- Node 12 reached end-of-life in April 2022
- Both `originRequest` and `originResponse` functions updated

**TLS minimum version**: `TLSv1` → `TLSv1.2_2021`
- TLS 1.0 and 1.1 are deprecated and cryptographically broken (POODLE, BEAST, etc.)
- `TLSv1.2_2021` enforces TLS 1.2+ with modern cipher suites

**HTTP version**: `http1.1` → `http2`
- HTTP/2 enables request multiplexing, header compression, and better performance for modern browsers

**`originRequest` handler** (`lambda/handler.js`)
- Replaced a regex loop (iterating two patterns to reconstruct paths) with a single path calculation
- Behaviour is identical: extensionless URIs like `/about` resolve to `/about/index.html`; requests with a file extension are passed through unchanged

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

See [CHANGELOG.md](CHANGELOG.md) for version history.

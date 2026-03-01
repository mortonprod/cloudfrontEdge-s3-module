const path = require('path');

/**
 * Redirect extensionless URIs to their directory index.html, otherwise serve the static asset.
 */
exports.originRequest = (event, context, callback) => {
  const { request } = event.Records[0].cf;
  const parsedPath = path.parse(request.uri);

  if (parsedPath.ext === '') {
    const base = request.uri.endsWith('/') ? request.uri.slice(0, -1) : request.uri;
    request.uri = (base || '') + '/index.html';
  }

  return callback(null, request);
};
/**
 * This will add the correct security headers to the response.
 */
exports.originResponse = (event, context, callback) => {

    const response = event.Records[0].cf.response;
    /**
     * If we get an error from the origin assume we could not find the html page and return to index.
     * Otherwise update with security headers.
     */
    if (response.status >= 400 && response.status <= 599) {
      const redirect_path = `/index.html`;

      response.status = 302;
      response.statusDescription = 'Found';

      /* Drop the body, as it is not required for redirects */
      response.body = '';
      response.headers['location'] = [{ key: 'Location', value: redirect_path }];
    } else {

      response.headers["x-frame-options"] = [{
        key: "x-frame-options",
        value: "SAMEORIGIN",
      }];

      response.headers["strict-transport-security"] = [{
          key: "strict-transport-security",
          value: "max-age=15552000; includeSubDomains",
      }];

      response.headers["x-content-type-options"] = [{
          key: "x-content-type-options",
          value: "nosniff",
      }];
      response.headers["x-xss-protection"] = [{
          key: "x-xss-protection",
          value: "1; mode=block",
      }];
      response.headers["content-security-policy"] = [{
          key: "content-security-policy",
          value: "default-src 'self'; img-src 'self' webpage-screenshot-processor-images-prod.s3.eu-west-2.amazonaws.com; connect-src 'self' ses.alexandermorton.co.uk apipagemelt-prod.alexandermorton.co.uk apipagemelt-dev.alexandermorton.co.uk cdnjs.cloudflare.com cdn.jsdelivr.net; script-src 'self' cdn.jsdelivr.net stackpath.bootstrapcdn.com cdnjs.cloudflare.com code.jquery.com; style-src 'self' cdn.jsdelivr.net stackpathq.bootstrapcdn.com cdnjs.cloudflare.com fonts.googleapis.com; font-src 'self' fonts.googleapis.com fonts.gstatic.com",
      }];
      response.headers["Referrer-Policy"] = [{
          key: "Referrer-Policy",
          value: "same-origin",
      }];
    } 
    callback(null, response);
    
};
const path = require('path');
const extracts = [/\/[a-zA-Z0-9_.-]*\/[a-zA-Z0-9_.-]*/,/\/[a-zA-Z0-9_.-]*/];
/**
 * This part will redirect the client to the correct index file for / or /something or /something/something
 * Note we will only redirect if no extension is present.
 */
exports.originRequest = (event, context, callback) => {
  const { request } = event.Records[0].cf;
  /**
   * Use node to parse the input request url to determine if we need to append and index.html to it. 
   */
  const parsedPath = path.parse(request.uri);
  let newUri;
  /**
   * If there is an extension then we just need to served the static assets at that location
   * Otherwise route to the index.html file
   */
  if (parsedPath.ext === '') {
    let isMatched = false;
    /**
     * If no extension found then we need to find the index.html file
     * Loop through all regex until we get a match.
     * TODO: Should be able to do this without a loop but will do for now.
     */
    for (let extract of extracts) {
        let match = request.uri.match(extract);
        if(match) {
            newUri = match[0] + '/' + 'index.html';
            isMatched = true;
            break
        }
    }
    /**
     * If we find no match then redirect to root index file.
     */
    if(!isMatched) {
        newUri = '/index.html';
    }
  } else {
    newUri = request.uri;
  }

  // Replace the received URI with the URI that includes the index page
  request.uri = newUri;
  
  // Return to CloudFront
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
          value: "default-src 'self'; connect-src 'self' ses.alexandermorton.co.uk; script-src 'self' stackpath.bootstrapcdn.com cdnjs.cloudflare.com code.getmdl.io code.jquery.com; style-src 'self' code.getmdl.io fonts.googleapis.com; font-src 'self' code.getmdl.io fonts.googleapis.com fonts.gstatic.com",
      }];
      response.headers["Referrer-Policy"] = [{
          key: "Referrer-Policy",
          value: "same-origin",
      }];
    } 
    callback(null, response);
    
};
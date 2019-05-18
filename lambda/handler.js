const path = require('path');
const extracts = [/\/[a-zA-Z0-9_.-]*\/[a-zA-Z0-9_.-]*/,/\/[a-zA-Z0-9_.-]*/];
/**
 * This part will redirect the client to the correct index file.
 */
exports.originRequest = (event, context, callback) => {
  const { request } = event.Records[0].cf;
  
//   console.log('Request URI: ', request.uri);
  /**
   * Use node to parse the input request url to determine if we need to append and index.html to it. 
   */
  const parsedPath = path.parse(request.uri);
  let newUri;

//   console.log('Parsed Path: ', parsedPath);
  /**
   * If there is an extension then we just need to served the static assets at that location
   * Otherwise route to the index.html file
   */
  if (parsedPath.ext === '') {
    let isMatched = false;
    /**
     * If no extension found then we need to find the index.html file
     * Loop through all regex until we get a match.
     */
    for (let extract of extracts) {
        let match = request.uri.match(extract);
        // console.log(`Match ${match} ${request.uri} ${extract}`);
        if(match) {
            // console.log(`Match Inside ${match[0]} ${typeof match}`);
            // newUri = path.join(match[0], 'index.html');
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

//   console.log('New URI: ', newUri);

  // Replace the received URI with the URI that includes the index page
  request.uri = newUri;
  
  // Return to CloudFront
  return callback(null, request);
};
/**
 * This will add the correct security headers to the response.
 * Can't do this with WAF rules it seems.
 */
exports.originResponse = (event, context, callback) => {

    const response = event.Records[0].cf.response;
    
    const headers = response.headers;
    
    headers["x-frame-options"] = [{
        key: "x-frame-options",
        value: "SAME-ORIGIN",
    }];

    headers["strict-transport-security"] = [{
        key: "strict-transport-security",
        value: "max-age=15552000; includeSubDomains",
    }];

    headers["x-content-type-options"] = [{
        key: "x-content-type-options",
        value: "nosniff",
    }];
    headers["x-xss-protection"] = [{
        key: "x-xss-protection",
        value: "1; mode=block",
    }];
    headers["content-security-policy"] = [{
        key: "content-security-policy",
        value: "default-src 'self'; connect-src 'self' ses.alexandermorton.co.uk; script-src 'self' 'unsafe-inline' cdnjs.cloudflare.com code.getmdl.io code.jquery.com; style-src 'self' code.getmdl.io fonts.googleapis.com; font-src 'self' code.getmdl.io fonts.googleapis.com fonts.gstatic.com",
    }];
    headers["Referrer-Policy"] = [{
        key: "Referrer-Policy",
        value: "same-origin",
    }];
    
    callback(null, response);
    
};
/**
 * DeskClient allows you to interact with the desk.com API. This wrapper is
 * based on APIv2 and not officially supported by desk.com.
 * 
 * @author Thomas Stachl <thomas@desk.com>
 * @version 0.1
 * @license MIT - http://thomas.mit-license.org/
 */
global class DeskClient
{
    /**
	 * The API endpoint.
	 */
    public String endpoint
    {
    	/**
    	 * @return String endpoint
    	 * @throws ConfigurationException
    	 */
    	get {
	        if (this.endpoint == null) {
	            if (this.subdomain == null)
	                throw new ConfigurationException('Endpoint and subdomain missing.');
	            this.endpoint = 'https://' + this.subdomain + '.desk.com';
	        }
	        return this.endpoint;
	    }
	    set;
	}
	
    /**
	 * The subdomain to auto-build the endpoint (https://SUBDOMAIN.desk.com).
	 */
    public String subdomain      { get; set; }
    
    /**
	 * The Basic Auth username.
	 */
    public String username       { get; set; }
    
    /**
	 * The Basic Auth password.
	 */
    public String password       { get; set; }
    
    /**
	 * The OAuth token.
	 */
    public String token          { get; set; }
    
    /**
	 * The OAuth tokenSecret.
	 */
    public String tokenSecret    { get; set; }
    
    /**
	 * The OAuth consumerKey.
	 */
    public String consumerKey    { get; set; }
    
    /**
	 * The OAuth consumerSecret.
	 */
    public String consumerSecret { get; set; }
    
    /**
	 * The defaultHeaders for all requests.
	 */
    private Map<String, String> defaultHeaders = new Map<String, String>{
        'User-Agent'           => 'salesforce-desk-client/0.1.0',
        'Accept'               => 'application/json'
    };
    
    /**
	 * Instantiates a new DeskClient.
	 */
    public DeskClient() {}
    
    /**
	 * Instantiates a new DeskClient and sets the fields.
	 * @param  options				A map of options to instantiate the DeskClient with.
	 */
    public DeskClient(Map<String, String> options)
    {
        // if we have options set them
        if (options.containsKey('endpoint'))        this.endpoint       = options.get('endpoint');
        if (options.containsKey('subdomain'))       this.subdomain      = options.get('subdomain');
        if (options.containsKey('username'))        this.username       = options.get('username');
        if (options.containsKey('password'))        this.password       = options.get('password');
        if (options.containsKey('token'))           this.token          = options.get('token');
        if (options.containsKey('tokenSecret'))     this.tokenSecret    = options.get('tokenSecret');
        if (options.containsKey('consumerKey'))     this.consumerKey    = options.get('consumerKey');
        if (options.containsKey('consumerSecret'))  this.consumerSecret = options.get('consumerSecret');
    }
    
    /**
     * Returns a new DeskResource based on the name.
     * @param  key					The plural name of the resource you require.
     * @return DeskResource
     */
    public DeskResource getResource(String key)
    {
		return this.findByPath('/api/v2/' + key);
    }
    
    /**
     * Finds a DeskResource based on the path.
     * @param  path					The full api path to the resource.
     * @return DeskResource
     */
    public DeskResource findByPath(String path)
    {
        return new DeskResource(new Map<String, Object>{
            '_links' => new Map<String, Object>{
                'self' => new Map<String, String>{
                    'href' => path
                }
            }
        }, this, false);
    }
    
    /**
     * HTTP GET Request methods
     * @param  path					The full api path to call.
     * @return HTTPResponse
     */
    public HTTPResponse get(String path) { return this.request('GET', path); }
    
    /**
     * HTTP POST Request methods
     * @param  path					The full api path to call.
     * @param  payload				The string representation of the request body.
     * @return HTTPResponse
     */
    public HTTPResponse post(String path, String payload)
    { 
        return this.request('POST', path, payload);
    }
    
    /**
     * HTTP PATCH Request methods
     * @param  path					The full api path to call.
     * @param  payload				The string representation of the request body.
     * @return HTTPResponse
     */
    public HTTPResponse patch(String path, String payload)
    { 
        return this.request('PATCH', path, payload);
    }
    
    /**
     * HTTP DELETE Request methods
     * @param  path					The full api path to call.
     * @return HTTPResponse
     */
    public HTTPResponse destroy(String path) { return this.request('DELETE', path); }
    
    /**
     * Different signature for the request method.
     * @param  method				The method to call.
     * @param  path					The full api path to call.
     * @return HTTPResponse
     */
    public HTTPResponse request(String method, String path)
    {
        return this.request(method, path, null);
    }
    
    /**
     * Sends off the actual request.
     * @param  method				The method to call.
     * @param  path					The full api path to call.
     * @param  payload				The string representation of the request body.
     * @return HTTPResponse
     */
    public HTTPResponse request(String method, String path, String payload)
    {
        HTTPRequest req = new HTTPRequest();
        Map<String, String> headers = this.defaultHeaders.clone();
        
        // set the request method
        if (method != 'PATCH') {
            req.setMethod(method);
        } else {
            req.setMethod('POST');
            headers.putAll(new Map<String, String>{ 'X-HTTP-Method-Override' => 'PATCH' });
        }
        
        // set the payload if exists
        if (payload != null && payload != '') {
            headers.put('Content-Type', 'application/json');
            req.setBody(payload);
        }
        
        // set the headers for the request
        for (String key : headers.keySet()) {
            req.setHeader(key, headers.get(key));
        }
        
        // set the endpoint
        req.setEndpoint(this.endpoint + path);
        
        // basic or oauth
        req = this.basicAuthentication(req);
        req = this.signRequest(req);
        
        HTTP client = new HTTP();
        HTTPResponse rsp = client.send(req);
        
        //Helpful debug messages
        System.debug(rsp.getBody());
        System.debug('STATUS:' + rsp.getStatus());
        System.debug('STATUS_CODE:' + rsp.getStatusCode());
        
        return rsp;
    }
    
    /**
     * Takes a parameter string and returns a map.
     * @param  paramString				Parameter string delimited by & and = signs.
     * @return Map<String, String>
     */
    private Map<String, String> getParams(String paramString)
    {
        Map<String, String> params = new Map<String, String>();
        
        if (paramString == null || paramString == '') return params;
        
        for(String s : paramString.split('&')) {
            String[] sl = s.split('=');
            if (sl.size() == 2) {
                params.put(sl[0], sl[1]);
            }
        }
        
        return params;
    }
    
    /**
     * Adds the Basic Auth header to the request.
     * @param  req						The request that needs to be authorized.
     * @return HTTPRequest
     */
    private HTTPRequest basicAuthentication(HTTPRequest req)
    {
        if (String.isNotBlank(this.username) && String.isNotBlank(this.password)) {
            Blob headerValue = Blob.valueOf(this.username + ':' + this.password);
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        }
        return req;
    }
    
    /**
     * Adds the OAuth header to the request.
     * @param  req						The request that needs to be authorized.
     * @return HTTPRequest
     */
    private HTTPRequest signRequest(HTTPRequest req)
    {
        if (String.isNotBlank(this.consumerKey) && String.isNotBlank(this.consumerSecret)
            && String.isNotBlank(this.token) && String.isNotBlank(this.tokenSecret))
        {
            Map<String, String> params = new Map<String, String>{
                'oauth_consumer_key' => this.consumerKey,
                'oauth_nonce' => String.valueOf(Crypto.getRandomLong()),
                'oauth_signature_method' => 'HMAC-SHA1',
                'oauth_timestamp' => String.valueOf(DateTime.now().getTime()/1000),
                'oauth_token' => this.token,
                'oauth_version' => '1.0'
            };
            
            String[] host = req.getEndpoint().split('\\?');
        
            // parse get parameters
            if (host.size() == 2) {
                params.putAll(this.getParams(host[1]));
            }
        
            // parse body parameters
            if (req.getBody() != null && req.getBody() != '') {
                params.putAll(this.getParams(req.getBody()));
            }
        
            // create the base string
            String baseString = '';
            List<String> keyList = new List<String>(params.keySet());
            keyList.sort();
            for (String key : keyList) {
                baseString += key + '=' + params.get(key) + '&';
            }
            baseString = req.getMethod().toUpperCase() + '&' +
                         EncodingUtil.urlEncode(host[0], 'UTF-8') + '&' +
                         EncodingUtil.urlEncode(baseString.substringBeforeLast('&'), 'UTF-8');
            
            System.debug('BASE STRING: ' + baseString);
        
            // create the signature
            Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(baseString), Blob.valueOf(
                            this.consumerSecret + '&' + this.tokenSecret
                       ));
            String signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        
            // create the header
            String header = 'OAuth ';
            for (String key : params.keySet()) {
                header += key + '="' + params.get(key) + '", ';
            }
            header += 'oauth_signature="' + signature + '"';
            
            // sign the request
            req.setHeader('Authorization', header);
        }
        return req;
    }
    
    /**
     * Custom configuration exception class.
     */
    public class ConfigurationException extends Exception {}
}
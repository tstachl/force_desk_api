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
    // class variables
    public String endpoint       { get {
        if (this.endpoint == null) {
            if (this.subdomain == null)
                throw new ConfigurationException('Endpoint and subdomain missing.');
            this.endpoint = 'https://' + this.subdomain + '.desk.com';
        }
        return this.endpoint;
    } set; }                                    // api endpoint
    public String subdomain      { get; set; }  // subdomain to build the full endpoint (https://SUBDOMAIN.desk.com)
    public String username       { get; set; }  // username for the basic auth flow
    public String password       { get; set; }  // password for the basic auth flow
    public String token          { get; set; }  // token for the OAuth flow
    public String tokenSecret    { get; set; }  // token secret for the OAuth flow
    public String consumerKey    { get; set; }  // consumer key for the OAuth flow
    public String consumerSecret { get; set; }  // consumer secret for the OAuth flow
    private Map<String, String> defaultHeaders = new Map<String, String>{
        'User-Agent'           => 'salesforce-desk-client/0.1.0',
        'Accept'               => 'application/json'
    };
    
    // constructors
    public DeskClient() {}
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
    
    public DeskResource getResource(String key)
    {
        return new DeskResource(new Map<String, Object>{
            '_links' => new Map<String, Object>{
                'self' => new Map<String, String>{
                    'href' => '/api/v2/' + key
                }
            }
        }, this, false);
    }
    
    /**
     * HTTP GET Request methods
     */
    public HTTPResponse get(String uri) { return this.request('GET', uri); }
    
    /**
     * HTTP POST Request methods
     */
    public HTTPResponse post(String uri, String payload)
    { 
        return this.request('POST', uri, payload);
    }
    
    /**
     * HTTP PATCH Request methods
     */
    public HTTPResponse patch(String uri, String payload)
    { 
        return this.request('PATCH', uri, payload);
    }
    
    /**
     * HTTP DELETE Request methods
     */
    public HTTPResponse destroy(String uri) { return this.request('DELETE', uri); }
    
    /**
     * Actual request methods.
     */
    public HTTPResponse request(String method, String uri)
    {
        return this.request(method, uri, null);
    }
    
    public HTTPResponse request(String method, String uri, String payload)
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
        req.setEndpoint(this.endpoint + uri);
        
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
    
    // private helper methods
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
    
    private HTTPRequest basicAuthentication(HTTPRequest req)
    {
        if (String.isNotBlank(this.username) && String.isNotBlank(this.password)) {
            Blob headerValue = Blob.valueOf(this.username + ':' + this.password);
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        }
        return req;
    }
    
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
    
    // exception
    public class ConfigurationException extends Exception {}
}
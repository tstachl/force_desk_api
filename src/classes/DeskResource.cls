/**
 * DeskClient allows you to interact with the desk.com API. This wrapper is
 * based on APIv2 and not officially supported by desk.com.
 * 
 * @author Thomas Stachl <thomas@desk.com>
 * @version 0.1
 * @license MIT - http://thomas.mit-license.org/
 */
global class DeskResource
{
    /**
	 * The links object.
	 */
    public Map<String, Object> links    = new Map<String, Object>();
    
    /**
	 * The resource fields.
	 */
    public Map<String, Object> fields   = new Map<String, Object>();
    
    /**
	 * The local changes not persistent.
	 */
    public Map<String, Object> changes  = new Map<String, Object>();
    
    /**
	 * The embedded resources object.
	 */
    public Map<String, Object> embedded = new Map<String, Object>();
    
    /**
	 * The flag indicating if the resource is loaded from the server.
	 */
    private Boolean loaded = false;
    
    /**
	 * The client used for transactions.
	 */
    private DeskClient client;
    
    /**
	 * Instantiates a new (empty) DeskResource.
	 */
    public DeskResource() { this(new Map<String, Object>(), null, false); }
    
    /**
	 * Instantiates a new (empty) DeskResource and sets the client.
	 * @param  client				The client to use for transactions.
	 */
    public DeskResource(DeskClient client)
    {
        this(new Map<String, Object>(), client, false);
    }
    
    /**
	 * Instantiates a new DeskResource from a JSON string without a client.
	 * @param  jsonString			The JSON string to set up.
	 */
    public DeskResource(String jsonString) { this(jsonString, null, false); }
    
    /**
	 * Instantiates a new DeskResource from a JSON string with a client.
	 * @param  jsonString			The JSON string to set up.
	 * @param  client				The client to use for transactions.
	 */
    public DeskResource(String jsonString, DeskClient client) { this(jsonString, client, false); }
    
    /**
	 * Instantiates a new DeskResource from a JSON string with a client.
	 * @param  jsonString			The JSON string to set up.
	 * @param  client				The client to use for transactions.
	 * @param  loaded				Indicates whether it was loaded from the API or not. 
	 */
    public DeskResource(String jsonString, DeskClient client, Boolean loaded)
    {
        this((Map<String, Object>)JSON.deserializeUntyped(jsonString), client, loaded);
    }
    
    /**
	 * Instantiates a new DeskResource from a JSON string with a client.
	 * @param  jsonMap				The JSON string converted to an untyped map.
	 * @param  client				The client to use for transactions.
	 * @param  loaded				Indicates whether it was loaded from the API or not. 
	 */
    public DeskResource(Map<String, Object> jsonMap, DeskClient client, Boolean loaded)
    {
        this.client = client;
        this.loaded = loaded;
        this.setup(jsonMap);
    }
    
    /**
	 * Generic getter returns fields, links and embedded resources.
	 * @param  key					The name of the field/embedded/link resource.
	 * @return Object
	 */
    public Object get(String key)
    {
        if (this.fields.containsKey(key)) {
            if (this.changes.containsKey(key)) return this.changes.get(key);
            else return this.fields.get(key);
        }
        if (this.embedded.containsKey(key)) return this.embedded.get(key);
        if (this.links.containsKey(key)) return this.links.get(key);
        
        // if we don't find anything make sure we have the resource loaded
        
        if (!this.loaded) return this.exec().get(key);
        return null;
    }
    
    /**
	 * Getter for resources, will lookup links and embedded resources.
	 * @param  key					The name of the embedded/link resource.
	 * @return DeskResource
	 */
    public DeskResource getResource(String key)
    {
        if (this.embedded.containsKey(key) && this.embedded.get(key) instanceof DeskResource)
            return (DeskResource)this.embedded.get(key);
        if (this.links.containsKey(key) && this.links.get(key) instanceof DeskResource)
            return (DeskResource)this.links.get(key);
        if (!this.loaded) return this.exec().getResource(key);
        return null;
    }
    
    /**
	 * If this is a page resource `getEntries' would return the list of resources.
	 * @return List<DeskResource>
	 */
    public List<DeskResource> getEntries()
    {
        if (this.embedded.containsKey('entries'))
            return (List<DeskResource>)this.embedded.get('entries');
        if (!this.loaded) return this.exec().getEntries();
        return null;
    }
    
    /**
	 * Setter only works on fields.
	 * @param  key					The name of the field.
	 * @param  value				The value the field should be set to.
	 */
    public void set(String key, Object value)
    {
        if (this.fields.containsKey(key)) {
            this.changes.put(key, value);
        }
    }
    
    /**
	 * Creates a new desk resource.
	 * @param  params				A map with params for the new resource.
	 * @return DeskResource
	 */
    public DeskResource create(Map<String, Object> params)
    {
        return new DeskResource(
            this.client.post(this.cleanBaseUrl(), JSON.serialize(params)).getBody(),
            this.client, true
        );
    }
    
    /**
	 * Updates the current desk resource.
	 * @param  params				A map with params for the new resource.
	 * @return DeskResource
	 */
    public DeskResource patch(Map<String, Object> params)
    {
        this.changes.putAll(params);
        this.setup(this.client.patch(this.getHref(), JSON.serialize(this.changes)).getBody());
        this.changes.clear();
        return this;
    }
    
    /**
	 * Deletes the current desk resource.
	 * @return Boolean
	 */
    public Boolean destroy()
    {
        return this.client.destroy(this.getHref()).getStatusCode() == 204;
    }
    
    /**
	 * Searches the current desk resources base object.
	 * @param  params				A string for the full text search.
	 * @return DeskResource
	 */
    public DeskResource search(String params)
    {
        return this.search(new Map<String, String>{
            'q' => params
        });
    }
    
    /**
	 * Searches the current desk resources base object.
	 * @param  params				A map of search params.
	 * @return DeskResource
	 */
    public DeskResource search(Map<String, String> params)
    {
        PageReference uri = new PageReference(this.cleanBaseUrl() + '/search');
        uri.getParameters().putAll(params);
        return this.findByPath(uri.getUrl());
    }
    
    /**
	 * Finds a specific desk resource on the current desk resources base object.
	 * @param  id					The id of the resource.
	 * @return DeskResource
	 */
    public DeskResource find(Integer id) { return this.find(String.valueOf(id)); }

    /**
	 * Finds a specific desk resource on the current desk resources base object.
	 * @param  id					The id of the resource.
	 * @return DeskResource
	 */
    public DeskResource find(String id)
    {
    	return this.findByPath(this.cleanBaseUrl() + '/' + id).exec();
    }
    
    /**
     * @param  path					The full api path to the resource.
     * @return DeskResource
     */
    public DeskResource findByPath(String path)
    {
    	return this.client.findByPath(path);
    }
    
    /**
	 * Returns the current page number.
	 * @return Integer
	 */
    public Integer page()
    {
        if (!this.getQueryParams().containsKey('page')) { this.exec(); }
        if (this.getQueryParams().containsKey('page')) {
            return Integer.valueOf(this.getQueryParams().get('page'));
        }
        return null;
    }
    
    /**
	 * Sets the current page number.
	 * @param  p					The page to be fetched.
	 * @return DeskResource
	 */
    public DeskResource page(Integer p)
    {
        this.setHref(new Map<String, String>{ 'page' => String.valueOf(p) });
        return this;
    }
    
    /**
	 * Returns the current perPage number.
	 * @return Integer
	 */
    public Integer perPage()
    {
        if (!this.getQueryParams().containsKey('per_page')) { this.exec(); }
        if (this.getQueryParams().containsKey('per_page')) {
            return Integer.valueOf(this.getQueryParams().get('per_page'));
        }
        return null;
    }
    
    /**
	 * Sets the current perPage number.
	 * @param  p					The number of records on a page to be fetched.
	 * @return DeskResource
	 */
    public DeskResource perPage(Integer p)
    {
        this.setHref(new Map<String, String>{ 'per_page' => String.valueOf(p) });
        return this;
    }
    
    /**
     * Allows you to embed subresources in the main request.
     * @param  embedds				A comma separated list of resources to embed.
     * @return DeskResource
     */
    public DeskResource embed(String embedds)
    {
        this.setHref(new Map<String, String>{ 'embed' => embedds });
        return this;
    }
    
    /**
	 * Executes a load on the current resource if not loaded.
	 * @return DeskResource
	 */
    public DeskResource exec()
    {
        return this.exec(false);
    }
    
    /**
	 * Executes a load on the current resource if not loaded or reload is true.
	 * @param  reload				Indicates whether you want to force a reload.
	 * @return DeskResource
	 */
    public DeskResource exec(Boolean reload)
    {
        if (!this.loaded || (this.loaded && reload)) {
            this.setup(this.client.get(this.getHref()).getBody());
            this.loaded = true;
        }
        return this;
    }
    
    /**
	 * Returns the current href link.
	 * @return String
	 */
    public String getHref()
    {
        return (String)this.getSelf().get('href');
    }
    
    /**
	 * Returns the current self map.
	 * @return Map<String, Object>
	 */
    public Map<String, Object> getSelf()
    {
    	return (Map<String, Object>)this.get('self');
    }
    
    /**
	 * Returns the url of the current resources base object.
	 * @return String
	 */
    private String cleanBaseUrl()
    {
        URL uri = new URL(this.client.endpoint + this.getHref());
        return uri.getPath().replaceAll('\\/(search|\\d+)$', '');
    }
    
    /**
	 * Changes the href of the current resource.
	 * @param  params				A map of parameters for the current resource href.
	 */
    private void setHref(Map<String, String> params)
    {
        PageReference uri = new PageReference(this.getHref());
        Map<String, String> oldParams = uri.getParameters().clone();
        uri.getParameters().putAll(params);
        // only change link if params have changed
        if (oldParams != uri.getParameters()) {
        	Map<String, Object> href = new Map<String, Object>();
	        href.put('href', uri.getUrl());
        	this.links.put('self', href);
        	this.loaded = false;
        }
    }
    
    /**
	 * Returns query parameters for the current href.
	 * @return Map<String, String>
	 */
    private Map<String, String> getQueryParams()
    {
        PageReference uri = new PageReference(this.getHref());
        return uri.getParameters();
    }
    
    /**
	 * Sets up a resource from a json string.
	 */
    private void setup(String jsonString)
    {
        this.setup((Map<String, Object>)JSON.deserializeUntyped(jsonString));
    }
    
    /**
 	 * Sets up a resource from a map.
	 */
    private void setup(Map<String, Object> jsonMap)
    {
        for (String key : jsonMap.keySet()) {
            if (!key.startsWith('_')) {
                this.fields.put(key, jsonMap.get(key));
                continue;
            }
            
            if (key == '_embedded') {
                Map<String, Object> value = (Map<String, Object>)jsonMap.get(key);
                for (String subKey : value.keySet()) {
                    Object subValue = value.get(subKey);
                    if (subValue instanceof List<Object>) {
                        List<DeskResource> entries = new List<DeskResource>();
                        for (Object obj : (List<Object>)subValue) {
                            entries.add(new DeskResource((Map<String, Object>)obj, this.client, true));
                        }
                        this.embedded.put(subKey, entries);
                    } else {
                        this.embedded.put(subKey, new DeskResource((Map<String, Object>)subValue, this.client, true));
                    }
                }
            }
            
            if (key == '_links') {
                Map<String, Object> value = (Map<String, Object>)jsonMap.get(key);
                for (String subKey : value.keySet()) {
                    Map<String, Object> obj = (Map<String, Object>)value.get(subKey);
                    if (subKey == 'self' || obj == null) {
                        this.links.put(subKey, obj);
                    } else {
                        this.links.put(subKey, new DeskResource(new Map<String, Map<String, Object>>{
                            '_links' => new Map<String, Object>{
                                'self' => obj
                            }
                        }, this.client, false));
                    }
                }
            }
        }
    }
}
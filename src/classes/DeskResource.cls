public class DeskResource
{
    public Map<String, Object> links    = new Map<String, Object>();
    public Map<String, Object> fields   = new Map<String, Object>();
    public Map<String, Object> changes  = new Map<String, Object>();
    public Map<String, Object> embedded = new Map<String, Object>();
    
    private Boolean loaded = false;
    private DeskClient client;
    
    /**
 	 * Multiple different constructors for this diverse class.
	 */
    public DeskResource() { this(new Map<String, Object>(), null, false); }
    public DeskResource(DeskClient client)
    {
        this(new Map<String, Object>(), client, false);
    }
    
    public DeskResource(String jsonString) { this(jsonString, null, false); }
    public DeskResource(String jsonString, DeskClient client) { this(jsonString, client, false); }
    public DeskResource(String jsonString, DeskClient client, Boolean loaded)
    {
        this((Map<String, Object>)JSON.deserializeUntyped(jsonString), client, loaded);
    }
    
    public DeskResource(Map<String, Object> jsonMap, DeskClient client, Boolean loaded)
    {
        this.client = client;
        this.loaded = loaded;
        this.setup(jsonMap);
    }
    
    /**
	 * Generic getter returns fields, links and embedded resources.
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
	 */
    public void set(String key, Object value)
    {
        if (this.fields.containsKey(key)) {
            this.changes.put(key, value);
        }
        return;
    }
    
    /**
	 * Creates a new desk resource.
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
	 */
    public Boolean destroy()
    {
        return this.client.destroy(this.getHref()).getStatusCode() == 204;
    }
    
    /**
	 * Searches the current desk resources base object.
	 */
    public DeskResource search(String params)
    {
        return this.search(new Map<String, String>{
            'q' => params
        });
    }
    
    public DeskResource search(Map<String, String> params)
    {
        PageReference uri = new PageReference(this.cleanBaseUrl() + '/search');
        uri.getParameters().putAll(params);
        return new DeskResource(new Map<String, Object>{
            '_links' => new Map<String, Object>{
                'self' => new Map<String, String>{
                    'href' => uri.getUrl()
                }
            }
        }, this.client, false);
    }
    
    /**
	 * Finds a specific desk resource on the current desk resources base object.
	 */
    public DeskResource find(Integer id) { return this.find(String.valueOf(id)); }
    public DeskResource find(String id)
    {
        DeskResource res = new DeskResource(new Map<String, Object>{
            '_links' => new Map<String, Object>{
                'self' => new Map<String, String>{
                    'href' => this.cleanBaseUrl() + '/' + id
                }
            }
        }, this.client, false);
        return res.exec();
    }
    
    /**
	 * Returns the current page number.
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
	 */
    public DeskResource page(Integer p)
    {
        this.setHref(new Map<String, String>{ 'page' => String.valueOf(p) });
        return this;
    }
    
    /**
	 * Returns the current perPage number.
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
	 */
    public DeskResource perPage(Integer p)
    {
        this.setHref(new Map<String, String>{ 'per_page' => String.valueOf(p) });
        return this;
    }
    
    public DeskResource embed(String embedds)
    {
        this.setHref(new Map<String, String>{ 'embed' => embedds });
        return this;
    }
    
    /**
	 * Executes a load on the current resource if not loaded.
	 */
    public DeskResource exec()
    {
        return this.exec(false);
    }
    
    /**
	 * Executes a load on the current resource if not loaded or reload is true.
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
	 * Returns the url of the current resources base object.
	 */
    private String cleanBaseUrl()
    {
        URL uri = new URL(this.client.endpoint + this.getHref());
        return uri.getPath().replaceAll('\\/(search|\\d+)$', '');
    }
    
    /**
	 * Changes the href of the current resource.
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
	 * Returns the current href link.
	 */
    public String getHref()
    {
        Map<String, Object> self = (Map<String, Object>)this.get('self');
        return (String)self.get('href');
    }
    
    /**
	 * Returns query parameters for the current href.
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
@isTest
public class DeskClientTest
{
    
    public static testMethod void configurationTest()
    {
        DeskClient client;
        // client doesn't need to have any configuration
        client = new DeskClient();
        System.assert(client != null);
        
        // it'll throw a ConfigurationException if no subdomain/endpoint is set
        try {
            String jsonString = client.get('/api/v2/cases').getBody();
        } catch (Exception e) {
            System.assert(e instanceof DeskClient.ConfigurationException);
        }
        
        // it'll allow you to define config variables on an instance
        client.endpoint = 'ep';
        client.username = 'un';
        client.password = 'pw';
        client.subdomain = 'sd';
        client.consumerKey = 'ck';
        client.consumerSecret = 'cs';
        client.token = 'to';
        client.tokenSecret = 'ts';
        
        System.assertEquals(client.endpoint, 'ep');
        System.assertEquals(client.username, 'un');
        System.assertEquals(client.password, 'pw');
        System.assertEquals(client.subdomain, 'sd');
        System.assertEquals(client.consumerKey, 'ck');
        System.assertEquals(client.consumerSecret, 'cs');
        System.assertEquals(client.token, 'to');
        System.assertEquals(client.tokenSecret, 'ts');
        
        // you can specify options on initialization
        client = new DeskClient(new Map<String, String>{
            'endpoint' => 'ep',
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'sd',
            'consumerKey' => 'ck',
            'consumerSecret' => 'cs',
            'token' => 'to',
            'tokenSecret' => 'ts'
        });
        
        System.assertEquals(client.endpoint, 'ep');
        System.assertEquals(client.username, 'un');
        System.assertEquals(client.password, 'pw');
        System.assertEquals(client.subdomain, 'sd');
        System.assertEquals(client.consumerKey, 'ck');
        System.assertEquals(client.consumerSecret, 'cs');
        System.assertEquals(client.token, 'to');
        System.assertEquals(client.tokenSecret, 'ts');
        
        // it automatically creates the endpoint if only subdomain
        client = new DeskClient(new Map<String, String>{
            'subdomain' => 'sd'
        });
        
        System.assertEquals(client.endpoint, 'https://sd.desk.com');
    }
    
    public static testMethod void getBasicTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> currUser = (Map<String, Object>)JSON.deserializeUntyped(client.get('/api/v2/users/current').getBody());
        System.assertEquals((String)currUser.get('name'), 'Thomas Stachl');
    }
    
    public static testMethod void getOAuthTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'consumerKey' => 'ck',
            'consumerSecret' => 'cs',
            'token' => 'to',
            'tokenSecret' => 'ts',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> currUser = (Map<String, Object>)JSON.deserializeUntyped(client.get('/api/v2/users/current').getBody());
        System.assertEquals((String)currUser.get('name'), 'Thomas Stachl');
    }
    
    public static testMethod void postBasicTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> newTopic = (Map<String, Object>)JSON.deserializeUntyped(client.post('/api/v2/topics', '{"name":"Test Topic"}').getBody());
        System.assertEquals((String)newTopic.get('name'), 'Test Topic');
    }
    
    public static testMethod void postOAuthTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'consumerKey' => 'ck',
            'consumerSecret' => 'cs',
            'token' => 'to',
            'tokenSecret' => 'ts',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> newTopic = (Map<String, Object>)JSON.deserializeUntyped(client.post('/api/v2/topics', '{"name":"Test Topic"}').getBody());
        System.assertEquals((String)newTopic.get('name'), 'Test Topic');
    }
    
    public static testMethod void patchBasicTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> updatedTopic = (Map<String, Object>)JSON.deserializeUntyped(client.patch('/api/v2/topics/601117', '{"name":"Test Updated Topic"}').getBody());
        System.assertEquals((String)updatedTopic.get('name'), 'Test Updated Topic');
    }
    
    public static testMethod void patchOAuthTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'consumerKey' => 'ck',
            'consumerSecret' => 'cs',
            'token' => 'to',
            'tokenSecret' => 'ts',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> updatedTopic = (Map<String, Object>)JSON.deserializeUntyped(client.patch('/api/v2/topics/601117', '{"name":"Test Updated Topic"}').getBody());
        System.assertEquals((String)updatedTopic.get('name'), 'Test Updated Topic');
    }
    
    public static testMethod void destroyBasicTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        System.assertEquals(client.destroy('/api/v2/topics/601117').getStatusCode(), 204);
    }
    
    public static testMethod void destroyOAuthTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'consumerKey' => 'ck',
            'consumerSecret' => 'cs',
            'token' => 'to',
            'tokenSecret' => 'ts',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        System.assertEquals(client.destroy('/api/v2/topics/601117').getStatusCode(), 204);
    }
    
    public static testMethod void getResourceTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Map<String, String> self = (Map<String, String>)client.getResource('cases').get('self');
        System.assert(self.get('href') == '/api/v2/cases');
    }
    
    public static testMethod void paramsTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'consumerKey' => 'ck',
            'consumerSecret' => 'cs',
            'token' => 'to',
            'tokenSecret' => 'ts',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        Map<String, Object> users = (Map<String, Object>)JSON.deserializeUntyped(client.get('/api/v2/users?page=1&per_page=100').getBody());
        System.assertEquals((Integer)users.get('total_entries'), 6);
    }

    public static testMethod void internalMockTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });

        // Set the internal Mock
        client.setMock(new DeskClientMock());
        Map<String, Object> currUser = (Map<String, Object>)JSON.deserializeUntyped(client.get('/api/v2/users/current').getBody());
        System.assertEquals((String)currUser.get('name'), 'Thomas Stachl');
    }
}
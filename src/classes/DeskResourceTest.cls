@isTest
public class DeskResourceTest
{
    
    public static testMethod void constructorTest()
    {
        // can be inited without information
        DeskResource res = new DeskResource();
        System.assert(res != null);
        // can be inited with only a client
        res = new DeskResource(new DeskClient());
        System.assert(res != null);
        // can be inited with only a json string
        res = new DeskResource('{"_links":{"self":{"href":"/api/v2/cases"}}}');
        System.assertEquals(res.getHref(), '/api/v2/cases');
        // can be inited with a json string and client
        res = new DeskResource('{"_links":{"self":{"href":"/api/v2/cases"}}}', new DeskClient());
        System.assertEquals(res.getHref(), '/api/v2/cases');
        // can be inited with a json string and client and loaded flag
        res = new DeskResource('{"_links":{"self":{"href":"/api/v2/cases"}}}', new DeskClient(), false);
        System.assertEquals(res.getHref(), '/api/v2/cases');
    }
    
    public static testMethod void getTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('users');
        System.assertEquals((Integer)res.get('total_entries'), 6);
        System.assertEquals((DeskResource)res.get('next'), null);
        System.assertEquals(((List<DeskResource>)res.get('entries')).size(), 6);
        System.assertEquals((Object)res.get('humbug'), null);
    }
    
    public static testMethod void getResourceTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('users/current');
        System.assertEquals(res.getResource('preferences').getHref(), '/api/v2/users/16096734/preferences');
        System.assertEquals(res.getResource('humbug'), null);
        res = client.getResource('cases').page(1).perPage(1).embed('customer').getEntries().get(0).getResource('customer');
        System.assertEquals((String)res.get('first_name'), 'Thomas');
        System.assertEquals(res.getHref(), '/api/v2/customers/37823480');
    }
    
    public static testMethod void getEntriesTest()   
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('cases').page(1).perPage(1).embed('customer');
        System.assertEquals(res.getEntries().size(), 1);
        System.assert(res.getEntries().get(0).getResource('customer').getEntries() == null);
    }
    
    public static testMethod void setTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('cases').page(1).perPage(1).embed('customer');
        DeskResource ticket = res.getEntries().get(0);
        ticket.set('subject', 'Test Subject');
        System.assertEquals(ticket.changes.get('subject'), 'Test Subject');
        System.assertEquals((String)ticket.get('subject'), 'Test Subject');
    }
    
    public static testMethod void createTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('topics').create(new Map<String, Object>{
            'name' => 'Test Topic'
        });
        System.assertEquals((String)res.get('name'), 'Test Topic');
    }
    
    public static testMethod void updateTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('topics').find(601117).patch(new Map<String, Object>{
            'name' => 'Test Updated Topic'
        });
        System.assertEquals((String)res.get('name'), 'Test Updated Topic');
    }
    
    public static testMethod void deleteTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('topics').find(601117);
        System.assert(res.destroy());
    }
    
    public static testMethod void searchTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('cases').search('subject:"Ut et culpa deleniti"');
        System.assertEquals(res.getEntries().size(), 1);
        res = client.getResource('cases').search(new Map<String, String>{ 'subject' => '"Ut et culpa deleniti"' });
        System.assertEquals(res.getEntries().size(), 1);
    }
    
    public static testMethod void pageTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('users').page(1).perPage(100).exec();
        System.assertEquals(res.page(), 1);
        System.assertEquals(res.perPage(), 100);
        
        res = client.getResource('users').exec();
        System.assertEquals(res.page(), null);
        System.assertEquals(res.perPage(), null);
    }
    
    public static testMethod void embedTest()
    {
        DeskClient client = new DeskClient(new Map<String, String>{
            'username' => 'un',
            'password' => 'pw',
            'subdomain' => 'devel'
        });
        
        Test.setMock(HttpCalloutMock.class, new DeskClientMock());
        DeskResource res = client.getResource('cases').page(1).perPage(1).embed('customer').getEntries().get(0).getResource('customer');
        System.assertEquals((String)res.get('first_name'), 'Thomas');
        System.assertEquals(res.getHref(), '/api/v2/customers/37823480');
        
        res = client.getResource('cases').find(3011, 'customer,message');
        System.assertEquals((Integer)res.get('priority'), 9);
        System.assertEquals((String)res.getResource('customer').get('first_name'), 'Thomas');
        System.assertEquals((String)res.getResource('message').get('direction'), 'in');
    }
}
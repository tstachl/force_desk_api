# desk.com APIv2 wrapper for salesforce.com

desk.com has released v2 of their REST API a few months ago and provides a lot more functionality. You should read up on the current progress of the [API](http://dev.desk.com/API/changelog). This library wraps all of it into an easy to use ruby module. We'll try to keep up with the changes of the API but things might still break unexpectedly.

## Example
This example shows you how to create a new client and establish a connection to the API. It shows the four request methods supported by the desk.com API (`GET`, `POST`, `PATCH` and `DELETE`).

```
// Basic Auth
DeskClient client = new DeskClient(new Map<String, String>{
  'username' => 'thomas@example.com',
  'password' => 'somepassword',
  'subdomain' => 'devel'
});

// OAuth
DeskClient client = new DeskClient(new Map<String, String>{
  'token' => 'TOKEN',
  'tokenSecret' => 'TOKEN_SECRET',
  'consumerKey' => 'CONSUMER_KEY',
  'consumerSecret' => 'CONSUMER_SECRET'
  'subdomain' => 'devel'
});

HTTPResponse rsp;

rsp = client.get('/api/v2/topics');
rsp = client.post('/api/v2/topics', '{"name":"My new Topic"}');
rsp = client.patch('/api/v2/topics/1', '{"name":"My updated Topic"}');
rsp = client.destroy('/api/v2/topics/1');
```

## Working with Resources and Collections

The API supports RESTful resources and so does this wrapper. These resources are automatically discovered, meaning you can navigate around without having to worry about anything.

### Initial Collection

Using the client we created earlier you can easily request the initial collection you want to work with.

```
DeskResource res = client.getResource('cases');
```

### Finders

The method `find` can be called on all `DeskResource` instances and will return a lazy loaded instance of the resource. _Gotcha:_ It will rebuild the base path based on the resource/collection it is called on. So if you call it on the cases collection `client.getResource('cases').find(1)` the path will look like this: `/api/v2/cases/:id`.

| Method                                                                           | Path                        |
| -------------------------------------------------------------------------------- | --------------------------- |
| `client.getResource('cases').find(1)`                                            | `/api/v2/cases/1`           |
| `client.getResource('cases').search('Test').find(1)`                             | `/api/v2/cases/1`           |
| `client.getResource('cases').getEntries().get(0).getResource('replies').find(1)` | `/api/v2/cases/1/replies/1` |

### Pagination

As mentioned above you can also navigate between resources and pages of collections. However you'll have to request the `entries` before you can loop through all the records on the page.

```
DeskResource cases = client.getResource('cases');
for (DeskResource myCase : cases.getEntries()) {
  // do something with the case
}

// now move on to the next page
DeskResource nextPage = cases.getResource('next');
for (DeskResource myNextPageCase : nextPage.getEntries()) {
  // do something with the case
}

// go back to the previous page
DeskResource previousPage = nextPage.getResource('previous');

// or go to the last page
DeskResource lastPage = previousPage.getResource('last');

// or go to the first page
DeskResource firstPage = lastPage.getResource('first');
```

### Links

Pagination is pretty obvious but the cool part about pagination or rather resources is the auto-linking. As soon as the resource has a link defined, it'll be navigatable:

```
// get the customer of the first case of the first page
DeskResource customer = client.getResource('cases').getEntries().get(0).getResource('customer');
```

### Lazy loading

Collections and resources in general are lazily loaded, meaning if you request the cases `client.getResource('cases')` no actual request will be set off until you actually request data. Only necessary requests are sent which will keep the request count low - [desk.com rate limit](http://dev.desk.com/API/using-the-api/#rate-limits).

```
DeskResource cases = client.getResource('cases').page(10).perPage(50);
for (DeskResource myCase : cases.getEntries()) {
  // in this method chain `getEntries' is the first method that acutally sends a request
}

// however if you request the current page numer and the resource is not loaded
// it'll send a request
System.assertEquals(1, client.getResource('cases').page());
```

### Side loading

APIv2 has a lot of great new features but the one I'm most excited about is side loading or embedding resources. You basically request one resource and tell the API to embed sub resources, eg. you need cases but also want to have the `assigned_user` - instead of requesting all cases and the `assigned_user` for each of those cases (30 cases = 31 API requests) you can now embed `assigned_user` into your cases list view (1 API request).

Of course we had to bring this awesomeness into the API wrapper as soon as possible, so here you go:

```
// fetch cases with their respective customers
DeskResource cases = client.getResource('cases').embed('customer');
DeskResource customer = cases.getEntries().get(0).getResource('customer');
```

### Create, Update and Delete

Of course we support creating, updating and deleting resources but not all resources can be deleted or updated or created, if that's the case for the resource you're trying to update, it'll throw a `DeskApi::Error::MethodNotAllowed` error. For ease of use and because we wanted to build as less business logic into the wrapper as possible, all of the methods are defined on each `DeskApi::Resource` and will be sent to desk.com. However the API might respond with an error if you do things that aren't supported.

```
// let's create an article
DeskResource newArticle = client.getResource('articles').create(new Map<String, Object>{
  'subject' => 'Some Subject',
  'body' => 'Some Body',
  '_links' => new Map<String, Object>{
    'topic' => new Map<String, Object>{
      'href' => '/api/v2/topics/1'
    }
  }
});

// updating the article
DeskResource updatedArticle = newArticle.update(new Map<String, Object>{
  'subject' => 'Updated Subject'
});

// deleting the article
if (updatedArticle.destroy()) {
  // article has been deleted
}
```

### Getter & Setter

As you have seen in prior examples we use the `getResource' getter to get links and embedded resources. For fields you can use `get' and `set' however you'll have to typecast the return value.

```
DeskResource customer = client.getResource('customers').find(1);

System.debug(customer.get('first_name'));
System.debug(customer.get('last_name'));
System.debug(customer.get('title'));

Map<String, String> customFields = (Map<String, String>)customer.get('custom_fields');

// for updates you can either use the setter or a map

customer.set('first_name', 'John');
customer.set('last_name', 'Doe');

DeskResource updatedCustomer = customer.update(new Map<String, Object>{
  'title' => 'Master of the Universe'
});
```

## License

(The MIT License)

Copyright (c) 2013 Thomas Stachl &lt;thomas@desk.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
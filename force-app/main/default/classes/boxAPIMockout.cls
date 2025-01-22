@isTest
public class boxAPIMockout implements HttpCalloutMock{
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        if (req.getEndpoint().contains('/2.0/folders')) {
            // Mock response for folder details
            if(req.getMethod() == 'POST' || req.getMethod()=='PUT'){
                res.setStatusCode(201);
                res.setBody('{"id":"12345", "name":"Test Folder"}');
            } else if(req.getMethod() == 'GET'){
                res.setStatusCode(200);
                res.setBody('{"id":"12345", "name":"Test Folder", "item_collection":{"total_count":2, "entries":[{"id":"1", "name":"File1"},{"id":"2", "name":"File2"}]}}');
            }
        } else if (req.getEndpoint().contains('/2.0/files/')) {
            // Mock response for file details
            res.setStatusCode(201);
            res.setBody('{"id":"67890", "name":"Test File", "size":2048}');
        }
        else if (req.getEndpoint().contains('/recaptcha/api')) {
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "score": 0.9, "action": "test_action"}');
            res.setStatusCode(200);
        } 
        else {
            // Default response for unknown endpoints
            res.setStatusCode(404);
            res.setBody('{"error":"Not Found , '+req.getEndpoint()+'"}');
        }

        return res;
    }  


   

}
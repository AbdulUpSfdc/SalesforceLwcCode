@isTest
global class BopisHttpCalloutMock implements HttpCalloutMock {
    
    protected Integer code;
    protected String bodyAsString;
    public BopisHttpCalloutMock(Integer code, String body){
        this.code = code;
        this.bodyAsString = body;
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(bodyAsString) ;
        response.setStatusCode(code);
        return response; 
    }

}
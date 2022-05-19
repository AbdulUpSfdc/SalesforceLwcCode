/*
    Represents a non-success result from an HTTP call.
*/
public with sharing class BWC_HttpException extends System.Exception {

    public HttpRequest request;         // Request that caused exception
    public HttpResponse response;       // The response
    public Integer statusCode;          // Http status code
    public String status;               // Description of status code
    public APILoggings__c apiLog;       // Any associated API log

    /*
        Construct from the request and its response.
    */
    public BWC_HttpException(System.HttpRequest request, System.HttpResponse response) {

        this.request = request;
        this.response = response;

        this.statusCode = response.getStatusCode();
        this.status = response.getStatus();

        String message = String.valueOf(this.statusCode);
        if (String.isNotEmpty(this.status)) {
            message += ' ' + this.status;
        }
        String responseBody = response.getBody();
        if (String.isNotEmpty(responseBody)) {
            message += ' ' + responseBody;
        }
        this.setMessage(message);

    }

    /*
        Construct from request and exception received while trying to get response.
    */
    public BWC_HttpException(System.HttpRequest request, System.Exception caughtException) {

        this.request = request;

        this.setMessage(caughtException.getMessage());
        this.initCause(caughtException);

    }

}
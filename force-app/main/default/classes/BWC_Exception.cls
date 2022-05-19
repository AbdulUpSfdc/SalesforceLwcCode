/*
    Custom throwable exception.
*/
public with sharing class BWC_Exception extends System.Exception {

    public String code;                 // Unique exception code
    public String requestContext;
    public String responseContext;

    public BWC_Exception(String message, String code) {
        this.setMessage(message);
        this.code = code;
    }

    public BWC_Exception(String message, String requestContext, String responseContext) {
        this.setMessage(message);
        this.requestContext = requestContext;
        this.responseContext = responseContext;
    }

}
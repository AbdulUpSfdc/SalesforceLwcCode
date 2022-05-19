/*
    Error information returned in API payload indicating failure of one call.
*/
public with sharing class BWC_MuleServiceError {

    @AuraEnabled
    public String node {get; set;}

    @AuraEnabled
    public Integer code {get; set;}

    @AuraEnabled
    public String message {get; set;}

    @AuraEnabled
    public String description {get; set;}

    @AuraEnabled
    public String transactionId {get; set;}

    @AuraEnabled
    public String traceId {get; set;}

    @AuraEnabled
    public String idpTraceId {get; set;}

}
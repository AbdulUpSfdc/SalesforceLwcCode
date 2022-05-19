public with sharing class Case_Action_Constants {
    public static final String CLOSED = 'Closed';
    public static final String CANCELLED = 'Cancelled';
    public static final String PENDING_CLOSED = 'Pending Closed';
    public static final String NEW_STATUS = 'New';

    public static final Id FIELD_RECORDTYPE_ID = Schema.SObjectType.Case_Action__c.getRecordTypeInfosByDeveloperName().get('Field').getRecordTypeId();
    public static final Id RESPONSE_RECORDTYPE_ID = Schema.SObjectType.Case_Action__c.getRecordTypeInfosByDeveloperName().get('Response').getRecordTypeId();
    //thess match Label names for product values 
    //Adding DIRECTV STREAM because part of future refactor
    public static final list<String> VIDEO_PRODUCT_LIST = new list<String>{'DIRECTV','DirecTV Legacy','AT&T TV','DIRECTV STREAM','LEGACY DIRECTV'};

    public static final String RESPONSE_SENT = 'Response Sent';
    public static final String RESPONSE_RETURNED = 'Response Returned';

    public static final String Case_DEV_NAME = 'Case';
    public static final String Case_Action_DEV_NAME = 'Case_Action__c';
    //Queue names for oop response solution
    public static final String OOPInterimRegResMobility = 'OOPInterimRegResMobility';
    public static final String OOPRegResMobility = 'OOPRegResMobility';
    public static final String OOPInterimRegResOther = 'OOPInterimRegResOther';
    public static final String OOPRegRespOther = 'OOPRegRespOther';
    public static final String Consumer = 'Consumer';

    public static final String OverdueCasesActionsBatch_Query =
    'SELECT Id, Case__c, Days_To_Close__c, Status__c '+
    'FROM Case_Action__c '+
    'WHERE Is_Closed__c	 = FALSE '+
    'AND Days_To_Close__c < 0 '+
    'AND Case__r.OverdueChildCases__c = FALSE '+
    'AND RecordTypeId in (\''+ RESPONSE_RECORDTYPE_ID + '\', \'' + FIELD_RECORDTYPE_ID + '\')';


    public static final String OverdueTaskCasesActionsBatch_Query =
    'SELECT Id, WhatId, What.Type ' +
    'FROM Task '+
    'WHERE IsClosed = FALSE ' +
    'AND ActivityDate <= TODAY ' +
    'AND ' +
    'What.Type in (\'Case\',\'Case_Action__c\') ' +
    'ORDER BY WhatId ASC NULLS FIRST';
}
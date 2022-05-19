/* ================================================
* @class name: BWC_InteractionsWithActivitiesController
* @author: Salesforce Inc.
* @purpose: interaction history cmp controller
* @created date (mm/dd/yyyy) :  02/03/2021
================================================*/ 
//this is for the interaction history component
public with sharing class BWC_InteractionsWithActivitiesController {
    private static final String OFF_LINE = 'Offline';

    //Grab the Interactions tied to caller
    @AuraEnabled
    public static string getInteractionRecordList(string interactionId, string SOQLTimeFrame, string currentDateMilli){

        Datetime dt =BWC_InteractionsWithActivitiesController.handleDateFilterLogic(SOQLTimeFrame,currentDateMilli);
        string customerId = BWC_InteractionsWithActivitiesController.getCustomerId(interactionId);
        list<Interaction__c> interactionList = [
            SELECT id, Name, createdDate, Activity_Summary__c, Notes__c, Contact_Type__c, Interaction_Activity_Count__c, Case_Count__c, CreatedBy.Name , CreatedBy.ATTUID__c
            FROM Interaction__c
            WHERE Customer__c =: customerId
            AND (createdDate >: dt)
            WITH SECURITY_ENFORCED
        ];
       //for testing remove before deployment
       //theList.addAll(theList);theList.addAll(theList);theList.addAll(theList);
       
       interactionList = BWC_InteractionsWithActivitiesController.removeOfflineWithoutCase(interactionList);     

       return JSON.serialize(interactionList);
    }
    //support method for getInteractionRecordList
    public static string getCustomerId(string interactionId){
        string returnValue = null;
        list<Interaction__c> theList = [
            SELECT id, Customer__c
            FROM Interaction__c
            WHERE id =: interactionId
            LIMIT 1
        ];
        if(!theList.isEmpty()){
           returnValue = theList[0].Customer__c;
        }
        return returnValue;
    }
    public static Datetime handleDateFilterLogic(string SOQLTimeFrame,string currentDateMilli){
        datetime myDateTime = null;
        Datetime currentDate = DateTime.newInstance(long.valueOf(currentDateMilli));
    
        long millisInMonth = 2678400000L;
        long millisIn3Months = millisInMonth * 3;
        long millisInYear = millisInMonth * 12;
        

        switch on SOQLTimeFrame {
            when '3 months' {
             myDateTime = DateTime.newInstance(currentDate.getTime() - millisIn3Months);
            }
            when '1 year' {
                myDateTime = DateTime.newInstance(currentDate.getTime() - millisInYear);
            }            
            when 'all time' {
                myDateTime = DateTime.newInstance(000000000l);
            }
         }
         return myDateTime;
    }
    //Gets all Interaction Activity and related case records for an Interaction
    @AuraEnabled
    public static string getRelatedRecords(string interactionId){

        list<Interaction_Activity__c> activityList = [
            SELECT name , createdDate , case_Type__c , Feature__c , Feature_Sub_Type__c, Detail_Record__c , CreatedBy.Name , CreatedBy.ATTUID__c
            FROM Interaction_Activity__c
            WHERE Interaction__c =: interactionId
            WITH SECURITY_ENFORCED
        ];

        list<Case_Interaction__c> caseList= [
            SELECT 
                id, name,CreatedDate,Case__r.Feature_Escalation__c, Case__r.Feature_Sub_Type__c, Case__r.CloseNotes__c, 
                Case__r.CreatedBy.Name, Case__r.CreatedBy.ATTUID__c, Case__r.Case_Type__c, Case__r.CreatedDate, Case__r.CaseNumber , 
                Case__r.Type, Case__r.Origin, Case__r.Status 
            FROM Case_Interaction__c 
            WHERE Interaction__c =: interactionId
            WITH SECURITY_ENFORCED
        ];    

        list<object> lst = new list<object>();

        for(Case_Interaction__c theCase : caseList){
            lst.add(theCase);
        }
        for(Interaction_Activity__c activityRecord : activityList){
            lst.add(activityRecord);
        }
        
        return JSON.serialize(lst);
    }
    public static list<Interaction__c> removeOfflineWithoutCase(list<Interaction__c>  interactionList){
        list<Interaction__c> returnList = new list<Interaction__c>();
        for (Integer i = 0; i < interactionList.size(); i++) {
            if(interactionList[i]?.Contact_Type__c == OFF_LINE && interactionList[i]?.Case_Count__c == 0){continue;}
            returnList.add(interactionList[i]);
        }
        return returnList;

    }
    //getting picklist values for the filter dropdown on client 
  /*  @AuraEnabled
    public static string getFilterListsValues(String objectName, String fieldName){

   // String objectName = 'Contact';
   // String fieldName ='LeadSource';
      
    Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
    Schema.DescribeSObjectResult r = s.getDescribe() ;
    Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
    Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry pickListVal : ple){
        System.debug(pickListVal.getLabel() +' '+pickListVal.getValue());
    }       
    return JSON.serialize(ple);
 
    }*/
}
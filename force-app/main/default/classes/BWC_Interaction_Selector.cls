/* ================================================
* @class name: BWC_Interaction_Selector
* @author: Salesforce Inc.
* @purpose: Selector layer apex class
* @created date (mm/dd/yyyy) :  03/20/2021
================================================*/ 
public with sharing class BWC_Interaction_Selector {

    public static Interaction__c getInteraction(string intId){
        
        list<Interaction__c> returnValue = [
                      SELECT id , Is_Authorized__c, CTI_Call_Identifier__c, Wireless_Authorization_Level__c
                      FROM Interaction__c
                      WHERE id =: intId 
                      LIMIT 1];
        return (returnValue.IsEmpty())?null:returnValue[0];            
    }

}
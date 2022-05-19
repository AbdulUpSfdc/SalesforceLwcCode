/*
    Class Name # CaseInteractionUtility
    Purpose # includes logic for Case interactions
    
*/    

public without sharing class CaseInteractionUtility{

    // Method to check and create new Case Interactions
    Public static void checkCreateCaseInteractions(Map<Id,Case> cases){
        List<Case_Interaction__c> newCaseInteractions = new List<Case_Interaction__c>();
        Set<String> caseInteractionsSet = new Set<String>();

        Set<Id> interactionIds = new Set<Id>();
        for(Case currentCase : cases.values()){
            //Get all interaction Ids
            interactionIds.add(currentCase.Last_Interaction__c);
        }

        if(interactionIds.size()>0){
            //Retrieve existing case interactions
            Map<Id,Case_Interaction__c> caseInteractionMap = new Map<Id,Case_Interaction__c>([Select Id, Case__c, Interaction__c from Case_Interaction__c where Case__c IN :cases.keySet()
                                                                        AND Interaction__c IN :interactionIds]);
            //Creating a map with Case ID and interaction Id
            Map<String,Case_Interaction__c> caseInteractions = new Map<String,Case_Interaction__c>();
            if(caseInteractionMap != Null){
                for(Case_Interaction__c ci : caseInteractionMap.values()){
                    caseInteractions.put(ci.Case__c+'-'+ci.Interaction__c,ci);
                }
            }

            for(Case c : cases.values()){
                //check whether case interaction exist or not and then initates a new case interaction record
                if((caseInteractions != Null && !caseInteractions.containsKey(c.Id+'-'+c.Last_Interaction__c)) || caseInteractions == Null){
                    if((caseInteractionsSet != Null && !caseInteractionsSet.contains(c.Id+'-'+c.Last_Interaction__c)) || caseInteractionsSet == Null){
                        newCaseInteractions.add(new Case_Interaction__c(Case__c = c.Id,Interaction__c = c.Last_Interaction__c));
                        caseInteractionsSet.add(c.Id+'-'+c.Last_Interaction__c);
                    }
                }
            }
            if(newCaseInteractions != Null){
                //inserting new Case Interactions
                insert newCaseInteractions;
            }
        }

    }
}
/* ================================================* 
* @date :   4/20/2021   
* @group : Event
* @description : Helper class to drive the logic related to Events
================================================*/

public without sharing class EventTriggerHelper {

    //After Insert + After Update
    public static void filterEventAfterInsertUpdate(){
        
        String case_prefix = Schema.SObjectType.Case.getKeyPrefix();   
        String evtWhatId; 
        Set<ID> caseIds = new Set<ID>();

        for(Event evt: (List<Event>)trigger.new){
            evtWhatId = evt.WhatId;
            if(String.isNotBlank(evt.WhatId) && evtWhatId.startsWith(case_prefix)){
                caseIds.add(evt.WhatId);
            }
        }
        
        //update last activity date on OOP Case records 
        if(caseIds.size()>0){
            CaseOOP_Service.updateLastActivityonCase(caseIds);
        }
    }    

    
}
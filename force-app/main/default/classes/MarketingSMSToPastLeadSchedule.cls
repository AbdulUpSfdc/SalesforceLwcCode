/*
* This Schedule class calls the 'MarketingSMSToPastLeadBatch' on the Business days
* Test class : MarketingSMSToPastLeadSchedule_Test
* Author: Madhava Allam
* Created Date: 8/12/2021 
*/

global without sharing class MarketingSMSToPastLeadSchedule implements Schedulable {
    
    
    public void execute(SchedulableContext sc){
        set<String> eligibileStatesSet = new set<String>();
        for(BusinessHours stateName : [SELECT Id,Name FROM BusinessHours WHERE IsActive = true]) {
            if(BusinessHours.isWithin(stateName.id,system.now())) {
                eligibileStatesSet.add(stateName.Name);
            }
        }
        if(!eligibileStatesSet.isEmpty()) {
            MarketingSMSToPastLeadBatch batchObj = new MarketingSMSToPastLeadBatch();
            batchObj.eligibileStatesSet = eligibileStatesSet;
            if(Test.isRunningTest()) {
                batchObj.eligibileStatesSet = new set<string>{'TX'};
            }
            Database.executeBatch(batchObj,1);
        }

    }
}
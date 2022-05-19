/*
 *  @Author     :SF
 *  @File Name  : CaseOOPOwnerUpdateHandler
 *  @Version    : V0.0
 *  @Description: This Class contains Case related logic
 *  @TestClass  : CaseOwnerAssignmentHelperTest
 *  @History
 * 
 */
 

global with sharing class CaseOOPOwnerUpdateHandler{
    
    //Method use by Process builder only at the time of OOP UPDATE  
    @InvocableMethod 
    public static void readyforOOPQueue(List<Id> caseIdList){
        List<Id> cIds = new List<Id>();
        String caseOwnerId;
        for(Case c : [Select id,OwnerId from Case where Id IN :caseIdList]){
            caseOwnerId = c.OwnerId;
            System.debug('!!!$$$$*** old owner '+c.OwnerId);
            System.debug('!!!$$$$*** case id'+c.Id);
            if(caseOwnerId.startsWith(CaseConstants.OOP_QUEUE_OWNER_CHECK )){
                cIds.add(c.Id);
            }    
        }
        
        if(!cIds.isEmpty()){
            CaseOwnerAssignmentHelper.initiateOOPCaseOwnerProcess(cIds,true);
        }
    } 
}
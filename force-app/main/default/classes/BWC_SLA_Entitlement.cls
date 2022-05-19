/* ================================================
* @class name: BWC_SLA_Entitlement
* @author: Salesforce Inc.
* @purpose: used to contain SLA / Entitlement logic 
* @created date (mm/dd/yyyy) :  12/03/2020
================================================*/ 
public class BWC_SLA_Entitlement {
    
 
    private static final BWC_Constants.SLA_Data SLA_Data = new BWC_Constants.SLA_DATA();
    
    
    //method used to map the SLA to case 
    public static string handleSLA(string escCaseType) {
        //Entitlement Id
        string returnValue = null;
        list<Entitlement> listOfRecords = new list<Entitlement>();

		
		list<BWC_CaseType_SLA_Mapping__mdt> myMeta = [select id, Entitlement_Name__c, Case_Type__c    
        	                                          from  BWC_CaseType_SLA_Mapping__mdt
            	                                      Where Case_Type__c  =: escCaseType];
        if(!myMeta.isEmpty()){
            
            listOfRecords = [SELECT id , Name From Entitlement where name =:myMeta[0].Entitlement_Name__c limit 1 ];
        }
        if(!listOfRecords.isEmpty()){
			returnValue = listOfRecords[0]?.id;
        }

		
                                         
        return returnValue;
    }  
    //method used to map the SLA to case 
    public static Boolean doesCaseHaveMilestones(id caseId) {
        Boolean returnValue = false;
        
        List<CaseMilestone> milestones = [SELECT Id, CompletionDate
        FROM CaseMilestone
        WHERE CaseId  =:caseId];

        if(!milestones.isEmpty()){
            returnValue = true;
        }
        return returnValue;
    }
    //returns entitlement based on name
    @TestVisible static string getEntitlement(string entitlementName) {
        string returnValue=null;
        
        
        
        list<Entitlement> SLAList = [select id, name from Entitlement]; 
        for(Entitlement e : SLAList){
            if(e.name.containsIgnoreCase(entitlementName)){
                returnValue = e.Id;
            }
        }
        return returnValue;
    }    
    /**
     * This method is used to complete open Case Milestones for the specified cases.
     */
    @InvocableMethod(label='Complete Open Milestones'
                     description='Completes open Case Milestone records for the specified Cases.'
                     category= 'Case')
    public static void completeOpenMilestones(List<Id> caseIds)
    {
        System.debug('EscalationCaseHelper::completeOpenMilestones() entered');
        System.debug('Cases to complete open milestones: ' + caseIds);
        // check if we have cases that have been assigned to a queue
        if (!caseIds.isEmpty())
        {
            // get the case milestones that are associated with the cases that were assigned to queues,
            // are the 'Internal' type, and are not completed so that we can complete these milestones
            List<CaseMilestone> openMilestones = [SELECT Id, CompletionDate
                                                  FROM CaseMilestone
                                                  WHERE CaseId IN :caseIds
                                                  AND IsCompleted = FALSE
                                                  AND (
                                                      MilestoneType.Name = :SLA_Data.SLA_INTERNAL OR
                                                      Case.IsClosed = TRUE
                                                  )];
            
            // loop through the open internal milestones
            for (CaseMilestone openMilestone : openMilestones)
            {
                // complete the milestone by setting the completion date to now
                // the 'Internal' milestone is configured for 'Independent' recurrence,
                // so when this one is completed, a new one is automatically created
                openMilestone.CompletionDate = DateTime.now();
            }
            
            // update the open milestones to completed
            Database.update(openMilestones);
        }
    }
}
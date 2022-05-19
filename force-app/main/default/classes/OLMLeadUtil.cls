/******************************************************************************************************
* @Class Name   : OLMLeadUtil
* @Version      : 1.0
* @Created Date : 9-16-2021
* @Description  : Util class to assign Lead to care Manager
* @Author       : Accenture
*
* Change Log:
* Date               Owner                          Description
* ============================================================================================================
* 9-13-2021          Soumitra (sc578a)              Initial Version
*
*
*******************************************************************************************************/
public class OLMLeadUtil{

   //Lead assignment done by this method
  public static List<Lead> reassignLeads(List<Lead> leadList, Map<String, Integer> employeeLeadCount){
        List<Lead> updateLead = new List<Lead>();
        AggregateResult[] groupedResults
            = [SELECT Owner__c, Count(Id)
               FROM Lead
               WHERE Status != 'Closed' AND Owner__c IN :employeeLeadCount.keySet()
               GROUP BY Owner__c];
        
        if(!groupedResults.isEmpty()){
            for (AggregateResult ar : groupedResults)  {
                String ATTUID = String.valueOf(ar.get('Owner__c'));
                Integer leadCount = Integer.valueOf(ar.get('expr0'));
                employeeLeadCount.put(ATTUID, leadCount);
            }
        }
        for (Lead l : leadList) {  
            Integer count = 0;
            String owner = null; 

            for (String userId : employeeLeadCount.keySet()) {
                System.debug('outside else if owner---> '+owner+'count--->'+count+' employeeLeadCount '+employeeLeadCount);
                System.debug('employeeLeadCount.get(userId) '+ employeeLeadCount.get(userId));
                
                if(owner == null) {
                    owner = userId;
                    count = employeeLeadCount.get(userId);
                    System.debug('if owner ==null owner---> '+owner+'count--->'+count);
                } else if (count > employeeLeadCount.get(userId)) {  
                    owner = userId;
                    count = employeeLeadCount.get(userId);
                    System.debug('owner---> '+owner+'count--->'+count);
                }
            }
            
            if(owner != null) {
                l.owner__c = owner;
                updateLead.add(l);
                count = count + 1;
                employeeLeadCount.put(owner, count);
            }
            
        }
        
        return updateLead; 
    }




}
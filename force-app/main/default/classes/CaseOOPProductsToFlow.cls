/* ================================================* 
* @date :   3/18/2021   
* @group : Case 
* @description : class to assign owner based on products
================================================*/


public Without Sharing class CaseOOPProductsToFlow{
  
  //Method to assign the owner to OOP Case 
  
  @InvocableMethod
  public static List<String> checkProductsOOP(List<Id> caseIds) {
    
    List<String> relatedQueuelst = new List<String>();
    //Retrieve case info
    List<Case> caselst = new List<Case>([Select Id,Priority,Product__c,OwnerId,Send_to_Intake_Queue__c,Product_Type_OOP__c,SubmissionSourceCode__c,Cust_Type__c,//CustomerType__c,
                                         Origin,ServiceEmail__c,ServicePhone__c,Description,
                     ServiceCustFirstName__c,ServiceCustLastName__c,StreetName__c,City__c,State__c,ZipPostalCode__c from Case where Id = :caseIds]);
                     
    if(caselst.size()==1){
        Case c = caselst[0];                 
                     
        List<String> productNameSet = new List<String>();
        if(String.isNotBlank(c.Product__c)){
            if(c.Product__c.Contains(';')){
                productNameSet = c.Product__c.split(';');
            }
            else{
                productNameSet.add(c.Product__c);
            }
        
        //retrieve Case Owner queue assignments
        List<OOP_Case_Owner_Queue_Assignment__mdt> assignments = 
                [SELECT Matching_Criteria__c, Order__c,Products__c, Queue__c FROM OOP_Case_Owner_Queue_Assignment__mdt ORDER BY Order__c ASC];
        
        Boolean isProdMatch = false;        
        if(!assignments.isEmpty()) {
            for(OOP_Case_Owner_Queue_Assignment__mdt qa : assignments){
                if(String.isNotBlank(qa.products__c)){
                    //check product matching
                    isProdMatch = getCompareVal(productNameSet, qa);
                    if(isProdMatch){                        
                        //Assign to DTV Intake Queue
                        if(String.isBlank(c.Description) || c.Send_to_Intake_Queue__c){
                            c.OwnerId = retrieveQueueId(qa.Queue__c); 
                        }
                        //Assign to DTV VIP Queue
                        else if(c.Priority.contains(CaseConstants.CASE_PRIORITY_VIP)){
                            c.OwnerId = retrieveQueueId(CaseConstants.OOP_QUEUE_DTVVIP);
                        }
                        //Assign to DTV High queue
                        else if(c.Priority.contains(CaseConstants.CASE_PRIORITY_HIGH) || c.Priority.contains(CaseConstants.CASE_PRIORITY_OUT_OF_SRV)){
                            c.OwnerId = retrieveQueueId(CaseConstants.OOP_QUEUE_DTVHIGH);
                        }
                        else{
                            //Assign to DTV Low Queue
                            c.OwnerId = retrieveQueueId(CaseConstants.OOP_QUEUE_DTVLOW);
                        }
                        c.Product_Type_OOP__c = CaseConstants.CASE_VIDEO_TYPE_OF_OOP;
                        relatedQueuelst.add(CaseConstants.CASE_QUEUE_MATCHWITHPRODUCTS);
                        break;
                    }
                }
            }
        }
    
        if(isProdMatch){
            update c;
        }
        else{
            relatedQueuelst.add(CaseConstants.CASE_QUEUE_NO_MATCHWITHPRODUCTS);
        }
       
       }
       else{relatedQueuelst.add(CaseConstants.CASE_QUEUE_NO_MATCHWITHPRODUCTS);}
    }
    else{relatedQueuelst.add(CaseConstants.CASE_QUEUE_NO_MATCHWITHPRODUCTS);}   
    
    return relatedQueuelst;
  }
  
  //Comparing products btween case and OOP Case owner queue record
  public static Boolean getCompareVal(List<String> caseProducts, OOP_Case_Owner_Queue_Assignment__mdt matchRule){
      
       List<String> ruleproducts = new List<String>(); 
       Set<String> caseProds = new Set<String>();
       Set<String> ruleProds = new Set<String>();
       
       if(matchRule.Products__c.contains(';')){
           ruleproducts = matchRule.Products__c.split(';');
       }
       else{
           ruleproducts.add(matchRule.Products__c);
       }
      
      caseProds.addAll(caseProducts);
      ruleProds.addAll(ruleproducts);
      
      String matchALLorANYbutNONE = 'All or Any (No Others)';
      
      if(matchRule.Matching_Criteria__c == matchALLorANYbutNone){
          if(ruleProds.containsAll(caseProds)){
              return TRUE; 
          }
      }
      
      return FALSE;
  }
  
  //retrieve Queue Id based on queue API name
  public static String retrieveQueueId(String queueName) {
        String queueId;
        List<Group> queues = [SELECT Id, Name FROM Group WHERE DeveloperName = :queueName AND Group.Type = 'Queue'];
        if(!queues.isEmpty()) {
            queueId = queues[0].Id;
         } 
        return queueId;
    }
  
}
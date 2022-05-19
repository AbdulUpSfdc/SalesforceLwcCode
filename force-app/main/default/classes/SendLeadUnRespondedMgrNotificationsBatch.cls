/**
 * @description       : Batch class to send Bell Notification for the Bulk Leads unread messages
 * @author            : Abdul Khan
 * @JIRA NO           : SPTSLSATT-42                      
**/
global class SendLeadUnRespondedMgrNotificationsBatch implements Database.Batchable<String>, Database.Stateful{
	
	public Map<String,Integer> leadsCountMap = new Map<String,Integer>();
    public Map<String,Set<String>> mapIdOwner = new Map<String,Set<String>>();
    public Map<String,Set<String>> mapCustomerName = new Map<String,Set<String>>();
    public Map<String,set<String>> mapUserIds = new Map<String,set<String>>();
    static final String Title = 'Unresponded Customer Messages';
      global SendLeadUnRespondedMgrNotificationsBatch (Map<String,Integer> leadsCountMap, Map<String,Set<String>> mapIdOwner, 
                                                      Map<String,Set<String>> mapCustomerName,
                                                      Map<String,set<String>> mapUserIds) {
                                                         this.leadsCountMap = leadsCountMap;
                                                         this.mapIdOwner = mapIdOwner;
                                                         this.mapCustomerName = mapCustomerName;
                                                         this.mapUserIds = mapUserIds;
                                                     }
    
	global Iterable<String>  start(Database.BatchableContext bc){
        
      return (Iterable<String>)leadsCountMap.keySet();
    }
    
    global void execute(Database.BatchableContext bc, list<String> storesSet){
	  String Body = '';
      String rep_Names = '';
      String customerNames = '';
      set<string> filteredUsername = new set<string>();
      Map<String, String> storeUserIdWithAllRep = new Map<String, String>();
        
      for(String str : storesSet){
        for(String own:mapIdOwner.get(str)){
          if(String.isNotBlank(rep_Names)){
            rep_Names = rep_Names+ ', ' +own;
            }else
            {
              rep_Names =own ;
                }
                  } 
				  
      storeUserIdWithAllRep.put(str,rep_Names);
	  rep_Names ='';                
                  }
				  
     for(String str : storesSet){
       if(mapUserIds.containsKey(str) && mapIdOwner.containsKey(str)){
          Body = 'Following reps have not responded to customers: '+ storeUserIdWithAllRep.get(str) ;      
          NotificationsHandler.sendNotification( '('+leadsCountMap.get(str)+') '+Title,Body,mapUserIds.get(str),userinfo.getUserId());
        }
        }	
    }
    
    global void finish(Database.BatchableContext bc){
       
    }
    }
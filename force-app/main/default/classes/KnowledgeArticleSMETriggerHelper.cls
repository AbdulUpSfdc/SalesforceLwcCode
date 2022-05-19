public with sharing class KnowledgeArticleSMETriggerHelper {
  
    public static final Integer MAX_NUM_RECORDS = 10;
    public static final String ERR_TOO_MANY_RECORDS = 'Cannot Add another SME, Maximum Limit of '+ MAX_NUM_RECORDS + ' SMEs per article has been reached';
    public static final string SME_CHECK='SME';
    public static void KnowledgeArticleSMECheckRec(List<BWKMArticleSME__c> bwKmArtls)  {
        try{          
      set<id> bwKmArtlSMEIds = new set<id>();
      Map<id,integer> smeCouneperArtcl = new Map<id,integer>();       
         for(BWKMArticleSME__c bwAr : bwKmArtls  ) 
         {    
            // if (bwAr.Role__c == SME_CHECK) 
             {
             	bwKmArtlSMEIds.add(bwAr.Knowledge_Article__c);
             }    
         }          
       // Map<Knowledge__kav,integer> smeCouneperArtcl = [select id, (select count(id) from Knowledge_Article_SMES__r) from Knowledge__kav where id=:bwKmArtlSMEIds];  
       for(Aggregateresult smeRT : [select count(id) cntsmeid, Knowledge_Article__C artclid from BWKMArticleSME__c where Knowledge_Article__C in :bwKmArtlSMEIds  group by Knowledge_Article__C])   
       {
           System.debug('Number of SMEs: ' + (integer)smeRT.get('cntsmeid'));
           if((integer)smeRT.get('cntsmeid')>=MAX_NUM_RECORDS) {
       		   System.debug('Too many SMES');
               smeCouneperArtcl.put((ID)smeRT.get('artclid'),(integer)smeRT.get('cntsmeid')); 
           }
       }
            
            system.debug('@@@@smeCouneperArtcl '+smeCouneperArtcl);
            if(smeCouneperArtcl.size()>0) {
                for(BWKMArticleSME__c smerecds:bwKmArtls) {
                    if(smeCouneperArtcl.get(smerecds.Knowledge_Article__C)!=null) {
                      smerecds.adderror(ERR_TOO_MANY_RECORDS); 
                  
                    }
                }   
            }   
                
            
         
        }
        catch(exception e) {
          String errMsg = 'There was a problem adding the SME records ' + e.getMessage();
            system.debug(errmsg);  
           //throw new KnowledgeException(errmsg);
             
        }
        
    }
    
}
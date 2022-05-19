public with sharing class KnowledgeArticleFollowUpdate {
    public void createEntitySubscription(){

        list<EntitySubscription> listESsToInsert = new list<EntitySubscription>();
        set<string> setContentSponsor = new set<String>();
        list<Knowledge__kav> listKavs = new list<Knowledge__kav>();
        map<String,Id> mapCSToUserId = new map<String,Id>();
        // Pull all Knowledge_kav records to update
        for(Knowledge__kav kav : [Select Id,KnowledgeArticleId,ContentSponsor__c from Knowledge__kav where ContentSponsor__c!='']) {
            setContentSponsor.add(kav.ContentSponsor__c);
            listKavs.add(kav);
        }

        for(User u : [Select Id,ATTUID__c from User where ATTUID__c IN: setContentSponsor ]){
            mapCSToUserId.put(u.ATTUID__c,u.Id);
        }

        for(Knowledge__kav kav : listKavs){
            system.debug('EntitySubscriptions:'+mapCSToUserId.get(kav.ContentSponsor__c));
            if(mapCSToUserId.get(kav.ContentSponsor__c) !=null){
                EntitySubscription es = new EntitySubscription();
                es.ParentId = kav.KnowledgeArticleId;
                es.SubscriberId = mapCSToUserId.get(kav.ContentSponsor__c);
                listESsToInsert.add(es);
            }
        }
        system.debug('EntitySubscriptions:'+listESsToInsert.size());
        if(listESsToInsert.size() > 0) {
            try{
                Database.insert(listESsToInsert,false);
            }
            catch(Exception e){
                system.debug('Exception:'+ e.getMessage());
            }

        }

    }
}
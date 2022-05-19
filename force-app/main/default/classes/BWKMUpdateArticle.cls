global class BWKMUpdateArticle implements Database.Batchable<sObject>, Database.Stateful{
    /*
Schedulable execute.
*/
    /* public void execute(SchedulableContext SC) {

Database.executeBatch(new BWKMUpdateArticle(),1);

}
*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        
        return Database.getQueryLocator([SELECT id,Article_Number__c,NewContentSponsor__c,Status__c,Article_ID__c,NewFRDDate__c from BW_KM_Logs__c where Status__c='Awaiting add content sponsor' ]);
    }
    
    global void execute(Database.BatchableContext BC, List<BW_KM_Logs__c> Article) {
        System.debug('No Of recods'+Article.size());
        list<string> PublishArticle =new list<string>();
        map<String,String> AticleNumberconsponser =new map<String,String>();
        map<string,date> NewFrddate =new map<string,date>();
        list<Exception__c> ex1=new list<Exception__c>();
        boolean Updatecontentsponser =false;
        boolean updatefrddate=false;
        for (BW_KM_Logs__c Km:Article)
        {                   
            //Add Article Number And New Content sponser to Map
            if(km.NewContentSponsor__c != null ){
                system.debug('new contentsponser to update'+km.NewContentSponsor__c);
                Updatecontentsponser=true;
            AticleNumberconsponser.put(Km.Article_Number__c,km.NewContentSponsor__c);
                }
            if(km.NewFRDDate__c != null )
            {
                system.debug('new frd to update'+km.NewFRDDate__c);
                updatefrddate=true;
             NewFrddate.put(km.Article_Number__c, km.NewFRDDate__c);  
            }
            PublishArticle.add(Km.Article_ID__c);
            
        }
        System.debug('No Of recods sent to make Draft'+PublishArticle.size());
        
        list<String>Articleid =new list<String>();
        map<String,Datetime> FutureReviewDate =new map<String,Datetime>();
        list<Knowledge__kav> publishArticleid = [SELECT Id, KnowledgeArticleId,ContentSponsor__c,ArticleNumber,FutureReviewDate__c FROM Knowledge__kav WHERE id IN:PublishArticle and PublishStatus = 'Online'];
        for(Knowledge__kav   kn :publishArticleid) 
        {
            //Pass Publish Article Id
            Knowledge__kav arti = (Knowledge__kav)kn;
            
            try{
                //Create Draft Article from Publish
                String id=KBManagement.PublishingService.editOnlineArticle(arti.KnowledgeArticleId,false);
                Articleid.add(id);
                System.debug('id of draft Articleid'+Articleid);
                FutureReviewDate.put(kn.ArticleNumber,kn.FutureReviewDate__c);
            }
            catch(System.Exception e){
                System.debug('Exception Draft article: ' + arti.ArticleNumber + ': ' + e);
                BWC_ExceptionUtils.handleException(e, true);
            }
            
        }
        
        list<Knowledge__kav> Frdupadte = new list<Knowledge__kav>();  
        list<Knowledge__kav> contentsponserupdate = new list<Knowledge__kav>();
        List< Knowledge__kav> newArticleid = [ SELECT Id, KnowledgeArticleId,ContentSponsor__c, CustomPublicationStatus__c,BWScheduledArticlePublicationDate__c,CustomValidationStatus__c,ArticleNumber,FutureReviewDate__c FROM Knowledge__kav WHERE id =: Articleid and PublishStatus = 'Draft'  ];  
        system.debug('List of draft article'+newArticleid.size());
        if(NewFrddate !=null || !NewFrddate.isEmpty() && updatefrddate==true ){
        for(Knowledge__kav NewDraftArticle : newArticleid)
        {
            
            for(string frdnewval:NewFrddate.keyset())
            {
                system.debug('frd date fom map ####'+frdnewval);
                if(string.valueOf(NewDraftArticle.ArticleNumber).endswith(frdnewval))
                { 
                    system.debug(' new frd to update if loop'+NewFrddate.get(frdnewval));
                   // datetime newdate =FutureReviewDate.get(frdnewval).format('MM-dd-yyyy');
                   //date frd =date.NewFrddate.get(frdnewval);
                    datetime fr = datetime.newInstance(NewFrddate.get(frdnewval).year(), NewFrddate.get(frdnewval).month(), NewFrddate.get(frdnewval).day(), 00, 00, 00);
                    system.debug(' after creating new instance of date '+fr);
                    NewDraftArticle.FutureReviewDate__c=fr;
                    NewDraftArticle.BWScheduledArticlePublicationDate__c=system.now();
                    NewDraftArticle.CustomPublicationStatus__c='Ready for Publication';
                    NewDraftArticle.CustomValidationStatus__c=True;
                    contentsponserupdate.add(NewDraftArticle);
                    //Copy Makets From Publish Article 
                    CopyMarketController CM =new CopyMarketController();
                    CopyMarketController.copyMarket(NewDraftArticle.id);
                    // Update link Dependency From Publish Article
                    BWArticlePublishPlatformEventHelper LinkDependency = new BWArticlePublishPlatformEventHelper();
                    BWArticlePublishPlatformEventHelper.publishPlatformEvent(NewDraftArticle.id);
                }
            }
                }
        }
        if(AticleNumberconsponser != null || !AticleNumberconsponser.isEmpty() && Updatecontentsponser==true){
            for(Knowledge__kav NewDraftArticle : newArticleid)
        {
            
            for(String mapvalue:AticleNumberconsponser.keyset()){
                if(String.valueOf(NewDraftArticle.ArticleNumber).endsWith(mapvalue))
                {
                    
                    system.debug('content sponser to update'+mapvalue);
                    NewDraftArticle.ContentSponsor__c=AticleNumberconsponser.get(mapvalue );
                    NewDraftArticle.BWScheduledArticlePublicationDate__c=system.now();
                    NewDraftArticle.CustomPublicationStatus__c='Ready for Publication';
                    NewDraftArticle.CustomValidationStatus__c=True;
                    //Check FRD is Past/feture and then Update   
                    for(String articlenumber :FutureReviewDate.keyset())
                    {
                        DateTime CurrentTime = System.now();
                        if(FutureReviewDate.get(articlenumber) >=CurrentTime) { 
                            system.debug(' future date');
                            NewDraftArticle.FutureReviewDate__c=FutureReviewDate.get(articlenumber);
                            
                        }
                        else
                        {
                            
                            NewDraftArticle.FutureReviewDate__c=system.now().addDays(4);
                            // FRD.FutureReviewDate__c.addMonths(now(),6);
                            //system.debug('Add date to Six month from now');
                        }
                    }
                    contentsponserupdate.add(NewDraftArticle);
                    //Copy Makets From Publish Article 
                    CopyMarketController CM =new CopyMarketController();
                    CopyMarketController.copyMarket(NewDraftArticle.id);
                    // Update link Dependency From Publish Article
                    BWArticlePublishPlatformEventHelper LinkDependency = new BWArticlePublishPlatformEventHelper();
                    BWArticlePublishPlatformEventHelper.publishPlatformEvent(NewDraftArticle.id);
                    system.debug('content sponser final list to update'+contentsponserupdate);
                }
                
            }
        }
        }
        
        if(contentsponserupdate.size()>0)
        {	
            
            try{
            Database.SaveResult[] AticleContentSponserupdate = Database.update(contentsponserupdate, false);
               
               Integer count=0;
                for (Database.SaveResult sr : AticleContentSponserupdate) {
                    if(sr.isSuccess())
                    {
                        System.debug('Update successful '+contentsponserupdate[count].id);
                    }
                if (!sr.isSuccess()) {
                    
                for(Database.Error err : sr.getErrors()) {
                
                Exception__c ex = new Exception__c ();
                ex.Message__c=err.getMessage()+contentsponserupdate[count].id;
                ex.Cause__c=err.message;
                ex1.add(ex);
               
                 System.debug(err.getStatusCode() + ': ' + err.getMessage()+contentsponserupdate[count].id);
                 System.debug('Kmlogs fields that affected this error: ' + err.getFields());
                     
                    }
                    
                 count++;   
                }
                
            }
            }
            catch(Exception e)
            {
               System.debug('Update failed due to  '+e.getMessage());
            }
        }
        
        
        
        list <BW_KM_Logs__c> statusupdate = new list <BW_KM_Logs__c>();
        
        for (BW_KM_Logs__c AticleStatus:Article)
        {
            system.debug('KM logs finish'+AticleStatus);
            for (Knowledge__kav Updatestatus:newArticleid)  
            {
                system.debug('know finish'+Updatestatus);
                if(Updatestatus.ArticleNumber.endsWith(AticleStatus.Article_Number__c)){
                    system.debug('status update for');
                    AticleStatus.Status__c='Completed add content sponsor';
                }
            }
            statusupdate.add(AticleStatus);
        }
        if(statusupdate.size()>0)
        {
            
            Database.SaveResult[] StatusupdateKMlogs = Database.update(statusupdate, false);
            Integer count1=0;
            for (Database.SaveResult sr : StatusupdateKMlogs) {
                if(sr.isSuccess())
                {
                    System.debug('Update successful '+statusupdate[count1].id);
                }
                if (!sr.isSuccess()) {
                    
                     for(Database.Error err : sr.getErrors()) {
                         Exception__c ex = new Exception__c ();
                ex.Message__c=err.getMessage();
                ex.Cause__c=err.message;
                ex1.add(ex);
                        System.debug(err.getStatusCode() + ': ' + err.getMessage()+statusupdate[count1].id);
                        System.debug('Kmlogs fields that affected this error: ' + err.getFields());
                    }
                   count1++; 
                }
                
            }
            
                        
        }
        insert ex1;
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }            
}
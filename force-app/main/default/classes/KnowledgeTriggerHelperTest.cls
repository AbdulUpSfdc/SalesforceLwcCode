/***********
    Name         : KnowledgeTriggerHelperTest
    Description  : This is the Test class for the KnowledgeTrigger.
********/


@isTest
public class KnowledgeTriggerHelperTest {
    @testSetup 
    private static void testSetup(){
        //user prmusr = KM_TestDataFactory.createSysAdminUser();
       
        user prmusr = KM_TestDataFactory.createContentSponsorUser('12345');
        prmusr.FederationIdentifier = '12345';
        update prmusr;
        
         //user secusr = KM_TestDataFactory.createSysAdminUser();
         
        user secusr = KM_TestDataFactory.createContentSponsorUser('12354');
        secusr.FederationIdentifier = '12354';
        update secusr;
        
        user smeusr1 = KM_TestDataFactory.createContentSponsorUser('12534');
        smeusr1.FederationIdentifier = '12534';
                 smeusr1.email= 'ABCTestUser1@test.com';

        update smeusr1;
        
        user smeusr2 = KM_TestDataFactory.createContentSponsorUser('13524');
        smeusr2.FederationIdentifier = '13524';
                 smeusr2.email= 'ABCTestUser1@test.com';

        update smeusr2;
         user smeusr3 = KM_TestDataFactory.createContentSponsorUser('12514');
        smeusr3.FederationIdentifier = '12514';
         smeusr3.email= 'ABCTestUser1@test.com';
        update smeusr3;
        user smeusr4 = KM_TestDataFactory.createContentSponsorUser('13554');
        smeusr4.FederationIdentifier = '13554';
         smeusr4.email= 'ABCTestUser1@test.com';
        update smeusr4;
        
        //Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        
        /* bwMarticllst.removeall();
for(integer i=0;i<MAX_NUM_RECORDS;i++){
          bwMarticl = new BWKMArticleSME__c();
             bwMarticl.Knowledge_Article__c=knowledgekav.id;
             bwMarticl.Role__c='SME';
             bwMarticl.User__c=usr.id;
             bwMarticllst.add(bwMarticl);
            
        }*/
        
    }
    
    public static testmethod void  KnowledgeTriggerHelperTestmthd1(){
       
        //id knwldgarticleId = [select KnowledgeArticleId from Knowledge__kav].KnowledgeArticleId;
        List<Knowledge__kav> knowledgeList;
        final Integer MAX_NUM_RECORDS = 3;
    list<Knowledge__kav> kavlst = new list<Knowledge__kav>();
            Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true, 
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test1',
            ContentSponsor__c = '12345',
            BWSecContentSponsor__c ='12354',        
            CustomPublicationStatus__c = 'Ready for Publication',
            CustomValidationStatus__c = TRUE,
                      
            BWScheduledArticlePublicationDate__c = system.now().addHours(1)
        );
        try{
            insert knowledgeFrontlineOnly ;
           }catch(exception ex ){
                    
           }
        knowledgeList = [SELECT Id from knowledge__kav];
        System.assertEquals(knowledgeFrontlineOnly.Id, knowledgeList[0].Id);
        //query and Validatethe number of SMES associated with knowledgeFrontlineOnly artcile
    
       // Knowledge__kav knw = [select KnowledgeArticleId from Knowledge__kav where Id = :kavlst[0].id];
        //knowledgeFrontlineOnly.KnowledgeArticleId
        //the value for the second parameter needs to be true or we lose the original published article
        KbManagement.PublishingService.publishArticle([select KnowledgeArticleId from Knowledge__kav where Id=:knowledgeFrontlineOnly.id].KnowledgeArticleId, true);
         BWKMArticleSME__c bwMarticl=null;
          list<BWKMArticleSME__c> bwMarticllst = new list<BWKMArticleSME__c>();
       
        list<User> usr = [Select Id from User WHERE email = 'ABCTestUser1@test.com'];
        
        for(integer i=0;i<MAX_NUM_RECORDS;i++){
          bwMarticl = new BWKMArticleSME__c();
             bwMarticl.Knowledge_Article__c=knowledgeFrontlineOnly.id;
             bwMarticl.Role__c='SME';
             bwMarticl.User__c=usr[i].id;
             bwMarticllst.add(bwMarticl);
            
        }
        system.debug('@@@@@bwMarticllst '+bwMarticllst);
        List<BWKMArticleSME__c>  smeList = getSMES(knowledgeFrontlineOnly.Id);
		System.assertEquals(2, smeList.size());
        if(!bwMarticllst.isempty()) insert bwMarticllst;
		smeList = getSMES(knowledgeFrontlineOnly.Id);
		System.assertEquals(5, smeList.size());
        //create a draft version of the article you published (knowledgeFrontlineOnly);
        string drftid=KbManagement.PublishingService.editOnlineArticle ([select KnowledgeArticleId from Knowledge__kav where Id=:knowledgeFrontlineOnly.id].KnowledgeArticleId,false);
		Knowledge__kav draftArticle = getArticleById(drftid);
        knowledgeFrontlineOnly = getArticleById(knowledgeFrontlineOnly.Id);
        List<BWKMArticleSME__c> existingSME = [select id,Knowledge_Article__c,Role__c,User__c,Knowledge_Article__r.knowledgearticleid from BWKMArticleSME__c where Knowledge_Article__r.knowledgearticleid=:knowledgeFrontlineOnly.knowledgearticleid and Knowledge_Article__r.IsLatestVersion =true];
        System.debug('Existing SMEs for frontline article: ' + existingSME);
        knowledgeList = getArticles();
        System.assertEquals(knowledgeList[0].IsLatestVersion, true);
        System.assertEquals(knowledgeList[0].Id, knowledgeFrontlineOnly.Id);
        System.assertEquals(draftArticle.KnowledgeArticleId, knowledgeFrontlineOnly.KnowledgeArticleId);
        System.assert(draftArticle.Id != null);
                 user smeusr3 = KM_TestDataFactory.createContentSponsorUser('12333');
        smeusr3.FederationIdentifier = '12333';
         smeusr3.email= 'ABCTestUser1@test.com';
        update smeusr3;
        user smeusr4 = KM_TestDataFactory.createContentSponsorUser('13555');
        smeusr4.FederationIdentifier = '13555';
         smeusr4.email= 'ABCTestUser12@test.com';
        update smeusr4;
        
        draftArticle.ContentSponsor__c='12333';
        draftArticle.BWSecContentSponsor__c='13555';
        //KM_TestDataFactory.createContentSponsorUser('ja4118');
        update draftArticle;
        System.debug('Draft article: ' + draftArticle);
        knowledgeList = getArticles();
        
        System.assertEquals(2,  knowledgeList.size());
        System.assertEquals(draftArticle.Id, knowledgeList[1].Id);
        System.assertEquals(knowledgeFrontlineOnly.Id, knowledgeList[0].Id);
  
        smeList = getSMES(drftid);
		System.assertEquals(5, (smeList.size()));
      
        
    } 
    
    public static testMethod void testInvalidATTIUD() {
        Boolean hasError = false;
        Knowledge__kav  article = new Knowledge__kav(BW_Is_Urgent__c =  true,
                                                     BW_Home_Page_Display__c = true,
                                                     Title = 'Assigned-Test',
                                                     UrlName = 'Assigned-Test1',
                                                     ContentSponsor__c = 'attuid',
                                                     BWSecContentSponsor__c ='att_uid'
                                                     );
         
        try{
            KM_TestDataFactory.createContentSponsorUser('attuid');
            insert article;
        }
        catch(exception e){
            hasError = true;
        }
        system.assertEquals(false, hasError );
    }
    
    public static testMethod void testSecondaryContentSponsorDeletion(){
        Boolean hasError = false;
        Knowledge__kav  article = new Knowledge__kav(BW_Is_Urgent__c =  true,
                                                     BW_Home_Page_Display__c = true,
                                                     Title = 'Assigned-Test',
                                                     UrlName = 'Assigned-Test1',
                                                     ContentSponsor__c = '12345',
                                                     BWSecContentSponsor__c ='12354'
                  
                                                    );
        
        insert article;
        List<BWKMArticleSME__c> smeAdded = getSMES(article.Id);
        //	assert that Primary CS & Secondary CS got added
        system.assertEquals(2, smeAdded.size());
        
        //	update article
        article.BWSecContentSponsor__c = '';
        update article;
        
        //	assert that Secondary Content Sponsor got deleted
        List<BWKMArticleSME__c> smeList = getSMES(article.Id);
        system.assertEquals(1, smeList.size());
        system.assertEquals('Primary Content Sponsor', smeList[0].Role__c);
        
        //	try to update Primary CS & Secondary CS to an invalid value
        article.BWSecContentSponsor__c = 'attuid';
        article.ContentSponsor__c = 'att_uid';
        try{
            update article;
        }
        catch(exception e){
            hasError = true;
        }
        system.assertEquals(false,hasError);
        
        //	add a secondary CS
        article.ContentSponsor__c = '12345';
		article.BWSecContentSponsor__c = '12354';
        update article;
        
        //	assert that Secondary Content Sponsor got added
        List<BWKMArticleSME__c> updatedSMEList = getSMES(article.Id);
        system.assertEquals(2, updatedSMEList.size());
        Integer numSecondaryCS = [Select count() from BWKMArticleSME__c  where Knowledge_Article__c = :article.Id AND Role__c = 'Secondary Content Sponsor'];
        System.assertEquals(1, numSecondaryCS);
    }
    
    public static List<BWKMArticleSME__c> getSMES(Id knowledgeId) {
        return [Select Id, Role__c from BWKMArticleSME__c  where Knowledge_Article__c = :knowledgeId];
    }
    
    public static Knowledge__kav getArticleById(Id knowledgeId) {
        return [Select Id, KnowledgeArticleId, IsLatestVersion, PublishStatus from Knowledge__kav where Id = :knowledgeId];
        
    }
    
     public static List<Knowledge__kav> getArticles() {
        return [Select Id, KnowledgeArticleId, IsLatestVersion, PublishStatus from Knowledge__kav order by createdDate asc];
    }
     
    
}
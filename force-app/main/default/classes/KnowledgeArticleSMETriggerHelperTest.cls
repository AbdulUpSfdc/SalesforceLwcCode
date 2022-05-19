@istest
public class KnowledgeArticleSMETriggerHelperTest {
    
    /* @testsetup 

public static void setupDataKwSME(){
List<Knowledge__kav> KnwArchlst = new List<Knowledge__kav>();
Profile p = [Select Id,Name from Profile where Name='System Administrator'];
User u = new user();
u.Username = 'Test1' + '@test'+ '.org';
u.Email = 'test@KM.com';
u.Alias = 'tsamp';
u.ProfileId = p.Id;
u.FederationIdentifier = 'abTest12';
u.IsActive = true;
u.UserPermissionsKnowledgeUser = true;
u.LastName ='test';
u.TimeZoneSidKey ='GMT';
u.LocaleSidKey ='en_US';
u.EmailEncodingKey ='UTF-8';
u.LanguageLocaleKey ='en_US';
insert u;

}*/
    public static testmethod void KnowledgeArticleSMECheckRecMTest(){
        Knowledge__kav knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        System.debug('SMEs after Knowledge Insert' + [select id,Knowledge_Article__c, Role__c from BWKMArticleSME__c]);
        user usr = KM_TestDataFactory.createSysAdminUser();
        //[SELECt ID from user where Profile.Name = 'System Administrator' limit 1].id;
        BWKMArticleSME__c bwMarticl;  
        Exception expectedException;
        list<BWKMArticleSME__c> bwMarticllst = new list<BWKMArticleSME__c>();
        for(integer i=0;i<KnowledgeArticleSMETriggerHelper.MAX_NUM_RECORDS;i++){
            bwMarticl = new BWKMArticleSME__c();
            bwMarticl.Knowledge_Article__c=knowledgekav.id;
            bwMarticl.Role__c='SME';
            bwMarticl.User__c=usr.id;
            bwMarticllst.add(bwMarticl);
            
        }
        
        try { 
            insert bwMarticllst;
            system.debug('SMEs after INSERT IN TEST ::: ' + bwMarticllst.size());
            List<BWKMArticleSME__c> smeList = [Select Id, Role__c from BWKMArticleSME__c WHERE Role__c = 'SME'AND Knowledge_Article__c =:knowledgekav.Id ];
            //System.assertEquals(KnowledgeArticleSMETriggerHelper.MAX_NUM_RECORDS, smeList.size());
        } catch (Exception e) {
            expectedException = e;
        }
        System.assertEquals(null,  expectedException);
        expectedException = null;
        
        //bwMarticllst  = [select id,Knowledge_Article__c from BWKMArticleSME__c WHERE Role__c = 'SME' AND Knowledge_Article__c =:knowledgekav.Id ];
        
        bwMarticl = new BWKMArticleSME__c();
        bwMarticl.Knowledge_Article__c=knowledgekav.id;
        bwMarticl.Role__c='SME';
        bwMarticl.User__c=usr.id;
        try { 
            insert  bwMarticl;
        } catch (Exception e) {
            expectedException = e;
        }      
        System.assertNotEquals(null,  expectedException);
        System.assert(expectedException.getMessage().contains(KnowledgeArticleSMETriggerHelper.ERR_TOO_MANY_RECORDS));      
        bwMarticllst  = [select id,Knowledge_Article__c from BWKMArticleSME__c ];
        //System.assertEquals(KnowledgeArticleSMETriggerHelper.MAX_NUM_RECORDS, bwMarticllst.size());
        //KnowledgeArticleSMETriggerHelper.KnowledgeArticleSMECheckRec(bwMarticllst);   
        
        
    }
    
}
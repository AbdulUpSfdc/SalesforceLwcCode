@isTest
public class knowledgeResetFRDControllerTest {
    public static final String ROLE_NAME = 'TestingTeam';
    private static final String DATE_FORMAT = 'ssSSS';
    @testSetup
    public static void testData(){
       User u = KM_TestDataFactory.createContentSponsorUser('rt12345'); 

        Knowledge__kav  knowledgeFrontlineOnly = new Knowledge__kav(
            BW_Is_Urgent__c =  false,
            BW_FrontLine_Focus__c = true,
            Title = 'Frontline-Test-fromline',
            UrlName = 'Frontline-Test-fromline',
            ContentSponsor__c = u.ATTUID__c,
            FutureReviewDate__c = System.NOW().addmonths(36)
        );
        insert knowledgeFrontlineOnly;
    }
    
    public static String generateEmail() {
        String orgId = UserInfo.getOrganizationId();
        String seconds = system.now().format(DATE_FORMAT);
        return orgId + seconds + '@att.test.com';
    }  
    
     public static testmethod void testUnitOne(){
        Knowledge__kav knw = [SELECT Id,FutureReviewDate__c from Knowledge__kav WHERE Title = 'Frontline-Test-fromline'];
        system.debug('Test knw'+knw);
         
        try {
            knowledgeResetFRDController.getKnowledge(knw.Id);
        } catch (AuraHandledException e) {}
        
        
    }

}
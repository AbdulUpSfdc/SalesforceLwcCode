/***********
    Name            : BWArticleFeedbackHelper
    Description     : This is the test class for BWArticleFeedbackHelperTest.
    
***********/

@isTest
public class BWArticleFeedbackHelperTest{
    
     public static final String ROLE_NAME = 'TestingTeam';
     private static final String DATE_FORMAT = 'ssSSS';
    
    @testsetup
    public static void testData(){
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            UserRole userRole;
            userRole = new UserRole(DeveloperName = ROLE_NAME, Name = ROLE_NAME);
            insert userRole;
           	String  profileName = KM_Constants.AUTHOR_PROFILE;
            String emailName = generateEmail();
            
            u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id,
                LastName = 'last',
                FirstName = 'first',
                Email = emailName,
                Username = emailName,
                Alias = emailName.substring(18, 23),
                CompanyName = 'Testing',
                FederationIdentifier = 'ABCD',
                TimeZoneSidKey = 'America/Chicago',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                UserRoleId = userRole.Id
            );
            
            insert u;
        }
        
        //Create Record for RecordTypeName 'News Article'.
        Knowledge__kav  knowledge = new Knowledge__kav(
            BW_Is_Urgent__c =  true,
            BW_FrontLine_Focus__c = true,
            BW_Home_Page_Display__c = true,
            Title = 'Assigned-Test',
            UrlName = 'Assigned-Test',
            ContentSponsor__c = 'ABCD',
            BWSecContentSponsor__c = 'ABCD',
            BW_Article_Summary__c = 'askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf askdjfahksjdf',
            RecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('News_Article').getRecordTypeId()
        );
        insert knowledge;
         
        KM_Article_Feedback__c articleFeedback = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback; 
        KM_Article_Feedback__c articleFeedback1 = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback1; 
        KM_Article_Feedback__c articleFeedback2 = new KM_Article_Feedback__c(
            Feedback_Status__c = 'Replied',
            Feedback_Response__c = 'Improvement',
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback2; 
        KM_Article_Feedback__c articleFeedback3 = new KM_Article_Feedback__c(
            Reason__c = KM_Constants.REASON_ARTICLE_LIKE,
            Knowledge__c = knowledge.Id
        );
        INSERT articleFeedback3;
    }
   

    public static String generateEmail() {
		String orgId = UserInfo.getOrganizationId();
    	String seconds = system.now().format(DATE_FORMAT);
    	return orgId + seconds + '@att.test.com';
    }    
    
    public static testMethod void testUnitOne(){
        Map<Id, KM_Article_Feedback__c> articleFeedbackMap = new Map<Id, KM_Article_Feedback__c>();
        for(KM_Article_Feedback__c feedback: [
            SELECT Id, ArticleSponsorATTUID__c, Article_Secondary_Sponsor_ATT_UID__c 
            FROM KM_Article_Feedback__c
        ]){
            articleFeedbackMap.put(feedback.Id, feedback);
        }
        //BWArticleFeedbackHelper.updateSponsorEmail(articleFeedbackMap);
    }
    
    public static testMethod void feedbackBellNotificationTest(){
        List<KM_Article_Feedback__c> feedbackList = new List<KM_Article_Feedback__c>();
        for(KM_Article_Feedback__c feedback : [ SELECT Id, ArticleSponsorATTUID__c, Article_Secondary_Sponsor_ATT_UID__c 
            									FROM KM_Article_Feedback__c]) {
            feedback.Feedback_Response__c = 'Test Bell Notifications';
            feedbackList.add(feedback);
        }
        if(!feedbackList.isEmpty()){
            update feedbackList;
        }
    }
}
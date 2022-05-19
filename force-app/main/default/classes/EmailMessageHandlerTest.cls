@isTest
public class EmailMessageHandlerTest {
    @isTest
    public static void beforeInsertTest(){
        
        User u = KM_TestDataFactory.createAgentUser();
        User sysAdminUser = KM_TestDataFactory.createSysAdminUser();
        EmailMessage em;
        System.debug('User Info:'+u);
       
       	String emailList = 'test@salesforce.com';
            
        
        // Query from Organization-Wide Email Address  
        Id orgwideIdAddressId;
        String displayName = 'Message From AT&T';    
        String fromAddress;
        EmailTemplate validEmailTemplate;
        List<OrgWideEmailAddress> lstEmailAddress=[select Id, address, Displayname from OrgWideEmailAddress WHERE Displayname= :displayName];
       	Exception expectedException = null;
        if (!lstEmailAddress.isEmpty()) {
        	orgwideIdAddressId = lstEmailAddress[0].Id;
             fromAddress = lstEmailAddress[0].address;
        }
        system.runAs(sysAdminUser) {
            validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'name';
            validEmailTemplate.DeveloperName = 'ATT';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            insert validEmailTemplate;
        }
             
        
        system.runAs(u){

            em = new EmailMessage();
            
            
            KMEmail__c kmemail = KMEmail__c.getOrgDefaults();
            kmemail.Email__c = 'test@salesforce.com';
            upsert kmemail KMEmail__c.Id;
            
            KMProfile__c kmprofile = KMProfile__c.getOrgDefaults();
            kmprofile.RunEmailMessageTgr__c	 = True;
            upsert kmprofile KMProfile__c.Id;
            
            test.startTest();
            try{
                em.FromAddress = 'test@salesforce.com';
                em.EmailTemplateId = null;
                insert em;
                
            }catch(exception e) {
                System.debug('Error creating email: ' + e);
                expectedException = e;
                
            }
             System.assertNotEquals(null, expectedException);
			expectedException = null; 
            try{
                em.FromAddress = 'test@salesforce.com';
                em.EmailTemplateId = validEmailTemplate.Id;
                insert em;
                
            }catch(exception e) {
                System.debug('Error creating email: ' + e);
                expectedException = e;
                
            }
            System.assertNotEquals(null, expectedException);
            System.assertEquals(false, EmailMessageHandler.isEmailTemplateValid(validEmailTemplate.Id));
            System.assertEquals(null, WithoutSharingHelper.getEmailTemplateById(validEmailTemplate.Id ,EmailMessageHandler.EMAIL_PUBLIC_GROUP_NAME));

            //System.assert(expectedException.getMessage().contains(EmailMessageHandler.MSG_INVALID_TEMPLATE));
        } 
             system.runAs(sysAdminUser) {
             	KM_TestDataFactory.addUserToGroup(sysadminuser.Id, EmailMessageHandler.EMAIL_PUBLIC_GROUP_NAME);
      
             }     
            System.assertEquals(true, EmailMessageHandler.isEmailTemplateValid(validEmailTemplate.Id));
        	System.assertNotEquals(null, WithoutSharingHelper.getEmailTemplateById(validEmailTemplate.Id ,EmailMessageHandler.EMAIL_PUBLIC_GROUP_NAME));
			System.assertNotEquals(null,  validEmailTemplate.Id);
            expectedException = null; 
        
        system.runAs(u){
    		 try{
                System.debug('Valid email template test');
                em = new EmailMessage();
                em.FromAddress = 'test@salesforce.com';
                em.EmailTemplateId = validEmailTemplate.Id;
                insert em;
                
            }catch(exception e) {
                System.debug('Error creating email: ' + e);
                expectedException = e;
                
            }
           	System.assertEquals(null, expectedException);
            
            
            test.stopTest();
            
            //EmailMessage email = [Select FromAddress FROM EmailMessage limit 1];
            System.debug('EmailMessage:'+em);

        }
        
        
    }
    
     @isTest
    public static void afterInsertTest(){
        
        User u =  KM_TestDataFactory.createAuthorUser();
        System.debug('User Info:'+u);
        
        system.runAs(u){

            EmailMessageRelation emr = new EmailMessageRelation();
            String emailList = 'test@salesforce.com';
            
            KMEmail__c kmemail = KMEmail__c.getOrgDefaults();
            kmemail.Email__c = 'test@salesforce.com';
            upsert kmemail KMEmail__c.Id;
            
            KMProfile__c kmprofile = KMProfile__c.getOrgDefaults();
            kmprofile.RunEmailMessageTgr__c	 = True;
            upsert kmprofile KMProfile__c.Id;
            
            test.startTest();
            try{
                insert emr;
                
            }catch(exception error){
                System.debug('Error');
                //System.assert(error.getMessage().contains('You must select Org wide address as from address'));
            }
           	
            test.stopTest();
            
            //EmailMessage email = [Select FromAddress FROM EmailMessage limit 1];
            System.debug('EmailMessage:'+emr);
        }
    }
    
   
}
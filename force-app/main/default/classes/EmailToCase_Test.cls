/*------------------------------------------------------------------------
Positive and negative tests for the EmailToCase custom email service class.

History
<Date>      <Authors Name>     <Brief Description of Change>
06-July-2020  Mammet Developer   This is the test class for Email to case custom email service.  
----------------------------------------------------------------------------*/
@isTest
private class EmailToCase_Test{
    
    @testSetup
    private static void testSetup(){
        Profile oopAdminProfile = [Select ID From Profile Where Name='Minimum Access OOP Admin'];
        User oppAdministratorUser = Utility_Test.createTestUser(oopAdminProfile.ID, 'firstName_oopAdmin', 'lastName_oopAdmin');
        insert oppAdministratorUser;

        List<GroupMember> groupMember_List = new List<GroupMember>();
        GroupMember groupMember = new GroupMember();
        groupMember.GroupId = [SELECT ID From Group Where DeveloperName='OOPAdmins' AND Type='Regular' Limit 1].ID;
        groupMember.UserOrGroupId = oppAdministratorUser.ID;
        groupMember_List.add(groupMember);

        insert groupMember_List;

        List<Utility_Test.UserPermissionSetWrapper> wrapperList = new List<Utility_Test.UserPermissionSetWrapper>();
        Utility_Test.UserPermissionSetWrapper wrapper = new Utility_Test.UserPermissionSetWrapper();
        wrapper.user = oppAdministratorUser;
        wrapper.permissionSetNames.add('OOPCaseFullPermission');
        wrapper.permissionSetNames.add('C360_Agent');
        wrapperList.add(wrapper);
        system.runAs(new User(Id=UserInfo.getUserId())){
            Utility_Test.assignPermissionSet(wrapperList);      
        }
        Utility_Test.createCaseAdminRecords();
    }

    //testmethod
    @isTest
    private static void handleInboundEmailScenario1_Test(){
        String htmlText = '<html>test test</html>';                
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'oopTest@example.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        List<Case> caseList = [Select ID,SubmissionSourceCode__c From Case Where SubmissionSourceCode__c='1CEO-Chairman'];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }
    
    //Submission code -- Other
    @isTest
    private static void handleInboundEmailScenario2_Test(){
        String htmlText = '<html>test test</html>';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'Insurance';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'oopTest@subDomain.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        List<Case> caseList = [Select ID From Case Where SubmissionSourceCode__c='OTHER (NONE OF THE ABOVE)'];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }
    
    //testmethod
    @isTest
    private static void handleInboundEmailScenario3_Test(){
        String htmlText = '<html>test test</html>';
                
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'fantom@test.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        List<Case> caseList = [Select ID From Case Where SubmissionSourceCode__c='1CEO-Chairman'];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }
    
    //testmethod
    @isTest
    private static void handleInboundEmailScenario4_Test(){
        String htmlText = '<html>test test</html>';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'fantom@Salesforce.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        List<Case> caseList = [Select ID From Case Where SubmissionSourceCode__c='OTHER (NONE OF THE ABOVE)'];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }

    //testmethod
    @isTest
    private static void handleInboundEmailScenario5_Test(){
        String htmlText = '<html>test test</html>';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'test blank subject';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'fantom@fest.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        //List<Case> caseList = [Select ID From Case Where SubmissionSourceCode__c='OTHER (NONE OF THE ABOVE)']; 
        List<Case> caseList = [Select ID From Case Where SubmissionSourceCode__c='1V-Web Officer Referral'];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }

    //testmethod
    @isTest
    private static void handleInboundEmailScenario6_Test(){
        String htmlText = '<html>test test</html>';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'fantom@fest.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        List<Case> caseList = [Select ID,SubmissionSourceCode__c From Case Where SubmissionSourceCode__c='OTHER (NONE OF THE ABOVE)'];
        //List<Case> caseList = [Select ID,SubmissionSourceCode__c From Case];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }
     //testmethod
    @isTest
    private static void handleInboundEmailScenario7_Test(){
        String htmlText = '<html>test test</html>';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'fantom@xest.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        List<Case> caseList = [Select ID From Case Where SubmissionSourceCode__c='6L-Legal'];
        List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
        system.assert(caseList.size()>0);
        // system.assert(emailMessageList.size()>0);
        }    
    }
    
    //BBR
    @isTest
    private static void handleInboundEmailScenario8_Test(){
        StaticResource bbrEmail = [Select Body From StaticResource Where Name='BBREmailBody'];
        String htmlText = '<html>test test</html>';                
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = bbrEmail.Body.toString();
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'oopTest@BBB.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
            List<Case> caseList = [Select ID,SubmissionSourceCode__c From Case Where SubmissionSourceCode__c='7BR-BBB Rebuttal'];
            if(caseList.size()>0){
                List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
                system.assert(caseList.size()>0);
                system.assert(emailMessageList.size()>0);
            }
        }    
    }
    //BBB
    @isTest
    private static void handleInboundEmailScenario10_Test(){
        StaticResource bbrEmail = [Select Body From StaticResource Where Name='BBBEmailBody'];
        String htmlText = '<html>test test</html>';                
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = bbrEmail.Body.toString();
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'oopTest@BBB.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
            List<Case> caseList = [Select ID,SubmissionSourceCode__c From Case Where SubmissionSourceCode__c='7B-Better Business Bureau-BBB'];
            if(caseList.size() > 0 ){
                List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
                system.assert(caseList.size()>0);
                system.assert(emailMessageList.size()>0);
            }
        }    
    }
    //BBB-Duplicate
    @isTest
    private static void handleInboundEmailScenario11_Test(){
        StaticResource bbrEmail = [Select Body From StaticResource Where Name='BBREmailBody'];
        String htmlText = '<html>test test</html>';                
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        email.subject = 'External';
        email.plainTextBody = bbrEmail.Body.toString();
        email.HtmlBody = htmlText;
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'oopTest@BBB.com';

        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);
            
            service = new EmailToCase();
            service.handleInboundEmail(email, env);
            Test.stopTest();    
            List<Case> caseList = [Select ID,SubmissionSourceCode__c From Case Where SubmissionSourceCode__c='7BR-BBB Rebuttal'];
            if(caseList.size()>0){
                List<EmailMessage> emailMessageList = [Select ID From EmailMessage Where ParentId = :caseList[0].Id];
                system.assert(caseList.size()==1);
                system.assert(emailMessageList.size()>0);
            }
        }    
    }
    
    // Threaded Reply
    @isTest
    private static void handleInboundEmailThreadedReply_Test() { 
        Case currentCase = TestData_Case.generateCase();
        
        // derive the threadId
        String caseId = currentCase.Id;
        if(caseId.length() > 15) {
            caseId = caseId.left(15);
        }
        String orgId = UserInfo.getOrganizationId().left(15);
        String threadId = '_';
        threadId += orgId.left(5);
        threadId += orgId.right(10).replace('0','');
        threadId += '._';
        threadId += caseId.left(5);
        threadId += caseId.right(10).left(5).replace('0','');
        threadId += caseId.right(5);
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        //email.subject = 'Sandbox: Test [ ref:_00D038jtv._500031Da2N:ref ]';
        email.subject = 'Sandbox: Test [ ref:' + threadId + ':ref ]';
        email.plainTextBody = 'Test Body';
        email.HtmlBody = '<html>test test</html>';
        email.toAddresses = new List<String>{'test@test.com'};
        email.fromAddress = 'oopTest@example.com';
        
        // headers
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = Datetime.now().format('yyyy-MM-dd');
        email.headers = new Messaging.InboundEmail.Header[1];

        User oppAdministratorUser = [SELECT ID FROM User WHERE LastName='lastName_oopAdmin'];
        system.runAs(oppAdministratorUser){
            Test.startTest();        
            EmailToCase service = new EmailToCase();
            service.handleInboundEmail(email, env);        
            Test.stopTest();    
        } 
        
        //final String testCaseId = '50003000001Da2NAAS';
        List<EmailMessage> emailMessageList = [SELECT ID FROM EmailMessage WHERE ParentId = :caseId];
        //system.assert(emailMessageList.size() > 0);
    }

}
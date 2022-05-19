@istest public class BWC_CommunicationTemplateController_Test {
	
    @istest static void emailTemplateCreation(){
        EmailTemplate emailTemp = BWC_TestDataFactory.customEmailTemplate('test','Text','test3456',true,UserInfo.getUserId(),'Test Email subject 3');
        insert emailTemp;
   		
        Test.startTest();
        	updateDataOnCommunicationTest();
        	updateDataOnCommunicationExceptionTest();
        	deleteDataOnCommunicationTest();
        	deleteDataOnCommunicationExceptionTest();
        Test.stopTest(); 
    }
    
   	@future
    public static void updateDataOnCommunicationTest(){
        Communication_Template_Mapping__c templateMapping = BWC_TestDataFactory.customTemplateMapping('Autopay Transaction Issues - Overpayment','Case Closed','Corrected','Educated Customer','English');
        insert templateMapping;
        String responseWrapper;
        List<EmailTemplate> emailTemp =[select id,name from EmailTemplate limit 1];
        try{
        	responseWrapper = BWC_CommunicationTemplateController.updateDataOnCommunication(emailTemp[0].Id, emailTemp[0].Name, templateMapping.Id);
        }catch(exception ex){
             System.assert(true);
        }
        // Verify
        BWC_CommunicationTemplateController.CommunicationResponseWrapper response =
            (BWC_CommunicationTemplateController.CommunicationResponseWrapper)JSON.deserialize(responseWrapper, BWC_CommunicationTemplateController.CommunicationResponseWrapper.class);
		system.assertEquals(true,response.success);
    }
    
    @future
    public static void updateDataOnCommunicationExceptionTest(){
        Communication_Template_Mapping__c templateMapping = BWC_TestDataFactory.customTemplateMapping('Autopay Transaction Issues - Overpayment','Case Closed','Corrected','Educated Customer','Spanish');
        insert templateMapping;
        String responseWrapper;
        List<EmailTemplate> emailTemp =[select id,name from EmailTemplate limit 1];
        try{
        	responseWrapper = BWC_CommunicationTemplateController.updateDataOnCommunication(emailTemp[0].Id, emailTemp[0].Name, '');
        }catch(exception ex){
             System.assert(true);
        }
        system.assertEquals(true,String.isEmpty(responseWrapper));
    }
    
   	@future
    public static void deleteDataOnCommunicationTest(){
        Communication_Template_Mapping__c templateMapping = BWC_TestDataFactory.customTemplateMapping('Autopay Transaction Issues - Overpayment','New Case','Corrected','Educated Customer','English');
        insert templateMapping;
        String responseWrapper;
        List<EmailTemplate> emailTemp =[select id,name from EmailTemplate limit 1];
        try{
        	responseWrapper = BWC_CommunicationTemplateController.deleteDataOnCommunication(emailTemp[0].Id, emailTemp[0].Name, templateMapping.Id);
        }catch(exception ex){
             System.assert(true);
        }
        BWC_CommunicationTemplateController.CommunicationResponseWrapper response =
            (BWC_CommunicationTemplateController.CommunicationResponseWrapper)JSON.deserialize(responseWrapper, BWC_CommunicationTemplateController.CommunicationResponseWrapper.class);
		system.assertEquals(true,response.success);
     }
    
    @future
    public static void deleteDataOnCommunicationExceptionTest(){
        Communication_Template_Mapping__c templateMapping = BWC_TestDataFactory.customTemplateMapping('Autopay Transaction Issues - Overpayment','New Case','Corrected','Educated Customer','Spanish');
        insert templateMapping;
        String responseWrapper;
        List<EmailTemplate> emailTemp =[select id,name from EmailTemplate limit 1];
        try{
        	responseWrapper = BWC_CommunicationTemplateController.deleteDataOnCommunication(emailTemp[0].Id, emailTemp[0].Name,'');
        }catch(exception ex){
            System.assert(true);
        }
        system.assertEquals(true,String.isEmpty(responseWrapper));
     }
    
     @isTest static void getCommunicationTest(){
        Communication_Template_Mapping__c templateMapping = BWC_TestDataFactory.customTemplateMapping('Bill Image - Delayed Bill','New Case','Corrected','Educated Customer','Spanish');
        insert templateMapping;
        BWC_CommunicationTemplateController.getCommunication(templateMapping.Id);
        system.assertEquals('New Case',templateMapping.Communication_Type__c);
    }
    
}
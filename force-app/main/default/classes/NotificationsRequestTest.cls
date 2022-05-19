@isTest
/*
* Thpis class is used to test notification request, mainly for CICD pre-deployment step for Production Pipeline
* Author: Seng Liew
*/
private  class NotificationsRequestTest {
    
    @isTest 
    static void testNotifictionRequest() 
    {
        Test.startTest();
        notificationRequest nr = new notificationRequest();
        Test.stopTest();
    }

}
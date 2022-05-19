/**
 * Name - Mule_ReconnectTest
 * Description - Mule_Reconnect Test class. 
 * Date - 10/26/2021
 * Author - Akinsola Jegede @Salesforce
 */
@isTest
private class Mule_ReconnectTest {
     @isTest 
     static void testMuleCalloutSuccess() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new Mule_ReconnectMock());
        String dataFeedType = 'Centers_Case_DAILY';
        String startDate = '2021-10-20T15:39:00.000Z';
        String endDate = '2021-10-23T15:39:00.000Z';
        String transactionNumbers='';
        String res = Mule_Reconnect.muleReconnect(dataFeedType, startDate, endDate,transactionNumbers);
        System.assertEquals(res,'Success');
    }
    
    @isTest 
     static void testMuleCalloutFail() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new Mule_ReconnectMock());
        String dataFeedType = '';
        String startDate = '2021-10-28T15:39:00.000Z';
        String endDate = '2021-10-27T15:39:00.000Z';
        String transactionNumbers='';
        try{
            String res = Mule_Reconnect.muleReconnect(dataFeedType, startDate, endDate,transactionNumbers);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception',e.getMessage());
        }
    }
}
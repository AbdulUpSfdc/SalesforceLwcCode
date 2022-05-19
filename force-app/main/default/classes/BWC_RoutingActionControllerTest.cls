@IsTest
public inherited sharing class BWC_RoutingActionControllerTest {

    @IsTest
    static void getRoutingActionValuesTest(){
        Test.startTest();
        BWC_RoutingActionController.getRoutingActionValues('Urgent | Unified Errors');
        Test.stopTest();
    }

    @IsTest
    static void getQueueIdTest(){

        Test.startTest();
        String queueName = [SELECT Id, Name FROM Group WHERE Type='Queue' LIMIT 1].Name;
        String queueId = BWC_RoutingActionController.getQueueId(queueName);
        Test.stopTest();

    }

    @IsTest
    static void getQueueIdTestFail(){

        Test.startTest();
        try{
            String queueId = BWC_RoutingActionController.getQueueId('queueName');
        }catch(Exception ex){

        }
        Test.stopTest();

    }

    @IsTest
    static void getTierValuesTest(){

        Test.startTest();
        String response = BWC_RoutingActionController.getTierValues('Tier3__c', 'Bill Image - Delayed Bill');
        Test.stopTest();

    }

}
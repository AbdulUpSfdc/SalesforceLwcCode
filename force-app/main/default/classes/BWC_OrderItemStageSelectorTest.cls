@IsTest
public with sharing class BWC_OrderItemStageSelectorTest {


    @IsTest
    public static void getStagesByFulfillmentTypeTest(){

        Test.startTest();
        String fulfillmentType = 'Returns';
        List<BWC_Order_Item_Stage__mdt> orderItemStages = BWC_OrderItemStageSelector.getStagesByFulfillmentType(fulfillmentType);
        Test.stopTest();
    }
}
public without sharing class BWC_OrderItemStageSelector {

    @AuraEnabled
    public static List<BWC_Order_Item_Stage__mdt> getStagesByFulfillmentType(String fulfillmentType){
        try {
            List<BWC_Order_Item_Stage__mdt> records = [SELECT
                Chevron_index__c, Chevron_label__c, Fulfillment_Type__c, Item_Status_Code__c,
                Milestone__c, Display_Sequence__c
                FROM BWC_Order_Item_Stage__mdt
                WHERE Fulfillment_Type__c =:fulfillmentType
                ORDER BY Display_Sequence__c ASC];

            return records;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
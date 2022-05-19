public class sdgTestDataFactory 
{
    public static BW_Status_Summary__c createParentRecord()
    {
        Id RecTypeName = Schema.SObjectType.BW_Status_Summary__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId(); 
        BW_Status_Summary__c ss = new BW_Status_Summary__c (
            RecordTypeId = RecTypeName,
            Name = 'TEST',
            BW_Month_Ending__c = date.parse('10/31/2020'));
    	insert ss;	
        return ss;
    }
}
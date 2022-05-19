@isTest
public class BWC_TakeOwnershipTest {
	@isTest
    public static void caseCreate(){
    	Adjustment__c adjustment = BWC_TestDataFactory.createAdjustment();
        BWC_TakeOwnership.checkTakeOwnership(adjustment.Case__r.Id);
    }
}
@isTest
public class BWC_LIC_WFEController_Test {
    
    private static testmethod void testGetLICWFERequestData(){
        test.startTest();
        BWC_LIC_WFE.LIC_WFEDataWrapper req = BWC_LIC_WFEController.getLICWFERequestData(true,'12345');
        System.assert(req !=null);
        test.stopTest();
    }
    private static testmethod void testLICWFE(){
        test.startTest();
        BWC_LIC_WFE obj = new BWC_LIC_WFE();
        test.stopTest();
    }

}
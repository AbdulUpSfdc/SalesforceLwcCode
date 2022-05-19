/* ================================================
* @class name: BWC_BillingSummaryService_Test
* @author: Salesforce Inc.
* @group: Billing Summary
* @purpose: Test coverage for BWC_BillingSummaryService.
* @created date (mm/dd/yyyy) :  10/01/2020
================================================*/ 
@isTest
public with sharing class BWC_BillingSummaryService_Test {
    public BWC_BillingSummaryService_Test() {

    }

    
    @TestSetup
    static void setupData() {
        Account acctObj = BWC_TestDataFactory.createAccount();
        Billing_Account__c billAcctObj = BWC_TestDataFactory.createBillingAccount('Wireless',acctObj);
        billAcctObj.Billing_Account_Number__c = '287263650846';
        update billAcctObj;
    }

    @isTest
    private static void getBillingDataTest() {

        Account acctObj = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        BWC_BillingSummaryService service = new BWC_BillingSummaryService();
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 200);

        BWC_BillingSummaryResultWrapper result = BWC_BillingSummaryService.getBillingData(acctObj.Id);

        // Cover all fields of BWC_BillingSummaryRespWrapper;
        BWC_BillingSummaryRespWrapper respWrapper = new BWC_BillingSummaryRespWrapper();
        respWrapper.Wireless = new List<BWC_BillingSummaryRespWrapper.ResponseContent>();
        respWrapper.Wireless.add(new BWC_BillingSummaryRespWrapper.ResponseContent());
        respWrapper.Wireless[0].content = new BWC_BillingSummaryRespWrapper.Content();
        
        BWC_BillingSummaryRespWrapper.Content content = respWrapper.Wireless[0].content;
        content.billFound = true;
        content.billInfo = new BWC_BillingSummaryRespWrapper.BillInfo();
        content.billInfo.address = new BWC_BillingSummaryRespWrapper.Address();
        content.billInfo.address.name = 'Test';
        content.billInfo.address.addressLines = new List<String>(); 
        content.billInfo.ban = '';
        content.billInfo.bbInstance = '';
        content.billInfo.billingMethod = '';
        content.billInfo.billngSystem = '';
        content.billInfo.cycleEndDate = '01-01-2020';
        content.billInfo.cycleStDate = '01-31-2020';     
        content.billInfo.fanID = 'Test';
        content.billInfo.marketZone = 'Test';
        
        content.billSummary = new BWC_BillingSummaryRespWrapper.BillSummary();
        content.billSummary.newChrgs = new BWC_BillingSummaryRespWrapper.TotalPayments();
        content.billSummary.newChrgs.amt = '0.0';
        content.billSummary.newChrgs.amtInd = '';
        content.billSummary.newChrgs.descList = new List<String>();
        content.billSummary.newChrgs.type_Z = '';
        content.billSummary.prevBal = new BWC_BillingSummaryRespWrapper.PrevBal();
        content.billSummary.prevBal.amt = '0.0';
        content.billSummary.prevBal.amtInd = '';
        content.billSummary.prevBal.descList = new List<String>();
        content.billSummary.prevRmningBal = new BWC_BillingSummaryRespWrapper.PrevRmningBal();
        content.billSummary.prevRmningBal.amt = '0.0';
        content.billSummary.prevRmningBal.type_Z = '';
        content.billSummary.rmningBal = new BWC_BillingSummaryRespWrapper.TotalPayments();
        content.billSummary.totalAdjustments = new BWC_BillingSummaryRespWrapper.TotalPayments();
        content.billSummary.totalPayments = new BWC_BillingSummaryRespWrapper.TotalPayments();
        content.billSummary.totChrgs = new BWC_BillingSummaryRespWrapper.TotalPayments();
        
        content.wirelessChrgs = new BWC_BillingSummaryRespWrapper.WirelessChrgs();
        content.wirelessChrgs.prevWirelessServiceAmt = new BWC_BillingSummaryRespWrapper.PrevWirelessServiceAmt();
        content.wirelessChrgs.prevWirelessServiceAmt.amt = '0.0';
        content.wirelessChrgs.totalWirelessServiceAmt = new BWC_BillingSummaryRespWrapper.PrevBal();
        content.wirelessChrgs.varWirelessServiceAmt = new BWC_BillingSummaryRespWrapper.PrevWirelessServiceAmt();
        content.wirelessChrgs.wirelessServiceDesc = '';
        content.wirelessChrgs.wirelessServiceList = new List<BWC_BillingSummaryRespWrapper.WirelessServiceList>();
        content.wirelessChrgs.wirelessServiceList.add(new BWC_BillingSummaryRespWrapper.WirelessServiceList());
        content.wirelessChrgs.wirelessServiceList[0].ctn = '';
        content.wirelessChrgs.wirelessServiceList[0].ctnUser = '';
        content.wirelessChrgs.wirelessServiceList[0].group_Z = true;
        content.wirelessChrgs.wirelessServiceList[0].groupID = '';
        content.wirelessChrgs.wirelessServiceList[0].nbrOfDevices = 0;
        content.wirelessChrgs.wirelessServiceList[0].prevServiceAmt = new BWC_BillingSummaryRespWrapper.PrevWirelessServiceAmt();
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList = new LIst<BWC_BillingSummaryRespWrapper.SectionBeanList>();
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList.add(new BWC_BillingSummaryRespWrapper.SectionBeanList());
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList = new List<BWC_BillingSummaryRespWrapper.ChargeList>();
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList.add(new BWC_BillingSummaryRespWrapper.ChargeList());
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList[0].amt = '0.0';
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList[0].amtInd = '';
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList[0].date1 = '01-01-2020';
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList[0].date2 = '01-01-2020';
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList[0].descList = new List<String>();
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].chargeList[0].type_Z = '';
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].sectionDesc = '';
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].totalSectAmt = new BWC_BillingSummaryRespWrapper.PrevBal();
        content.wirelessChrgs.wirelessServiceList[0].sectionBeanList[0].type_Z = '';
        content.wirelessChrgs.wirelessServiceList[0].serviceDesc = '';
        content.wirelessChrgs.wirelessServiceList[0].totalServiceAmt = new BWC_BillingSummaryRespWrapper.PrevBal();
        content.wirelessChrgs.wirelessServiceList[0].varServiceAmt = new BWC_BillingSummaryRespWrapper.PrevWirelessServiceAmt();
        
        BWC_BillingSummaryRespWrapper.SectionBeanList_Z sectionBean = new BWC_BillingSummaryRespWrapper.SectionBeanList_Z();
        sectionBean.chargeList = new List<BWC_BillingSummaryRespWrapper.ChargeList>();
        sectionBean.prevSectAmt = new BWC_BillingSummaryRespWrapper.PrevWirelessServiceAmt();
        sectionBean.sectionDesc = '';
        sectionBean.totalSectAmt = new BWC_BillingSummaryRespWrapper.PrevBal();
        sectionBean.type_Z = '';
        sectionBean.varSectAmt = new BWC_BillingSummaryRespWrapper.PrevWirelessServiceAmt();
        

        Test.stopTest();
        System.assertEquals(true, result.success);
    }

    

    @isTest
    private static void getBillingDataTest_Error() {

        Account acctObj = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 400);

        BWC_BillingSummaryResultWrapper result = BWC_BillingSummaryService.getBillingData(acctObj.Id);

        Test.stopTest();
        System.assertEquals(false, result.success);
    }

    

    @isTest
    private static void getBillingDataTest_NotFound() {

        Account acctObj = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        
        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_BillingSummaryMock', 404);

        BWC_BillingSummaryResultWrapper result = BWC_BillingSummaryService.getBillingData(acctObj.Id);

        Test.stopTest();
        System.assertEquals(false, result.success);
    }

}
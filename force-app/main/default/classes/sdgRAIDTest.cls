@isTest
public class sdgRAIDTest 
{    
    static testmethod void testInstantiate() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
        sdgRAID lgMA = new sdgRAID();
        sortablegrid.SDG coreSDG = lgMA.LoadSDG('', ss.Id);
        system.assertNotEquals(null, coreSDG);
        system.assertNotEquals(0, coreSDG.SDGFields.size());   
    }
    static testmethod void testNoFilterAscending() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        myrequest.SortColumn = '1';
        myrequest.SortOrder = 'A';
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNoFilterDescending() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        myrequest.SortColumn = '1';
        myrequest.SortOrder = 'D';
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testequal1() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('1','=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTequal1() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('1','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testCONTAINS1() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('1','CONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTCONTAINS1() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('1','NOTCONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testSTARTS1() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('1','STARTS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testENDS1() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('1','ENDS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testequal2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTequal2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testCONTAINS2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','CONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTCONTAINS2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','NOTCONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testSTARTS2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','STARTS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testENDS2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','ENDS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
        static testmethod void testequal3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTequal3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testCONTAINS3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','CONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTCONTAINS3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','NOTCONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testSTARTS3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','STARTS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testENDS3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','ENDS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testequal4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTequal4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testCONTAINS4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','CONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTCONTAINS4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','NOTCONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testSTARTS4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','STARTS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testENDS4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','ENDS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testequal5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','=','2020-07-31');
        system.debug(myfilter);
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testGT5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','GT','2020-07-31');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLT5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','LT','2020-07-31');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTOMORROW5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','TOMORROW','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTODAY5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','TODAY','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testYESTERDAY5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','YESTERDAY','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_WEEK5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','NEXT_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_WEEK5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','THIS_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_WEEK5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','LAST_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_MONTH5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','NEXT_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_MONTH5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','THIS_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_MONTH5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','LAST_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_QUARTER5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','LAST_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_QUARTER5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','THIS_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_QUARTER5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','NEXT_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_YEAR5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','LAST_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_YEAR5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','THIS_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_YEAR5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','NEXT_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
/**    static testmethod void testequal6() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('6','=','Foo');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        system.debug(myrequest.filters);
        system.debug(coreSDG);
        system.debug(myrequest);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }  **/
    static testmethod void testNOTequal6() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('6','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        system.debug(myrequest.filters);
        system.debug(coreSDG);
        system.debug(myrequest);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testCONTAINS6() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('6','CONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNOTCONTAINS6() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('6','NOTCONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testSTARTS6() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('6','STARTS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testENDS6() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('6','ENDS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgRAID.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }   
}
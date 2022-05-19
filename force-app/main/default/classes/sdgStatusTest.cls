@isTest
public class sdgStatusTest 
{    
    static testmethod void testInstantiate() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
        sdgStatus lgMA = new sdgStatus();
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgStatus.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
  }
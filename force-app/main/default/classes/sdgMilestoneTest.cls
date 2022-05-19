@isTest
public class sdgMilestoneTest {
    
    static testmethod void testInstantiate() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
        sdgMilestone lgMA = new sdgMilestone();
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    
/**    static testmethod void testequal2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }  **/
    
    static testmethod void testNOTequal2() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('2','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
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
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    
    static testmethod void testequal3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','=','2020-07-31');
        system.debug(myfilter);
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testGT3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','GT','2020-07-31');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLT3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','LT','2020-07-31');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTOMORROW3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','TOMORROW','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTODAY3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','TODAY','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testYESTERDAY3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','YESTERDAY','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_WEEK3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','NEXT_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_WEEK3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','THIS_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_WEEK3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','LAST_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_MONTH3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','NEXT_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_MONTH3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','THIS_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_MONTH3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','LAST_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_QUARTER3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','LAST_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_QUARTER3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','THIS_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_QUARTER3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','NEXT_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_YEAR3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','LAST_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_YEAR3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','THIS_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_YEAR3() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('3','NEXT_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testequal4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','=','2020-07-31');
        system.debug(myfilter);
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testGT4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','GT','2020-07-31');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLT4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','LT','2020-07-31');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTOMORROW4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','TOMORROW','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTODAY4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','TODAY','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testYESTERDAY4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','YESTERDAY','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_WEEK4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','NEXT_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_WEEK4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','THIS_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_WEEK4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','LAST_WEEK','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_MONTH4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','NEXT_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_MONTH4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','THIS_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_MONTH4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','LAST_MONTH','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_QUARTER4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','LAST_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_QUARTER4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','THIS_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_QUARTER4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','NEXT_QUARTER','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testLAST_YEAR4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','LAST_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testTHIS_YEAR4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','THIS_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testNEXT_YEAR4() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('4','NEXT_YEAR','');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    static testmethod void testequal5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    } 
    
    static testmethod void testNOTequal5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','NOT=','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    
    static testmethod void testCONTAINS5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','CONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    
    static testmethod void testNOTCONTAINS5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','NOTCONTAINS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    
    static testmethod void testSTARTS5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','STARTS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
    
    static testmethod void testENDS5() 
    {
        BW_Status_Summary__c ss = sdgTestDataFactory.createParentRecord();
		sortablegrid.SDG coreSDG = new sortablegrid.SDG('15');
        sortablegrid.SDGRequest myrequest = new sortablegrid.SDGRequest();
        myrequest.ParentRecordId = ss.Id;
        sortablegrid.SDGFilter myfilter = new sortablegrid.SDGFilter('5','ENDS','1');
        myrequest.Filters = new List<sortablegrid.SDGFilter>();
        myrequest.Filters.add(myfilter);
        sortablegrid.SDGResult myresult = sdgMilestone.getData(coreSDG,myrequest);
        system.assertEquals(0, myresult.data.size());
    }
}
@isTest
public with sharing class ChangeLeadOwnerListActionsControllerTest {
        
    @isTest
    static void test() {
        Lead dciLead = new Lead(LastName = 'DCILead', Company = 'TEST', MobilePhone = '2001234567', RecordTypeId = RetailConstants.DIGITALCHECKIN_RECORDTYPEID);
        insert dciLead;
        
        PageReference pageRef = Page.ChangeLeadOwnerListAction;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardSetController ctrlr = New ApexPages.StandardSetController(New List<Lead>{dciLead});
        ctrlr.setSelected(New List<Lead>{dciLead});
        ChangeLeadOwnerListActionController obj = New ChangeLeadOwnerListActionController(ctrlr);
        System.assertEquals(1, obj.getLeads().size());
    }

}
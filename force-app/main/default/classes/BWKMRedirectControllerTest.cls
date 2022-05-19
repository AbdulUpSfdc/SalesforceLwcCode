@isTest
private class  BWKMRedirectControllerTest {
    @isTest
    static void BWKMRedirectPageTest() {

        Test.startTest();

        BWKnowledgeRedirect__c rd_rec = new BWKnowledgeRedirect__c(Article_Link__c='test_url');         
		insert rd_rec;
        
		string test_rec_id = rd_rec.ID;
        
        PageReference pageRef = Page.BWKMRedirectPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id',test_rec_id);
               
        //BWKMRedirectController thisobject = new BWKMRedirectController();
        BWKMRedirectController.getkmarticle();

    }
}
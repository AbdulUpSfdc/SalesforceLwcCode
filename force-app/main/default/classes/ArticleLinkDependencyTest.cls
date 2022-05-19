@isTest
public class ArticleLinkDependencyTest {
    @isTest
    static void doPostTest(){
		 knowledge__kav published = new knowledge__kav(
                                                          UrlName='Test-Article-Markets',
                                                          Title= 'Test Article',
                                                          ContentSponsor__c = 'abc',
            											  BW_External_URL__c = 'www.salesforce.com'
                                                          );
        KM_TestDataFactory.createContentSponsorUser('abc');
        insert published;
        System.debug('Article: '+published.Id);

        String instance = URL.getSalesforceBaseUrl().toExternalForm();
        
        System.debug(instance+'/services/apexrest/ArticleLinkDependency');
       // ArticleLinkDependency.doPost(published.Id);
        
       	String myJSON = JSON.serialize(published);

        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        request.requestUri = instance+'/services/apexrest/ArticleLinkDependency';
        request.httpMethod = 'POST';
		request.requestBody = Blob.valueof(myJSON);
		
        RestContext.request = request;
        RestContext.request = request;
    	RestContext.response= res;
        Test.startTest();
         ArticleLinkDependency.doPost(published.Id);
        Test.stopTest();

 
        
    }
}
@isTest
public class DeleteArchivedBatTest {
    @isTest
    public static void testKnowledge(){
        
        //Insert Test data
        Knowledge__kav newArticle = new Knowledge__kav(Title = 'Retention', URLName = 'Retention', ContentSponsor__c = 'ABC');
        KM_TestDataFactory.createContentSponsorUser('ABC');
        Insert newArticle;
        
        test.startTest();
        DeleteArchivedBat.DeleteArchivedArticles();
        
        test.stopTest();
    }
}
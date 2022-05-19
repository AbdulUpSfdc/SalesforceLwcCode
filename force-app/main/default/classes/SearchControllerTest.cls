@isTest
public class SearchControllerTest {

     @istest static void searchEmailTemplate(){
        SearchController sObj = new SearchController();
        String objectName ='EmailTemplate';
        List<String> fields=new List<String>{'Name','developerName'};
        String searchTerm='Case';
        SearchController.search(objectName,fields,searchTerm);
    }
    
}
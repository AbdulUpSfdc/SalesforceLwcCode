@isTest
public with sharing class ArticleWebServiceWrapperTest {

     public static testMethod void testWrapper(){
       List<ArticleDataWrapper> articleDataWrapperList;
        String errorMessage;
         
      ArticleWebServiceWrapper wrapper = new ArticleWebServiceWrapper(articleDataWrapperList, errorMessage);
      wrapper = new ArticleWebServiceWrapper(articleDataWrapperList);
      wrapper = new ArticleWebServiceWrapper(errorMessage);
      wrapper = new ArticleWebServiceWrapper();
      
    }
    
    
}
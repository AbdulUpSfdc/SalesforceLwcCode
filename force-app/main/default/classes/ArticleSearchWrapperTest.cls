@isTest
public with sharing class ArticleSearchWrapperTest {

    public static testmethod void testWrapper() {
        String userId = 'UserId';
    	String searchText = 'testSearch1';
        String sortBy = 'sortBy';
        String filterBy = 'filterBy';
        Integer currentPage = 1;
        String startDate = '1/1/2021';
        String endDate = '12/31/2021';
     	ArticleSearchWrapper searchWrapper = new ArticleSearchWrapper(searchText, sortBy, filterBy, currentPage,
                        											startDate, endDate);
    }
    
}
public with sharing class ArticleSearchWrapper {

    public String searchText = null;
    public String sortBy = null;
    public String filterBy = null;
    public Integer currentPage = null;
    public String startDate = null;
    public String endDate = null;
    
    public ArticleSearchWrapper (String searchText,
                                String sortBy,
                                String filterBy,
                                Integer currentPage,
                                String startDate,
                                String endDate) {
   		this.searchText = searchText;
        this.sortBy = sortBy;
        this.filterBy = filterBy;
        this.currentPage = currentPage;
        this.startDate = startDate;
        this.endDate = endDate;
                                  
   }
}
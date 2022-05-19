global with sharing class ArticleWebServiceWrapper {
    
    public Boolean success {get; private set;} {success = true;}
    public String errorMessage {get; set;} {errorMessage = '';}
    public Boolean publishArticles {get; set;} {publishArticles = true;}
	public String extractSandboxName {get; set;} {extractSandboxName = '';}
    public Integer articleQuantity {get; set;} {articleQuantity = 0;}
    public List<Id> articleIdList {get; set;} {articleIdList = new List<Id>();}
    public List<ArticleDataWrapper> articleDataWrapperList {get; set;} {articleDataWrapperList = new List<ArticleDataWrapper>();}  

    public ArticleWebServiceWrapper() {} 
    
    public ArticleWebServiceWrapper(List<ArticleDataWrapper> articleDataWrapperList) {
        setArticleDataWrapperList(articleDataWrapperList);
    }
    
    public ArticleWebServiceWrapper(String errorMessage) {
        this.setErrorMessage(errorMessage);
    }
    
    public ArticleWebServiceWrapper(List<ArticleDataWrapper> articleDataWrapperList, String errorMessage) {
        this.setErrorMessage(errorMessage);
        this.setArticleDataWrapperList(articleDataWrapperList);
    }
    
    private void setArticleDataWrapperList(List<ArticleDataWrapper> articleDataWrapperList) {
        if (articleDataWrapperList != null) {
            this.articleDataWrapperList = articleDataWrapperList;
            if (articleDataWrapperList != null) {
            	this.articleQuantity = articleDataWrapperList.size();
            }    
        } 
    }
    
    public void setErrorMessage(String errorMessage) {
        if (errorMessage != null) {
            this.errorMessage = errorMessage;
            this.success = false;
        }
    }
}
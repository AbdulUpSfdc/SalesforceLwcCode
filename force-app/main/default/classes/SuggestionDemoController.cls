public class SuggestionDemoController {
    
    public String searchText;
    public String language = 'en_US';
    public String objectType = 'KnowledgeArticleVersion';
    public Integer nbResult = 5;
    public Transient Search.SuggestionResults suggestionResults;
 
    public String getSearchText() {
        return searchText;
    }
 
    public void setSearchText(String s) {
        searchText = s;
    }
    
    public Integer getNbResult() {
        return nbResult;
    }
 
    public void setNbResult(Integer n) {
        nbResult = n;
    }
    
    public String getLanguage() {
        return language;
    }
    
    public void setLanguage(String language) {
        this.language = language;
    }
            
    public String getObjectType() {
        return objectType;
    }
    
    public void setObjectType(String objectType) {
        this.objectType = objectType;
    }
 
    public List<Search.SuggestionResult> getResults() {
        if (suggestionResults == null) {
            return new List<Search.SuggestionResult>();
        }
        
        return suggestionResults.getSuggestionResults();
    }
    
    public Boolean getHasMoreResults() {
        if (suggestionResults == null) {
            return false;
        }
        return suggestionResults.hasMoreResults();
    }
    
    public PageReference doSuggest() {
        nbResult = 5;
        suggestArticles();
        return null;
    }
    
    public PageReference doSuggestMore() {
        nbResult += 5;
        suggestArticles();
        return null;
    }
    
    private void suggestArticles() {
        Search.SuggestionOption options = new Search.SuggestionOption();
        Search.KnowledgeSuggestionFilter filters = new Search.KnowledgeSuggestionFilter();
        if (objectType=='KnowledgeArticleVersion') {
            filters.setLanguage(language);
            filters.setPublishStatus('Online');
        }
        options.setFilter(filters);
        options.setLimit(nbResult);
        suggestionResults = Search.suggest(searchText, objectType, options);
    }
}
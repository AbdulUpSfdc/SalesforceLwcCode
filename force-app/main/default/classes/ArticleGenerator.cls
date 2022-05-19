public with sharing class ArticleGenerator {

    public static Knowledge__kav publishArticle(String recordTypeName, String title, String urlname, String ContentSponsor,
                                               Boolean assignedArticle, Boolean frontLineFocus, Boolean isUrgent, Map<String, List<String>> articleCategoryMap, List<String> articleMarketList ){
       Id recordTypeId = ArticleDataWrapper.getRecordTypeId(recordTypeName);
        Knowledge__kav knowledgeArticle = new Knowledge__kav(
           BW_Is_Urgent__c = isUrgent,
           Title = title,
           UrlName = urlname,
           ContentSponsor__c = ContentSponsor,
           RecordTypeId = recordTypeId,
           BW_Home_Page_Display__c = assignedArticle,
           BW_FrontLine_Focus__c = frontlineFocus
       );
        knowledgeArticle.BW_Article_Details__c = 'TEST';                                       
        if (recordTypeName.equalsIgnoreCase('News Article')) {
          	knowledgeArticle.BW_News_Start_Date__c = DateTime.now().addDays(1);
            knowledgeArticle.BW_News_End_Date__c = knowledgeArticle.BW_News_Start_Date__c.addDays(30);                                           
         }
         knowledgeArticle.BW_Article_Details__c = 'Test Article Details created ' + Datetime.now();
         knowledgeArticle.BW_Preview_Image__c= '<img alt="HBO Max" src="https://cnet2.cbsistatic.com/img/tq9cRzYly6Fy4SCvgrSngAIKnt0=/1200x675/2019/10/29/ace0a81f-293b-4fb2-b20f-ed0d3a1743c7/hbo-max-all-the-shows-coming.png" />';
             
        insert knowledgeArticle;
        knowledgeArticle = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id = :knowledgeArticle.Id];

        System.debug('Article inserted: ' + knowledgeArticle.id);
        List<BWKnowledgeArticleLink__c> linkList = new List<BWKnowledgeArticleLink__c>();                                         
        for(Integer i=0; i<2; i++){
                BWKnowledgeArticleLink__c link = new BWKnowledgeArticleLink__c();
                link.Knowledge_Article__c =  knowledgeArticle.Id;
                link.Status__c = 'Published';
                link.Link_Title__c = 'TestTitle';
                link.Link_URL__c = 'TestURL' + i;
                link.Type__c = 'Knowledge Article';
                linkList.add(link);
        }
        
        insert linkList;
        List<String> dataCategoryNameList;

        List<BWMarketAssociation__c> marketAssociationList = new List<BWMarketAssociation__c>();
        List<Knowledge__datacategorySelection> dataCategoryList = new List<Knowledge__datacategorySelection>();
                   if (articleCategoryMap != null && !articleCategoryMap.isEmpty()) {
                    for (String datacategorygroupname: articleCategoryMap.keySet()) {
                        dataCategoryNameList = articleCategoryMap.get(datacategorygroupname);
                        if (!dataCategoryNameList.isEmpty()) {
                            for (String datacategoryname : dataCategoryNameList) {
                                dataCategoryList.add(ArticleImportWebService.createArticleDataCategory(knowledgeArticle.Id, datacategorygroupname, datacategoryname));    
                            }
                        }    
                    }    
                }
                if (articleMarketList != null && !articleMarketList.isEmpty()) {
                    for (String marketName: articleMarketList) {
                        Id marketId = ArticleImportWebService.marketMasterNameMap.get(marketName);
                        if (marketId !=null) {
                        	marketAssociationList.add(ArticleImportWebService.createMarketAssociation(knowledgeArticle.Id,  marketId));	  
                        }
                    }    
                }
                
                                                
	insert dataCategoryList;
    System.debug('Number of data categories inserted ' +  dataCategoryList.size());                                              
    insert marketAssociationList;
    System.debug('Number of markets inserted ' +  marketAssociationList.size());                                                 
    KbManagement.PublishingService.publishArticle(knowledgeArticle.KnowledgeArticleId, true);                                              
                                                   
        
   return knowledgeArticle;
    }
    
    public static Knowledge__kav testPublishArticle() {
        String timeStamp = String.valueOf(DateTime.now());
        timestamp = timestamp.replaceAll('\\D', '');
		System.debug(timestamp); 
        String resourceTypeCategoryString;
        String channelCategoryString;
        String marketListString;
        String roleCategoryString;
        roleCategoryString = 'Previewer, Agent_Principal, Sales_Call_Center_Representative, Manager_and_above, Technical_Care_Support_Representative';
        marketListString = 'Florida, Gulf States, Michigan';	
        resourceTypeCategoryString = 'Employee';
        channelCategoryString = 'OOP, ACC, AT_T_Retail';
        String title = 'KEJ Test Article ' + timeStamp;
        String urlname = 'KEJ' + timeStamp;
        String ContentSponsor = 'kj980n';
        Boolean assignedArticle = true;
        Boolean frontLineFocus = true;
        Boolean isUrgent = false;
        String recordTypeName;
		recordTypeName = 'FAQs & Troubleshooting';
        //recordTypeName = 'News Article';
        //recordTypeName = 'Operations Support';
        //recordTypeName = 'Sales & Support';
        //recordTypeName = 'Promotions & Offers';
        //recordTypeName = 'Link Center Article';
        
        //recordTypeName = 'BW_FAQ_Troubleshooting';

       
        Map<String, List<String>> dataCategories = new Map<String, List<String>>();
        List<String> marketList = new List<String>();
        List<String> resourceTypeCategories = new List<String>();
        List<String> channelCategories = new List<String>();
        List<String> roleCategories = new List<String>();
        dataCategories.put('Role', roleCategories);
        dataCategories.put('Resource_Type', resourceTypeCategories);
        dataCategories.put('Channel', channelCategories);
        
        resourceTypeCategories.addAll(resourceTypeCategoryString.split(','));
        marketList.addAll(marketListString.split(','));
        channelCategories.addAll(channelCategoryString.split(','));
        roleCategories.addAll(roleCategoryString.split(','));
        return publishArticle(recordTypeName, title,  urlname, ContentSponsor,
                                assignedArticle,  frontLineFocus,  isUrgent,   dataCategories, marketList );
    } 
}
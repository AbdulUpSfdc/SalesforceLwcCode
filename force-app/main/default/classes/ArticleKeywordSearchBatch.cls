/*
 * 
 * This is intended to be executed by a Sys Admin user from the Developer console using the following form. The user who's attid is used should be a member of the public group: KM Content Strategy Team. The user should look for errors in the debug logs.
This will email a report with the article informationto the email associated with the user of the attId.
String searchTerm = 'HBO';
String attId = 'vk8702';
Id batchJobId = Database.executeBatch(new ArticleKeywordSearchBatch(searchTerm, attId), 200);
*/

//Regex.Replace(Your String, @"[^0-9a-zA-Z_]+", "")  


public without sharing class ArticleKeywordSearchBatch implements Database.Batchable<sObject>, Database.Stateful{
    public final String SEARCH_TEXT;
    public final String ATTUID;
    public final User REQUEST_USER;
    public List<String> articleIdList = new List<String>();
    public Set<Id> articleIdSet = new Set<Id>();
    public static final String CONTENT_STRATEGY_GROUP_NAME = 'KM_Content_Strategy_Team';
    public static final String EMAIL_SUBJECT = 'Article Keyword Search Results For: ';
    public final List<String> pageHeaders;
    public static final String stripCharsRegEx = '[^0-9a-zA-Z_]'; 
    public List<String> searchStringList = new List<String>();
    public static final String NEWLINE = '\n';
    
    public ArticleKeywordSearchBatch(String searchText, String attuid) {
        this.SEARCH_TEXT = searchText;
        this.ATTUID = attuid;
        this.REQUEST_USER = getUserByAttuid(this.ATTUID);
        System.debug('Att user located: ' + this.REQUEST_USER);
        
        this.searchStringList.add(this.SEARCH_TEXT);
        String strippedString = stripCharacters(this.SEARCH_TEXT);
        if (!strippedString.equals(SEARCH_TEXT) && !String.isEmpty(strippedString)) {
       		this.searchStringList.add(strippedString);    
        }
        
        pageHeaders = new List<String>();
        pageHeaders.add('Article Number');
        pageHeaders.add('Article Id');
        pageHeaders.add('Article Title');
        pageHeaders.add('Term(s) Found');
        pageHeaders.add('Title');
		pageHeaders.add('Body');
        pageHeaders.add('Related Links');
        pageHeaders.add('Last Published Date');
        pageHeaders.add('Content Sponsor');
        pageHeaders.add('Content Type');
        pageHeaders.add('Content Path');
        System.debug('Search List: ' + searchStringList);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
       
        if (this.REQUEST_USER == null  ) {
        	throw new ArticleKeywordSearchBatchException('No active user found for ' + this.ATTUID);
        } 
        if (!isValidRequester(this.REQUEST_USER)) {
       		throw new ArticleKeywordSearchBatchException(this.ATTUID + ' user is not a member of the group, and cannot request the query: ' + CONTENT_STRATEGY_GROUP_NAME);
        }
        String query = 'SELECT Id, Title, ArticleNumber, BW_Article_Details__c,';
        query += ' UrlName, ContentSponsor__c, LastPublishedDate, KnowledgeArticleId';
        query += ' FROM Knowledge__kav';
        query += ' WHERE PublishStatus = \'Online\'';
        query += ' ORDER BY CreatedDate DESC LIMIT 50000';
        return Database.getQueryLocator(query);
    	
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<String> foundSearchTerms = new Set<String>();
        String upperDetails;
        String upperTitle;
        String upperLinkTitle;
        String upperLinkURL;
        String upperSearchTerm;
        String foundInBody;
        String foundInTitle;
        String foundinLinks;
        List<String> articleOutput;
        List<String> foundSearchTermsList;
        List<Knowledge__kav> articleList = (List<Knowledge__kav>) scope;
        Set<Id> knowledgeIdSet = new Set<Id>();
        for (Knowledge__kav article :  articleList) {
        	//knowledgeIdSet.add(article.KnowledgeArticleId);	
        	knowledgeIdSet.add(article.Id);	       
        }
       
        List<BWKnowledgeArticleLink__c> linkList = [SELECT Id, Type__c, Link_Title__c, Knowledge_Article__c, Link_URL__c 
                                                    FROM BWKnowledgeArticleLink__c 
                                                    WHERE Knowledge_Article__c IN :knowledgeIdSet
                                                    AND Type__c = 'Knowledge Article'];
        //System.debug('KnowledgeIdset: ' + knowledgeIdSet + '; LinkList: ' + linkList);
        Map<Id, List<BWKnowledgeArticleLink__c>> linkMap = new Map<Id, List<BWKnowledgeArticleLink__c>>();
        for (BWKnowledgeArticleLink__c articleLink : linkList) {
            KnowledgeUtility.addToMapOfLists(linkMap, articleLink.Knowledge_Article__c, articleLink);
        }
        //System.debug('LinkMap ' + linkMap);
        List<BWKnowledgeArticleLink__c> articleLinkList;
        
        for(sobject ka : scope){
            foundInBody = null;
            foundInTitle = null;
            foundInLinks = null;
            foundSearchTerms = new Set<String>();
            articleOutput = new List<String>();
            Knowledge__kav article = (Knowledge__kav)ka;
            for (String searchTerm : this.searchStringList) {
           		upperSearchTerm = searchTerm.toUpperCase();
                //System.debug('Search term: ' + upperSearchTerm);
                if (String.isNotBlank(article.BW_Article_Details__c)) {
                    upperDetails = article.BW_Article_Details__c.toUpperCase();
                    if (upperDetails.contains(upperSearchTerm)) {
                       //System.debug(article.id+': Body Contains ' + upperSearchTerm);
                	   articleIdSet.add(article.Id); 
					   foundSearchTerms.add(searchTerm); 
                       foundInBody = 'X';
                    }
                } 
                
                if (String.isNotBlank(article.Title)) {
                    upperTitle = article.Title.toUpperCase();
                    foundInTitle = searchString(upperTitle, upperSearchTerm);
                    if (foundInTitle != null) {
                       articleIdSet.add(article.Id); 
					   foundSearchTerms.add(searchTerm); 
                    }
                    
                } 
                
                if (linkMap.containsKey(article.Id)) {
                    articleLinkList = linkMap.get(article.Id);
                    System.debug('Links found for ' + article.Title + ': ' +  articleLinkList);
                    for (BWKnowledgeArticleLink__c articleLink : articleLinkList) {
                        if (String.isNotBlank(articleLink.Link_Title__c)) {
                        	upperLinkTitle = articleLink.Link_Title__c.toUpperCase();
                            if (upperLinkTitle.contains(upperSearchTerm)) {
                       			//System.debug(article.id+': Title Contains ' + upperSearchTerm);
                	   			articleIdSet.add(article.Id); 
					   			foundSearchTerms.add(searchTerm); 
                       			foundInLinks = 'X';
                                break;
                            } else {
                                //System.debug(article.Title+': linkeTitle' +  upperLinkTitle + ' does not Contain ' + upperSearchTerm);
                	   			 
                            }
                        }   
                        if (foundInLinks == null) {
                            if (String.isNotBlank(articleLink.Link_URL__c)) {
                        		upperLinkURL = articleLink.Link_URL__c.toUpperCase();
                                if (upperLinkURL.contains(upperSearchTerm)) {
                                    //System.debug(article.id+': Title Contains ' + upperSearchTerm);
                                    articleIdSet.add(article.Id); 
                                    foundSearchTerms.add(searchTerm); 
                                    foundInLinks = 'X';
                                    break;
                                }
                            }
                        } else {
                         	//System.debug(article.Title+': linkURL' +  upperLinkURL + ' does not Contain ' + upperSearchTerm);
                       }                  
                    }
                } else {
                    System.debug('No links found for ' + article.Title);
                }
                    
             } //look in title, related links  // the link title of related articles
            //stripped of spaces and & - /article number
            //System.debug('Search terms found in article: ' + foundSearchTerms);
            if (!foundSearchTerms.isEmpty()) {
            	foundSearchTermsList = new List<String>();
                foundSearchTermsList.addAll(foundSearchTerms);
                articleOutput.add(article.ArticleNumber); 
                articleOutput.add(article.Id);
                articleOutput.add('"' + article.Title + '"'); 
                articleOutput.add(String.join(foundSearchTermsList, '; '));
                articleOutput.add(foundInTitle);
                articleOutput.add(foundInBody);
                articleOutput.add(foundInLinks);
                articleOutput.add(String.valueOf(article.LastPublishedDate));
                articleOutput.add(article.ContentSponsor__c);
                articleOutput.add('Article');
                articleOutput.add(URL.getSalesforceBaseUrl().toExternalForm() +'/lightning/articles/Knowledge/' + article.UrlName);
                this.articleIdList.add(String.join(articleOutput, ','));
            }
            
       }
       //this.articleIdList.addAll(articleIdSet);
 	}
    
    
    public void finish(Database.BatchableContext BC){
   		System.debug('Sending email to ' + REQUEST_USER.email + ' for searchterm: ' + SEARCH_TEXT + '.  Number of articles found: ' + articleIdList.size());
        sendEmail(REQUEST_USER, SEARCH_TEXT, this.articleIdList, this.pageHeaders);
    }
    
    public static Boolean isValidRequester(User requestUser) {
       Group validGroup = getGroupByName(CONTENT_STRATEGY_GROUP_NAME);
        if (validGroup == null) {
         	throw new ArticleKeywordSearchBatchException('Group with this name cannot be located: ' + CONTENT_STRATEGY_GROUP_NAME);
        }
       return isGroupMember(requestUser, validGroup.Id);
    }
    
    public static Boolean isGroupMember(User groupUser, Id groupId) {
        if (groupuser == null || groupuser.Id == null || groupId == null) {
            System.debug('No groupuser or group Id provider');
            return false;
        }
    	List<GroupMember> memberList = [SELECT Id, groupID, UserOrGroupId FROM GroupMember WHERE groupID = :groupId AND
                                        UserOrGroupId = :groupUser.Id];
                                        
        return !memberList.isEmpty();                           
        
    }
    
    public static User getUserByAttuid(String attuid) {
        List<User> userList = [SELECT Id, Name, email, ATTUID__c from User WHERE ATTUID__c = :attuid AND isActive = true ORDER BY CreatedDate desc];
        
        if (userList.isEmpty()) {
            return null;
        } else {
            return userList[0];
        }  
    }
    
    public static Group getGroupByName(String groupName) {
        List<Group> groupList = [SELECT id, name, developerName FROM GROUP WHERE type='Regular' AND DeveloperName=:groupName]; 
        if (!groupList.isEmpty()) {
            System.debug('Group found for ' + grouplist[0]);
            return grouplist[0];
        } else {
            System.debug('No group found for ' +  groupName);
            return null;
        }
    }
    
    public static void sendEmail(User recipient, String searchTerm, List<String> articleIdList, List<String> pageHeaders) {
    	String requestInfoString = 'Keyword search for ' + searchTerm + ' performed ' + Datetime.now() + '; ' + articleIdList.size() + ' articles found.' + NEWLINE;
        String headerString = String.join(pageHeaders, ',') + NEWLINE;
        String idString = String.join(articleIdList, NEWLINE);
        Blob myBlob = Blob.valueof(requestInfoString + headerString + idString);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
        String body = 'Hi ' + recipient.Name + ', \r\n' + '  The attached file contains the list of published article Ids '
            + 'that contain the keyword you searched for: ' + searchTerm + '. There were ' + articleIdList.size() + ' articles found.';

        // Create the email attachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('keywordSearchTermResults' + stripCharacters(searchTerm) + '.csv');
        efa.setBody(myBlob);

        List<String> toAddresses = new List<String>{recipient.Email, UserInfo.getUserEmail() };

        // Sets the paramaters of the email
        email.setSubject(EMAIL_SUBJECT +  searchTerm);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody( body );

        email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});

        // Sends the email
        Messaging.SendEmailResult [] r = 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});   

    }

    public static String searchString(String searchText, String searchTerm) {
    	if (searchText.contains(searchTerm)) {
        	return 'X';
        } else {
            return null;
        }    
    }
    
    public static String stripCharacters(String originalString) {
        String strippedString;
        strippedString = originalString.replaceAll(stripCharsRegEx, '');
        return strippedString;
    }
    
    public class ArticleKeywordSearchBatchException extends Exception{}
}
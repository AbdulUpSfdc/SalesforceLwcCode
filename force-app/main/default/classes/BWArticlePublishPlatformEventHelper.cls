/*****
 Name             : BWArticlePublishPlatformEventHelper
 Description      : This is the helper class for publishing platform events when an article is published/archived
 ****/
public class BWArticlePublishPlatformEventHelper{
    @TestVisible private static Integer numPublishedEvents = 0;
    @TestVisible private static Integer numErrors = 0;
    
    @AuraEnabled
	public static String publishPlatformEvent(Id articleId){
		Set<Id> articleIdSet = new Set<Id>{articleId};
		return publishPlatformEvents(articleIdSet);
	}

	public static String publishPlatformEvents(Set<Id> articleIdSet){
		Boolean isError = false;
		List<ArticleDependencyUpdateRequest__e> articleEventList = new List<ArticleDependencyUpdateRequest__e>();
		for (Id articleId : articleIdSet){
			// Create an instance of the event and add it to the articleEventList
			ArticleDependencyUpdateRequest__e articleEvent = new ArticleDependencyUpdateRequest__e(ArticleId__c = articleId);
			articleEventList.add(articleEvent);
		}

		if (!articleEventList.isEmpty()){
            Integer i = 0;
			// Call method to publish events.
			List<Database.SaveResult> results = EventBus.publish(articleEventList);
			// Inspect publishing result for each event
			for (Database.SaveResult sr : results){
				if (sr.isSuccess()){
                    numPublishedEvents++;
					System.debug('Event published successfully for article Id : ' + articleEventList[i].ArticleId__c);
				} else{
					for (Database.Error err : sr.getErrors()){
						System.debug('Error returned: ' + err.getStatusCode()+' - ' + err.getMessage());
                        BWC_ExceptionUtils.handleException(new BWArticlePublishEventException(err.getMessage()), true);
					}
                    isError = true;
                    numErrors++;
                }
                i++;
            }
            System.debug('PLATFORM EVENTS PUBLISHED ::: ' + numPublishedEvents);
            System.debug('PLATFORM EVENTS FAILED TO PUBLISH ::: ' + numErrors);
		}
		return isError ? 'Failed':'Success';
	}
    
    public class BWArticlePublishEventException extends Exception {}
}
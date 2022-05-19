@RestResource(urlMapping='/ArticleLinkDependency/*')
global with sharing class ArticleLinkDependency {

    @HttpPost
    global static void doPost(String ArticleId){
        String Status;
        ArticleDependencyUpdateRequest__e addLinkDependency = new ArticleDependencyUpdateRequest__e(ArticleId__c=ArticleId);
        System.debug('addLinkDependency'+addLinkDependency);
        // Call method to publish events
        try{
        Database.SaveResult results = EventBus.publish(addLinkDependency);
        Status='Success';
        }
        catch(System.Exception e)
        {
            system.debug('ArticleLinkDependency:'+e);
                    // Log the exception
            BWC_ExceptionUtils.handleException(e, true);
            Status=e.getMessage();
        }
        //Database.SaveResult results = EventBus.publish(addLinkDependency);
        // Inspect publishing result for each event
        Map<String, String> obj = new Map<String, String>();
        obj.put('Status', Status);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.Serialize(obj));
     }
 
}
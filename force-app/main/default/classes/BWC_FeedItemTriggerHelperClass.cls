/*
Initial version - 03/22/2021 - Calling masking method: Story 1675.
*/
public class BWC_FeedItemTriggerHelperClass {
    
    public static void maskFeedPost() {
        
        List<FeedItem> listofFeedPosts = (List<FeedItem>)Trigger.new;
        Map<Id, FeedItem> mapOfOldFeedPosts = (Map<Id, FeedItem>)Trigger.oldMap;

        // Mask Body of the post
        for(FeedItem feedPost : listofFeedPosts) {
            // If insert or Body is changing on Update, mask the content
            if (feedPost.Body != null && (mapOfOldFeedPosts == null || feedPost.Body != mapOfOldFeedPosts.get(feedPost.Id).Body)) {
                feedPost.Body = BWC_Utils.maskSentence(feedPost.Body);
            }
        }
    }

    public static void updateLastActivityonCase() {

        String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
        String parentId;
        Set<Id> caseIds = new Set<Id>();

        for(FeedItem fi : (List<FeedItem>) Trigger.new) {
            parentId = fi.ParentId;
            if(String.isNotBlank(parentId) && parentId.startsWith(casePrefix)) {
                caseIds.add(fi.ParentId);
            }
        }

        if(caseIds.size()>0) {
            CaseOOP_Service.updateLastActivityonCase(caseIds);
        }
    }

    public static void postFeedItemWithMentions(String messageText, Id mentionId, Id subjectId) {
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();           
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();  
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
         
		ConnectApi.MentionSegmentInput mentionInput = new ConnectApi.MentionSegmentInput();
        mentionInput.id = mentionId;
        messageBodyInput.messageSegments.add(mentionInput);
        
        ConnectApi.TextSegmentInput textInput = new ConnectApi.TextSegmentInput();
        textInput.text = ' ' + messageText;
        messageBodyInput.messageSegments.add(textInput);
         
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = subjectId;
        
		ConnectApi.FeedElement feedElement =
       	ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
    }

}
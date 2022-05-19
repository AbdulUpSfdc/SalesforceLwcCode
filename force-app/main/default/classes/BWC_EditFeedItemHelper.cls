public without sharing class BWC_EditFeedItemHelper {
    /*
* Call this method from an after insert FeedItem trigger.
* It updates the feed items passed in and preserves @mentions.
*/
    public static void edit(FeedItem[] feedItems) {
        String communityId = Network.getNetworkId();
        List<String> feedItemIds = new List<String>();
        for (FeedItem f : feedItems) {
            feedItemIds.add(f.id);
        }
        // Get all feed items passed into the trigger.
        ConnectApi.BatchResult[] results = ConnectApi.ChatterFeeds.getFeedElementBatch(communityId, feedItemIds);
        List<FeedItem> feedItms = new List<FeedItem>();
        for (ConnectApi.BatchResult result : results) {
            if (result.isSuccess()) {
                Object theResult = result.getResult();
                if (theResult instanceof ConnectApi.FeedItem) {
                    ConnectApi.FeedItem item = (ConnectApi.FeedItem) theResult;  
                    ConnectApi.FeedItemInput input = BWC_EditFeedItemHelper.createFeedItemInputFromBody(item.body);
                    ConnectApi.ChatterFeeds.updateFeedElement(communityId, item.id, input);
                }
            }
            else { 
                System.debug('Failure in batch feed element retrieval: ' + result.getErrorMessage());
            }    
        } 
    }
    /* Takes an output body and returns a feed item input body that matches it.
This is useful for when you retrieve a feed item and want to either re-post or edit it. */
    public static ConnectApi.FeedItemInput createFeedItemInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput bodyInput = createInputFromBody(body);
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = bodyInput;
        return input;
    }
    /* Takes an output feed body and returns a message body input that matches it.
This is useful for when you retrieve a feed item or comment and want to either re-post or edit it. */
    public static ConnectApi.MessageBodyInput createInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput input = new ConnectApi.MessageBodyInput();
        input.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        for (ConnectApi.MessageSegment segment : body.messageSegments) {
            if (segment instanceof ConnectApi.TextSegment) {
                ConnectApi.TextSegment textOutput = (ConnectApi.TextSegment) segment;
                ConnectApi.TextSegmentInput textInput = new ConnectApi.TextSegmentInput();
                textInput.text = BWC_Utils.maskSentence(textOutput.text);
                input.messageSegments.add(textInput);
            }
            else if (segment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionOutput = (ConnectApi.MentionSegment) segment;
                ConnectApi.MentionSegmentInput mentionInput = new ConnectApi.MentionSegmentInput();
                mentionInput.id = mentionOutput.record.id;
                input.messageSegments.add(mentionInput);
            }
            else if (segment instanceof ConnectApi.HashtagSegment) {
                ConnectApi.HashtagSegment hashtagOutput = (ConnectApi.HashtagSegment) segment;
                ConnectApi.HashtagSegmentInput hashtagInput = new ConnectApi.HashtagSegmentInput();
                hashtagInput.tag = hashtagOutput.tag;
                input.messageSegments.add(hashtagInput);
            }
            else if (segment instanceof ConnectApi.LinkSegment) {
                ConnectApi.LinkSegment linkOutput = (ConnectApi.LinkSegment) segment;
                ConnectApi.LinkSegmentInput linkInput = new ConnectApi.LinkSegmentInput();
                linkInput.url = linkOutput.url;
                input.messageSegments.add(linkInput);
            }
            else if (segment instanceof ConnectApi.MarkupBeginSegment) {
                ConnectApi.MarkupBeginSegment markupBeginOutput = (ConnectApi.MarkupBeginSegment) segment;
                if(markupBeginOutput.markupType == ConnectApi.markupType.Hyperlink)
                {   ConnectApi.MarkupBeginSegmentInput markupBeginInput = new ConnectApi.MarkupBeginSegmentInput();
					markupBeginInput.url = markupBeginOutput.url;    
                    markupBeginInput.altText=markupBeginOutput.url;
                     markupBeginInput.markupType = markupBeginOutput.markupType;
                    input.messageSegments.add(markupBeginInput);
                }
                else
                {  ConnectApi.MarkupBeginSegmentInput markupBeginInput = new ConnectApi.MarkupBeginSegmentInput();
                    markupBeginInput.markupType = markupBeginOutput.markupType;
                    input.messageSegments.add(markupBeginInput);
                }
                
            }
            else if (segment instanceof ConnectApi.MarkupEndSegment) {
                ConnectApi.MarkupEndSegment markupEndOutput = (ConnectApi.MarkupEndSegment) segment;
                ConnectApi.MarkupEndSegmentInput markupEndInput = new ConnectApi.MarkupEndSegmentInput();
                markupEndInput.markupType = markupEndOutput.markupType;
                input.messageSegments.add(markupEndInput);
            }
            else if (segment instanceof ConnectApi.InlineImageSegment) {
                ConnectApi.InlineImageSegment inlineImageOutput = (ConnectApi.InlineImageSegment) segment;
                ConnectApi.InlineImageSegmentInput inlineImageInput = new ConnectApi.InlineImageSegmentInput();
                inlineImageInput.fileId = inlineImageOutput.thumbnails.fileId;
                inlineImageInput.altText = inlineImageOutput.altText;
                input.messageSegments.add(inlineImageInput);
            }        
        }
        return input;
    }
    
}
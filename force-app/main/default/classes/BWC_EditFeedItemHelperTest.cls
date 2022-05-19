@IsTest(SeeAllData=true)
public class BWC_EditFeedItemHelperTest {
    
    @IsTest(SeeAllData=true)
    static void testCreateInputFromBody() {
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        String expectedText = 'Text ';
        String expectedLink = 'http://link.com';
        String expectedHashtag = 'hashtag';
        String expectedBoldText = 'Bold text';
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedText + expectedLink + ' #' + expectedHashtag;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = UserInfo.getUserId();
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupBeginSegmentInput);
        
        textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = expectedBoldText;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegmentInput.markupType = ConnectApi.MarkupType.Bold;
        messageBodyInput.messageSegments.add(markupEndSegmentInput);
                
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = UserInfo.getUserId();
        
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        
        ConnectApi.MessageBodyInput input = BWC_EditFeedItemHelper.createInputFromBody(feedElement.body);
        System.assertEquals(2, input.messageSegments.size()-6, 'Wrong number of message segments.');
        
        System.assert(input.messageSegments.get(0) instanceof ConnectApi.TextSegmentInput, 'Segment 0 is not a text segment input.');
        ConnectApi.TextSegmentInput textInput = (ConnectApi.TextSegmentInput) input.messageSegments.get(0);
        System.assertEquals(expectedText, textInput.text, 'Segment 0 text does not match.');
        
        System.assert(input.messageSegments.get(1) instanceof ConnectApi.LinkSegmentInput, 'Segment 1 is not a link segment input.');
        ConnectApi.LinkSegmentInput linkInput = (ConnectApi.LinkSegmentInput) input.messageSegments.get(1);
        System.assertEquals(expectedLink, linkInput.url, 'Segment 1 url does not match.');
        
        System.assert(input.messageSegments.get(2) instanceof ConnectApi.TextSegmentInput, 'Segment 2 is not a text segment input.');
        ConnectApi.TextSegmentInput textInput2 = (ConnectApi.TextSegmentInput) input.messageSegments.get(2);
        System.assertEquals(' ', textInput2.text, 'Segment 2 text does not match.');
        
        System.assert(input.messageSegments.get(3) instanceof ConnectApi.HashtagSegmentInput, 'Segment 3 is not a hashtag segment input.');
        ConnectApi.HashtagSegmentInput hashtagInput = (ConnectApi.HashtagSegmentInput) input.messageSegments.get(3);
        System.assertEquals(expectedHashtag, hashtagInput.tag, 'Segment 3 hashtag does not match.');
        
        ConnectApi.FeedItemInput feedItemInput2 = BWC_EditFeedItemHelper.createFeedItemInputFromBody(feedElement.body);
        System.assertEquals(input, feedItemInput2.body, 'createFeedItemInputFromBody is returning a different input body than createInputFromBody.');
        
    }
    
    
    
}
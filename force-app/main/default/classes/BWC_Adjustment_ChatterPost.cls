// Class for handling chatter posts on Adjustments

public without sharing class BWC_Adjustment_ChatterPost {
    public static void postSOAFailMessageForManager(String workItemId) {
        // Getting adjustment
        Adjustment__c adj = [SELECT Id, Manager__c, Case__c FROM Adjustment__c WHERE Id = :workItemId LIMIT 1];

        // Getting logged in user info and employee record
        Employee__c emp = [SELECT Id, User__c, Name, EmployeeId__c FROM Employee__c WHERE User__c = :adj.Manager__c];

        // Constructing chatter message
        String chatterMessage =
            'Adjustment failed due to SOA adjustment limit. This is because of an incorrect user profile setup or invalid user within the queue.' +
            '\n' +
            'Agent Name: ' +
            emp.Name +
            '\n' +
            'Agent ATTUID: ' +
            emp.EmployeeId__c;

        // Posting feed item
        BWC_FeedItemTriggerHelperClass.postFeedItemWithMentions(chatterMessage, adj.Manager__c, adj.Case__c);
    }

    public static void postSOAFailMessageForQueue(String workItemId) {
        // Getting adjustment
        Adjustment__c adj = [SELECT Id, Case__c, Case__r.OwnerId FROM Adjustment__c WHERE Id = :workItemId LIMIT 1];

        // Getting queue and corresponding chatter group based on matching names
        Group soaQueue = [SELECT Id, Name FROM Group WHERE Id = :adj.Case__r.OwnerId LIMIT 1];
        List<CollaborationGroup> soaChatterGroup = soaQueue != null
            ? [SELECT Id, Name FROM CollaborationGroup WHERE Name = :soaQueue.Name LIMIT 1]
            : new List<CollaborationGroup>();

        // Getting logged in user info and employee record
        String loggedInUser = UserInfo.getUserId();
        Employee__c emp = [SELECT Id, User__c, Name, EmployeeId__c FROM Employee__c WHERE User__c = :loggedInUser];

        // Constructing chatter message
        String chatterMessage =
            'Adjustment failed due to SOA adjustment limit. This is because of an incorrect user profile setup or invalid user within the queue.' +
            '\n' +
            'Agent Name: ' +
            emp.Name +
            '\n' +
            'Agent ATTUID: ' +
            emp.EmployeeId__c;

        // Posting feed item
        if (soaChatterGroup.size() > 0) {
            BWC_FeedItemTriggerHelperClass.postFeedItemWithMentions(chatterMessage, soaChatterGroup[0].Id, adj.Case__c);
        }
    }

    // Whenever a user converts an adjustment, post to the new case with a link to the old one
    public static void postForConvertedAdjustment(String oldCaseId, String newCaseId) {
        List<Case> oldCase = [SELECT Id, CaseNumber FROM Case WHERE ID = :oldCaseId LIMIT 1];

        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        // Bolded title segment
        ConnectApi.MarkupBeginSegmentInput boldTitleBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        boldTitleBeginSegment.markupType = ConnectApi.MarkupType.Bold;
        messageInput.messageSegments.add(boldTitleBeginSegment);

        ConnectApi.TextSegmentInput titleSegment = new ConnectApi.TextSegmentInput();
        titleSegment.text = 'Adjustment Type Updated';
        messageInput.messageSegments.add(titleSegment);

        ConnectApi.MarkupEndSegmentInput boldTitleEndSegment = new ConnectApi.MarkupEndSegmentInput();
        boldTitleEndSegment.markupType = ConnectApi.MarkupType.Bold;
        messageInput.messageSegments.add(boldTitleEndSegment);

        // Line break, must use paragraph. I know.
        ConnectApi.MarkupBeginSegmentInput parOneBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        parOneBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
        messageInput.messageSegments.add(parOneBeginSegment);

        ConnectApi.TextSegmentInput parOneTextSegement = new ConnectApi.TextSegmentInput();
        parOneTextSegement.text = '&nbsp;';
        messageInput.messageSegments.add(parOneTextSegement);

        ConnectApi.MarkupEndSegmentInput parOneEndSegment = new ConnectApi.MarkupEndSegmentInput();
        parOneEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
        messageInput.messageSegments.add(parOneEndSegment);

        // Status message
        ConnectApi.TextSegmentInput statusTextSegment = new ConnectApi.TextSegmentInput();
        statusTextSegment.text = 'This case was created and updated from a previous adjustment case.';
        messageInput.messageSegments.add(statusTextSegment);

        // Line break two
        ConnectApi.MarkupBeginSegmentInput parTwoBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        parTwoBeginSegment.markupType = ConnectApi.MarkupType.Paragraph;
        messageInput.messageSegments.add(parTwoBeginSegment);

        ConnectApi.TextSegmentInput parTwoTextSegment = new ConnectApi.TextSegmentInput();
        parTwoTextSegment.text = '&nbsp;';
        messageInput.messageSegments.add(parTwoTextSegment);

        ConnectApi.MarkupEndSegmentInput parTwoEndSegment = new ConnectApi.MarkupEndSegmentInput();
        parTwoEndSegment.markupType = ConnectApi.MarkupType.Paragraph;
        messageInput.messageSegments.add(parTwoEndSegment);

        // Previous case number
        ConnectApi.TextSegmentInput prevCaseTextSegment = new ConnectApi.TextSegmentInput();
        prevCaseTextSegment.text = 'Previous Case Number: ' + oldCase[0].CaseNumber + ' ';
        messageInput.messageSegments.add(prevCaseTextSegment);

        // Adding () around the link
        ConnectApi.TextSegmentInput parenOne = new ConnectApi.TextSegmentInput();
        parenOne.text = '(';
        messageInput.messageSegments.add(parenOne);

        // Constructing the link
        // For the record to open in a subtab, you must use .lightning.force.com and LinkSegmentInput
        String hostName = URL.getSalesforceBaseUrl().getHost();
        String recordUrl = 'https://' + hostName.substringBefore('.') + '.lightning.force.com' + '/' + oldCase[0].Id;

        ConnectApi.LinkSegmentinput linkSegment = new ConnectApi.LinkSegmentinput();
        linkSegment.url = recordUrl;
        messageInput.messageSegments.add(linkSegment);

        // Adding () around the link
        ConnectApi.TextSegmentInput parenTwo = new ConnectApi.TextSegmentInput();
        parenTwo.text = ')';
        messageInput.messageSegments.add(parenTwo);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = newCaseId;

        ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);
    }
}
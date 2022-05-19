/*------------------------------------------------------------------------
Apex custom email service class that processess the incoming emails to salesforce from KANA.
PBCNTRSENT-395,PBCNTRSENT-393
History
<Date>      <Authors Name>     <Brief Description of Change>
6-July-2020  Mammet Developer  Custom apex email service class that handles all the incoming emails from KANA. This class is responsible for mapping email and case field 
& populating the 'Submission source code' on case record.
----------------------------------------------------------------------------*/
global with sharing class EmailToCase implements Messaging.inboundEmailHandler{
    //Instance variables..
    Messaging.InboundEmail email;
    Messaging.InboundEmailResult result;
    String emailSubject;
    String fromAddress;
    String submissionSourceCode='OTHER (NONE OF THE ABOVE)';
    List<SubmissionSourceEmailWrapper> bbSubmissionCodesWrapper_List;
    BBCaseWrapper bbcaseWrapper;
    Case oopCase;
    
    //This is the method from Messaging.InboundEmailHandler interface that needs to be implemented in order to process the incoming email messages to the email service for this class.
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) {
        this.email = email;
        this.emailSubject = this.email.subject;
        this.fromAddress = this.email.fromAddress;
        system.debug('==>'+this.email);
        
        result = new Messaging.InboundEmailResult();
        result.success=false;
        
        Boolean isThreadedReply = handleThreadedReply(email);
        if(isThreadedReply == true) {
            result.success = true;
        } else {
            String emailDomain = getEmailDomainAddress(fromAddress);
            if(String.isNotBlank(emailDomain)){
                syncSubmissionCode(emailDomain);    
            }
            //Non BB Case..
            if(submissionSourceCode!='evaluateBB'){
                createParentCase();
            }
            else{
                createBBCase();
            }
        }
        
        return result;
    }
    private void createBBCase(){
        bbcaseWrapper = new BBCaseWrapper();
        List<String> splittedEmailBody_List = new List<String>();
        
        if(email.plainTextBody != null){
            String beforeCaseInfo;
            String afterCaseInfo;
            String stringToProcess;
            if(email.plainTextBody.containsIgnoreCase('Case Information:')){
                beforeCaseInfo = email.plainTextBody.subStringBefore('Case Information:');
                afterCaseInfo = email.plainTextBody.subStringAfter('Case Information:');
                if(String.isNotBlank(afterCaseInfo)){
                    bbcaseWrapper.caseInfomation = afterCaseInfo.trim();    
                }        
            }//case info
            if(String.isNotBlank(beforeCaseInfo)){
                splittedEmailBody_List = beforeCaseInfo.split('\n');
            }
            if(splittedEmailBody_List.size()>0){
                for(String row : splittedEmailBody_List){
                    mapFields(row);        
                }
            }
            system.debug('==>bbcaseWrapper==>'+bbcaseWrapper);
            
            if(String.isNotBlank(bbcaseWrapper.bbCaseNumber)){
                List<Case> bbCase_List = new List<Case>();
                Boolean bbrExists = false;
                bbCase_List = checkForMatch(bbcaseWrapper.bbCaseNumber);
                if(bbCase_List.size() > 0){
                    if(String.isNotBlank(bBCaseWrapper.rebuttal) && bBCaseWrapper.rebuttal.equalsIgnoreCase('Y')){
                        for(Case bbr : bbCase_List){
                            if(bbr.SubmissionSourceCode__c.equalsIgnoreCase('7BR-BBB Rebuttal')){
                                bbrExists = true;
                                break;
                            }    
                        }
                        if(!bbrExists){
                            //create BBR Case..
                            populateCaseFields('7BR-BBB Rebuttal');
                        }
                    }
                } 
                else{//no match
                    if(String.isNotBlank(bBCaseWrapper.rebuttal) && bBCaseWrapper.rebuttal.equalsIgnoreCase('Y')){
                        //create rebuttal case 
                        populateCaseFields('7BR-BBB Rebuttal');                   
                    }else if(String.isNotBlank(bBCaseWrapper.rebuttal) && bBCaseWrapper.rebuttal.equalsIgnoreCase('N')){
                        //create BB Case...
                        populateCaseFields('7B-Better Business Bureau-BBB');
                    }
                }    
            }
        }
    }//createBBCase
    
    private void populateCaseFields(String submissionSourceCode){
        oopCase = new Case();
        oopCase.SubmissionSourceCode__c = submissionSourceCode;
        oopCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').Id;
        //oopCase.SubmissionSourceCode__c = submissionSourceCode;
        oopCase.Type='OOP';
        oopCase.Status='New';
        oopCase.Origin='Email';        
        oopCase.Subject = email.subject;
        
        //updated Priority logic based on SPTSFDCSPT-2795 - 2/25/21 @salesforce
        //if email subject contains urgent then case priority is set to High else Medium
        //oopCase.Priority='Medium';
        oopCase.Priority=(String.isNotBlank(oopCase.Subject) && oopCase.Subject.toLowerCase().contains('urgent'))?'High':'Medium';
        
        oopCase.Country__c = bBCaseWrapper.country;
        oopCase.BillingCountry__c = bBCaseWrapper.country;
        
        oopCase.AccountIdentifier__c = String.isNotBlank(bBCaseWrapper.accountNumber) ? bBCaseWrapper.accountNumber : ''; 
        
        //REQ # 3407 Retrirve related billing account to account identifier and assign to billing account field on case 
        if(String.isNotBlank(bBCaseWrapper.accountNumber)){
            Billing_Account__c ba = BWC_BillingAccount_Selector.getBillingAccountFromAcctIdentifier(bBCaseWrapper.accountNumber);
            if(ba != null){
                oopCase.Billing_Account__c = ba.Id;
            }
        }
        
        if(String.isNotBlank(bBCaseWrapper.customerName)){
            String firstName = bBCaseWrapper.customerName.subStringBefore(' ');
            String lastName = bBCaseWrapper.customerName.subStringAfter(' ');
            
            if(String.isNotBlank(firstName)){
                oopCase.ServiceCustFirstName__c = firstName;
                oopCase.BillingCustFirstName__c = firstName;
            }
            if(String.isNotBlank(lastName)){
                oopCase.ServiceCustLastName__c = lastName;
                oopCase.BillingCustLastName__c = lastName;
            }
            
        }
        if(String.isNotBlank(bBCaseWrapper.address)){
            oopCase.StreetName__c = bBCaseWrapper.address;
            oopCase.BillingStreet__c = bBCaseWrapper.address;
        }
        if(String.isNotBlank(bBCaseWrapper.city)){
            oopCase.City__c = bBCaseWrapper.city;
            oopCase.BillingCity__c = bBCaseWrapper.city;
        }
        if(String.isNotBlank(bBCaseWrapper.state)){
            oopCase.State__c = bBCaseWrapper.state;
            oopCase.BillingState__c = bBCaseWrapper.state;
        }
        if(String.isNotBlank(bBCaseWrapper.zip)){
            oopCase.ZipPostalCode__c = bBCaseWrapper.zip;
            oopCase.BillingZip__c = bBCaseWrapper.zip;
            
        }
        if(String.isNotBlank(bBCaseWrapper.emailAddres)){
            oopCase.BillingEmail__c = bBCaseWrapper.emailAddres;
            oopCase.ServiceEmail__c = bBCaseWrapper.emailAddres;
        }
        if(String.isNotBlank(bBCaseWrapper.phoneNumber)){
            oopCase.ServicePhone__c = bBCaseWrapper.phoneNumber;
            oopCase.BillingPhone__c = bBCaseWrapper.phoneNumber;
            
        }
        if(String.isNotBlank(bBCaseWrapper.bbCaseNumber)){
            oopCase.ReferenceData__c = bBCaseWrapper.bbCaseNumber;
        }
        if(String.isNotBlank(bBCaseWrapper.complainantName)){
            String firstName = bBCaseWrapper.complainantName.subStringBefore(' ');
            String lastName = bBCaseWrapper.complainantName.subStringAfter(' ');
            
            oopCase.ComplainantFirstName__c = String.isNotBlank(firstName) ? firstName :'--';
            oopCase.ComplainantLastName__c = String.isNotBlank(lastName) ? lastName :'--';
        }
        if(String.isNotBlank(bBCaseWrapper.reachedPhone)){
            oopCase.ReachedPhone__c = bBCaseWrapper.reachedPhone;
        }
        if(String.isNotBlank(bBCaseWrapper.dayPhone)){
            oopCase.DayPhone__c = bBCaseWrapper.dayPhone;
        }
        if(String.isNotBlank(bBCaseWrapper.bbbUrl) && !bbcaseWrapper.bbbUrl.equalsIgnoreCase('fetchNext')){
            oopCase.CaseURL__c = bBCaseWrapper.bbbUrl;
        }
        if(String.isNotBlank(bBCaseWrapper.serviceType)){
            //oopCase.CustomerType__c = bBCaseWrapper.serviceType;
        }
        if(String.isNotBlank(bBCaseWrapper.caseInfomation)){
            Integer fieldMaxLenght = Schema.SObjectType.Case.fields.Description.getLength();
            Integer consumedLength;
            //oopCase.Description += '\r\n';
            oopCase.Description = email.plainTextBody;
            
            consumedLength = bBCaseWrapper.caseInfomation.length();
            if(consumedLength > fieldMaxLenght){
                oopCase.Description = bBCaseWrapper.caseInfomation.subString(0,fieldMaxLenght);    
            }else{
                oopCase.Description = bBCaseWrapper.caseInfomation;    
            }
        }
        oopCase.OwnerId = [Select Id from Group where DeveloperName= 'IntakeQueue' and Type = 'Queue'].Id;
        
        try{
            insert oopCase;
            createEmailMessageRecord(oopCase);
            result.success=true;
        } 
        catch(Exception e) {
            result.success=true;
            BWC_ExceptionUtils.handleException(e, true);
        }    
    }
    private List<Case> checkForMatch(String caseIdentifier){
        List<Case> caseList = new List<Case>();
        caseList = [Select ID, SubmissionSourceCode__c From Case Where ReferenceData__c = :caseIdentifier];
        return caseList;    
    }
    private void fetchBbbUrl(String row){
        //Pattern myPattern = Pattern.compile('\\b(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]');
        //Matcher myMatcher = myPattern.matcher(row);
        /*if(myMatcher.find()){
            system.debug('row==>'+row.length()+'===>'+myMatcher.start()+'===>end'+myMatcher.end());
            Integer startIndex = myMatcher.start();
            Integer endIndex = myMatcher.end();
            Integer length = row.length();
            if(endIndex >= length){
                endIndex = length-1;
            }
            bbcaseWrapper.bbbUrl = row.subString(startIndex,endIndex);    
        }*/
        if(String.isNotBlank(row)){
            if(row.containsIgnoreCase('<')){
                bbcaseWrapper.bbbUrl = row.subStringBefore('<');    
            }
            else{
                bbcaseWrapper.bbbUrl = row.trim();
            }
        }
    }
    
    //method to parse and map values with wrapper variables
    private void mapFields(String row){
        if(String.isNotBlank(row)){
            if(String.isNotBlank(bbcaseWrapper.bbbUrl) && bbcaseWrapper.bbbUrl.equalsIgnoreCase('fetchNext')){
                bbcaseWrapper.bbbUrl='';
                fetchBbbUrl(row.trim());
                return;    
            }
            String key = row.substringBefore(':');
            String value = row.subStringAfter(':');
            if(String.isNotBlank(key)){
                if(key.trim().equalsIgnoreCase('Account Number')){
                    bbcaseWrapper.accountNumber = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Customer Name')){
                    bbcaseWrapper.customerName = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Address')){
                    bbcaseWrapper.address = value.trim();    
                }  
                else if(key.trim().equalsIgnoreCase('City')){
                    bbcaseWrapper.city = value.trim();    
                } 
                else if(key.trim().equalsIgnoreCase('State')){
                    if(String.isNotBlank(value) 
                       && MetadataSelector.stateCodeToName_Map!=null 
                       && MetadataSelector.stateCodeToName_Map.containsKey(value.trim().toUpperCase())){
                           bbcaseWrapper.state = MetadataSelector.stateCodeToName_Map.get(value.trim().toUpperCase());    
                       }
                } 
                else if(key.trim().equalsIgnoreCase('Zip')){
                    bbcaseWrapper.zip = value.trim();    
                } 
                else if(key.trim().equalsIgnoreCase('Email Address')){
                    bbcaseWrapper.emailAddres = value.subStringBefore('<').trim();    
                } 
                else if(key.trim().equalsIgnoreCase('Phone Number')){
                    bbcaseWrapper.phoneNumber = value.trim();    
                } 
                else if(key.trim().equalsIgnoreCase('CallBack Name')){
                    bbcaseWrapper.callBackName = value.trim();    
                } 
                else if(key.trim().equalsIgnoreCase('BBB CaseNo')){
                    bbcaseWrapper.bbCaseNumber = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Rebuttal')){
                    bbcaseWrapper.rebuttal = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Complainant Name')){
                    bbcaseWrapper.complainantName = value.trim();    
                }  
                else if(key.trim().equalsIgnoreCase('Complainant Phone number')){
                    bbcaseWrapper.complainantPhoneNumber = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Complainant Email address')){
                    bbcaseWrapper.complainantEmailAddress = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Reached Phone (Alternate)')){
                    bbcaseWrapper.reachedPhone = value.trim();    
                }  
                else if(key.trim().equalsIgnoreCase('Day Phone')){
                    bbcaseWrapper.dayPhone = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('BBB Url')){
                    if(String.isNotBlank(value.trim())){
                        fetchBbbUrl(value.trim());
                    }else{
                        bbcaseWrapper.bbbUrl = 'fetchNext';   
                    }  
                }
                else if(key.trim().equalsIgnoreCase('Date Received')){
                    bbcaseWrapper.dateReceived = value.trim();    
                }
                else if(key.trim().equalsIgnoreCase('Service Type')){
                    if(value.trim().equalsIgnoreCase('Residential')){
                        bBCaseWrapper.serviceType = 'Consumer';
                    }
                    else{
                        bBCaseWrapper.serviceType = 'Business (Other)';    
                    }
                    
                }                             
            }
        }
    }
    // create case Non BB..
    private void createParentCase(){
        oopCase = new Case();
        oopCase.RecordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get('OOP').Id;
        oopCase.SubmissionSourceCode__c = submissionSourceCode;
        oopCase.Type='OOP';
        oopCase.Status='New';
        oopCase.Origin='Email';        
        oopCase.Subject = email.subject;
        
        //updated Priority logic based on SPTSFDCSPT-2795 - 2/25/21 @salesforce
        //if email subject contains urgent then case priority is set to High else Medium
        //oopCase.Priority='Medium';
        oopCase.Priority=(String.isNotBlank(oopCase.Subject) && oopCase.Subject.toLowerCase().contains('urgent'))?'High':'Medium';
        
        //oopCase.Description = String.isNotBlank(email.subject) ? email.subject : 'Case created from Kana.';
        if(email.plainTextBody != null){
            Integer fieldMaxLenght = Schema.SObjectType.Case.fields.Description.getLength();
            Integer consumedLength;
            //oopCase.Description += '\r\n';
            oopCase.Description = email.plainTextBody;
            consumedLength = oopCase.Description.length();
            if(consumedLength > fieldMaxLenght){
                oopCase.Description = oopCase.Description.subString(0,fieldMaxLenght);    
            }
        }
        //oopCase.CustomerType__c='Consumer';
        oopCase.OwnerId = [Select Id from Group where DeveloperName= 'IntakeQueue' and Type = 'Queue'].Id;
        try{
            insert oopCase;
            createEmailMessageRecord(oopCase);
            result.success=true;
        }
        catch(Exception e) {
            result.success=false;
            BWC_ExceptionUtils.handleException(e, true);
        }
    }
    
    //Insert email message..
    private void createEmailMessageRecord(Case oopCase){
        Integer htmlBodyFieldLength = Schema.SObjectType.EmailMessage.fields.HtmlBody.getLength();
        Integer textBodyFieldLength = Schema.SObjectType.EmailMessage.fields.TextBody.getLength();
        
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.FromName;
        emailMessage.ToAddress = email.toAddresses == null ? '' : joinList(email.toAddresses,',', 4000); 
        emailMessage.CcAddress = email.ccAddresses == null ? '' : joinList(email.ccAddresses,',', 4000); 
        emailMessage.Subject = email.Subject;
        emailMessage.Status = '0';
        emailMessage.ParentId = oopCase.Id;
        emailMessage.Incoming=true;
        
        if(email.htmlBody != null){
            if(email.htmlBody.length() >= htmlBodyFieldLength){            
                emailMessage.HtmlBody = emailMessage.HtmlBody.subString(0,htmlBodyFieldLength);
            }else{
                emailMessage.HtmlBody = email.htmlBody;
            }
        }
        if(email.plainTextBody != null){
            if(email.plainTextBody.length() > textBodyFieldLength){
                emailMessage.TextBody = email.plainTextBody.subString(0,textBodyFieldLength);
            }else{
                emailMessage.TextBody = email.plainTextBody;
            }
        }
        try{
            insert emailMessage;
            addAttachments(emailMessage);
        }
        catch(Exception e) {
            BWC_ExceptionUtils.handleException(e, true);
        }
        //add attachment
    }
    
    //Insert attachment to respective email message.
    private void addAttachments(EmailMessage emailMessage){
        if (email.binaryAttachments != null || email.textAttachments!=null){
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            List<ContentVersion> cvList = new List<ContentVersion>();
            //add text attachment..
            
            if(email.textAttachments!=null){
                for(Messaging.InboundEmail.textAttachment textAttach : email.textAttachments){
                    ContentVersion cv = new ContentVersion();
                    cv.VersionData = Blob.valueOf(textAttach.body);
                    cv.Title = textAttach.fileName;
                    cv.PathOnClient = textAttach.fileName;
                    cvList.add(cv);   
                }
            }
            
            //add binary attachment
            if(email.binaryAttachments != null){
                for (Messaging.InboundEmail.binaryAttachment binAttach :email.binaryAttachments){
                    ContentVersion cv = new ContentVersion();
                    cv.VersionData = binAttach.body;
                    cv.Title = binAttach.fileName;
                    cv.PathOnClient = binAttach.fileName;
                    cvList.add(cv);
                }
            }
            if(cvList.size() >0 ){
                insert cvList;
            }
            for(ContentVersion cv : [select ContentDocumentId from ContentVersion where id IN :cvList]){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = emailMessage.Id;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.ShareType = 'V';
                cdlList.add(cdl);
                
                cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = emailMessage.ParentId;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdl.ShareType = 'V';
                cdlList.add(cdl);
            } 
            if(cdlList.size() >0 ){
                insert cdlList;
            }  
        } 
    } 
    
    //retrieve the email domain from the email fromAddress
    private String getEmailDomainAddress(String fromAddress){
        Integer startIndex;
        Integer length;
        String emailDomainName='';
        
        if(String.isNotBlank(fromAddress)){
            startIndex = fromAddress.lastIndexOf('@');
            length = fromAddress.length();
            emailDomainName = fromAddress.substring(startIndex, length);
        }
        return emailDomainName;
    }
    
    //This method decides the submission source code that is assigned to the case record.
    private void syncSubmissionCode(String emailDomain){
        Map<String,SubmissionSourceEmailWrapper> submissionSourceEmailToCode_Map = generateWrapperToCode_Map(emailDomain);
        List<SubmissionSourceEmailWrapper> completeEmailMatch_List = new List<SubmissionSourceEmailWrapper>();
        List<SubmissionSourceEmailWrapper> emailDomainMatch_List = new List<SubmissionSourceEmailWrapper>();
        
        for(SubmissionSourceEmailWrapper wrapper : submissionSourceEmailToCode_Map.values()){
            if(wrapper.emailKeyWord_Set!=null && wrapper.emailKeyWord_Set.size()>0){
                if(wrapper.emailKeyWord_Set.contains(fromAddress.toLowerCase())){
                    completeEmailMatch_List.add(wrapper);    
                }
                else if(wrapper.emailKeyWord_Set.contains(emailDomain.toLowerCase())){
                    emailDomainMatch_List.add(wrapper);
                }     
            }
        }//for ends..
        //In case of complete address match..
        if(completeEmailMatch_List.size()>0){
            processSubmissionCodeSync(completeEmailMatch_List, emailDomain);
        }
        else if(emailDomainMatch_List.size()>0 && submissionSourceCode.equalsIgnoreCase('OTHER (NONE OF THE ABOVE)')){
            //In case of email domain match
            processSubmissionCodeSync(emailDomainMatch_List, emailDomain);
        }
    }
    
    //helper methods that decides the submission source code of the case to be created.
    private void processSubmissionCodeSync(List<SubmissionSourceEmailWrapper> submissionCodeWrapper_List, String emailDomain){
        Set<String> bbSubmissionCodes = new Set<String>();
        bbSubmissionCodes.add('7B-Better Business Bureau-BBB'.toLowerCase());
        bbSubmissionCodes.add('7BR-BBB Rebuttal'.toLowerCase());
        bbSubmissionCodesWrapper_List = new List<SubmissionSourceEmailWrapper>();
        
        //Integer matchCountForNonBbWithSub=0;
        //Integer matchCountForNonBbWithoutSub=0;
        Integer matchCountForNonBb=0;
        String defaultSubmissionCode='OTHER (NONE OF THE ABOVE)';
        
        for(SubmissionSourceEmailWrapper wrapper : submissionCodeWrapper_List){
            if(bbSubmissionCodes.contains(wrapper.submissionSourceCode.toLowerCase())){
                bbSubmissionCodesWrapper_List.add(wrapper);
                continue;    
            }
            
            if(wrapper.subjectKeyWord_Set.size()>0){
                submissionSourceCode = 'OTHER (NONE OF THE ABOVE)';
                for(String currentSubject : wrapper.subjectKeyWord_Set){
                    if(emailSubject.containsIgnoreCase(currentSubject.trim())){
                        submissionSourceCode = wrapper.submissionSourceCode;
                        //subjectFound=true;
                        //matchCountForNonBbWithSub++;
                        matchCountForNonBb++;
                        break;
                    }
                }
            }else{
                defaultSubmissionCode = wrapper.submissionSourceCode; 
                //matchCountForNonBbWithoutSub++;
                matchCountForNonBb++;   
            }
        }//outer for ends...
        if(bbSubmissionCodesWrapper_List.size()>0){
            submissionSourceCode = 'evaluateBB';    
        }
        else if(matchCountForNonBb > 1 ){
            submissionSourceCode = 'OTHER (NONE OF THE ABOVE)';    
        }
        else if(submissionSourceCode == 'OTHER (NONE OF THE ABOVE)' && !defaultSubmissionCode.equalsIgnoreCase('OTHER (NONE OF THE ABOVE)')){
            submissionSourceCode = defaultSubmissionCode;
        }
    }
    
    //generates the map of SubmissionSourceEmailWrapper to submission source code map..
    private Map<String,SubmissionSourceEmailWrapper> generateWrapperToCode_Map(String emailDomainName){
        Map<String,SubmissionSourceEmailWrapper> submissionSourceEmailToCode_Map = new Map<String,SubmissionSourceEmailWrapper>();
        SubmissionSourceEmailWrapper submissionSourceEmailWrapper;
        List<String> subjectKeyWord_List;
        List<String> emailKeyWord_List;
        
        Set<String> subjectKeyWord_Set;
        Set<String> emailKeyWord_Set;
        for(SubmissionSourceEmail__c submissionSourceEmail : [Select Name, CaseAdmin__r.SubmissionSource__c,CaseAdmin__r.Subject__c From SubmissionSourceEmail__c Where Name Like :('%'+emailDomainName)]){
            if(submissionSourceEmailToCode_Map==null){
                submissionSourceEmailToCode_Map = new Map<String,SubmissionSourceEmailWrapper>();    
            }
            
            if(submissionSourceEmailToCode_Map.containsKey(submissionSourceEmail.CaseAdmin__r.SubmissionSource__c)){
                subjectKeyWord_List = new List<String>();
                emailKeyWord_Set = new Set<String>();
                emailKeyWord_Set.add(submissionSourceEmail.Name.toLowerCase());
                
                if(String.isNotBlank(submissionSourceEmail.CaseAdmin__r.Subject__c)){
                    subjectKeyWord_List = submissionSourceEmail.CaseAdmin__r.Subject__c.toLowerCase().split(',');
                }
                subjectKeyWord_Set = new Set<String>();
                if(subjectKeyWord_List.size()>0){
                    subjectKeyWord_Set.addAll(subjectKeyWord_List);
                }
                
                submissionSourceEmailWrapper = new SubmissionSourceEmailWrapper();
                submissionSourceEmailToCode_Map.get(submissionSourceEmail.CaseAdmin__r.SubmissionSource__c).emailKeyWord_Set.addAll(emailKeyWord_Set);
                submissionSourceEmailToCode_Map.get(submissionSourceEmail.CaseAdmin__r.SubmissionSource__c).emailKeyWord_Set.addAll(subjectKeyWord_Set);
            }else{
                subjectKeyWord_List = new List<String>();
                subjectKeyWord_List = new List<String>();
                emailKeyWord_Set = new Set<String>();
                emailKeyWord_Set.add(submissionSourceEmail.Name.toLowerCase());
                if(String.isNotBlank(submissionSourceEmail.CaseAdmin__r.Subject__c)){
                    subjectKeyWord_List = submissionSourceEmail.CaseAdmin__r.Subject__c.toLowerCase().split(',');
                }
                subjectKeyWord_Set = new Set<String>();
                if(subjectKeyWord_List.size()>0){
                    subjectKeyWord_Set.addAll(subjectKeyWord_List);
                }
                submissionSourceEmailWrapper = new SubmissionSourceEmailWrapper();
                submissionSourceEmailWrapper.submissionSourceCode =  submissionSourceEmail.CaseAdmin__r.SubmissionSource__c;
                submissionSourceEmailWrapper.emailKeyWord_Set = emailKeyWord_Set;
                submissionSourceEmailWrapper.subjectKeyWord_Set = subjectKeyWord_Set;
                submissionSourceEmailToCode_Map.put(submissionSourceEmailWrapper.submissionSourceCode, submissionSourceEmailWrapper);    
            }    
        }//for ends...
        return submissionSourceEmailToCode_Map;
    }
    
    //generates a string containing all the toAddress from incoming email message. 
    private String joinList(List<String> itemsList, String separator, Integer maxChars){
        String stringified = String.join(itemsList, separator);
        if(stringified.length() > maxChars){
            itemsList.remove(itemsList.size()-1);
            return joinList(itemsList, separator, maxChars);
        }
        return stringified;
    }
    
    // threaded reply
    private Boolean handleThreadedReply(Messaging.InboundEmail inboundEmail) {
        Boolean handled = false;
        // 'Sandbox: test [ ref:_00D0n96sW._5000n7aIxb:ref ]'
        //String emailSubject = inboundEmail.subject;
        //String threadIdString = emailSubject.substringBetween('[ ref:', ':ref ]');
        List<Messaging.InboundEmail.Header> headers = inboundEmail.headers;
        //System.debug('*** headers: ' + headers);
        //if(String.isNotBlank(threadIdString)) {
        if(headers != NULL && !headers.isEmpty()) {
            //Id caseId = Cases.getCaseIdFromEmailThreadId(threadIdString);
            Id caseId;
            try{
                caseId = Cases.getCaseIdFromEmailHeaders(headers);
            system.debug('*** CaseIdFromEmail: ' + caseId);
            }
            catch(Exception e){
                BWC_ExceptionUtils.handleException(e, true);
            }
            
            if(caseId != NULL) {
                EmailMessage message = new EmailMessage();
                message.ParentId = caseId;
                //message.RelatedToId = caseId;
                message.FromAddress = inboundEmail.fromAddress;
                message.FromName = inboundEmail.fromName;
                message.ToAddress = inboundEmail.toAddresses[0];
                message.Subject = inboundEmail.subject;
                message.HtmlBody = inboundEmail.htmlBody;
                message.TextBody = inboundEmail.plainTextBody;
                //message.Headers = inboundEmail.headers;
                
                try {
                    insert message;
                    addAttachments(message);
                   handled = true;
                } 
                catch(Exception e) {
                    BWC_ExceptionUtils.handleException(e, true);
                }    
            }
        }

        return handled;
    }

    //Wrapper class which contains all the email address and keywords in subject & respective submission source code.
    class SubmissionSourceEmailWrapper{
        public String submissionSourceCode;
        public Set<String> emailKeyWord_Set; 
        public Set<String> subjectKeyWord_Set;
        
        public SubmissionSourceEmailWrapper(){
            submissionSourceCode='';
            emailKeyWord_Set = new Set<String>();
            subjectKeyWord_Set = new Set<String>();                
        }
    }
    //BB case wrapper
    class BBCaseWrapper{
        String accountNumber;
        String customerName;
        String address;
        String city;
        String state;
        String country='United States';
        String zip;
        String emailAddres;
        String phoneNumber;
        String callBackName; // no ampping available
        String bbCaseNumber;
        String rebuttal;
        String complainantName;
        String complainantPhoneNumber;//no mapping 
        String complainantEmailAddress;// no mapping
        String reachedPhone;
        String dayPhone;
        String bbbUrl;
        String dateReceived;
        String caseInfomation;
        String serviceType;
    }
}
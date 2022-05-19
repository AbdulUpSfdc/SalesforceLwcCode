/*********
Name            : KnowledgeTriggerHelper
Description     : This is helper class for the trigger KnowledgeTrigger.
*********/
public with sharing class KnowledgeTriggerHelper{
    //private static string sponsorPostFix = '@att.com%';
    //private static string AUTO_PUBLISH_PERM_AUTHOR_GROUP = 'Auto Publish Permission Authors';
    public static void setFieldValues(List<Knowledge__kav> newKnowledgeList){
        Set<Id> knowledgeArticleIDSet = new Set<Id>();
        List<Knowledge__kav> existingArticleList;
        Set<Id> existingKnowledgeArticleIDSet = new Set<Id>();
        List<String> lstSponsorUID = new List<String>();
        List<String> lstSecondarySponsorUID = new List<String>();
        for (Knowledge__kav knowledge : newKnowledgeList){
            if (knowledge.KnowledgeArticleId != NULL){
                knowledgeArticleIDSet.add(knowledge.KnowledgeArticleId);
            }
            if (knowledge.ContentSponsor__c != NULL){
                lstSponsorUID.add(knowledge.ContentSponsor__c);
            }
            if (knowledge.BWSecContentSponsor__c != NULL){
                lstSecondarySponsorUID.add(knowledge.BWSecContentSponsor__c);
                
            }
        }
        existingArticleList = [SELECT Id, versionnumber, createddate, ArticleNumber, publishstatus, KnowledgeArticleId, BWScheduledArticlePublicationDate__c, ContentSponsor__c, BWSecContentSponsor__c
                               FROM Knowledge__kav
                               WHERE KnowledgeArticleId IN :knowledgeArticleIDSet];
        
        for (Knowledge__kav knowledge : existingArticleList){
            if (knowledge.KnowledgeArticleId != NULL){
                existingKnowledgeArticleIDSet.add(knowledge.KnowledgeArticleId);
            }
        }
        
        /*  List<User> lstSponsors =[SELECT Email,ATTUID__c ,FirstName,LastName,FederationIdentifier FROM User where FederationIdentifier=:lstSponsorUID OR FederationIdentifier=:lstSecondarySponsorUID];
            Map<String, String> emailToUserMap = new Map<String, String>();
            Map<String, User> nameToUserMap = new Map<String, User>();
            for (User u : lstSponsors) {
                emailToUserMap.put(u.FederationIdentifier,u.Email);
                nameToUserMap.put(u.FederationIdentifier,u);
            }*/
        
        for (Knowledge__kav knowledge : newKnowledgeList){
            if (knowledge.BWScheduledArticlePublicationDate__c != NULL && existingKnowledgeArticleIDSet.contains(knowledge.KnowledgeArticleId)){
                knowledge.BWScheduledArticlePublicationDate__c = null;
            }
            if (knowledge.CustomValidationStatus__c == TRUE && knowledge.CustomPublicationStatus__c != NULL && existingKnowledgeArticleIDSet.contains(knowledge.KnowledgeArticleId)){
                knowledge.CustomValidationStatus__c = FALSE;
                knowledge.CustomPublicationStatus__c = NULL;
            }
            if ((knowledge.FutureReviewDate__c != NULL || knowledge.FutureReviewDate__c == NULL) && existingKnowledgeArticleIDSet.contains(knowledge.KnowledgeArticleId)){
                knowledge.FutureReviewDate__c = system.now().addMonths(6);
            }
            /*  if(knowledge.ContentSponsor__c != NULL || knowledge.ContentSponsor__c != '' ){
                    String currSponsorUID=knowledge.ContentSponsor__c;
                    String currSponsorEmail=emailToUserMap.get(currSponsorUID);
                    knowledge.Content_Sponsor_Email__c =currSponsorEmail;
                    string firstName = nameToUserMap.get(currSponsorUID).FirstName;
                    String LastName = nameToUserMap.get(currSponsorUID).LastName;
                    knowledge.Content_Sponsor_Name__c  = firstName +' '+LastName;
                }
                if(knowledge.BWSecContentSponsor__c != NULL || knowledge.BWSecContentSponsor__c != '' ){
                    String currSecSponsorUID=knowledge.BWSecContentSponsor__c;
                    String currSecSponsorEmail=emailToUserMap.get(currSecSponsorUID);
                    knowledge.Secondary_Content_Sponsor_Email__c  =currSecSponsorEmail;
                    string secfirstName = nameToUserMap.get(currSecSponsorUID).FirstName;
                    String secLastName = nameToUserMap.get(currSecSponsorUID).LastName;
                    knowledge.Secondary_Content_Sponsor_Name__c   = secfirstName +' '+secLastName;
                }*/        
        }
    }
    
    /* // commented by  Sai Nishanth
    // DO NOT DELETE THIS METHOD. ITS A PART OF A POC TO VALIDATE SMART LINKS
    public static void validateSmartLinks(List<Knowledge__kav> articles){
        for(Knowledge__kav article : articles){
            if(String.isBlank(article.BW_myCSP_Article_Id__c)){
                if(String.isNotBlank(article.BW_Article_Summary__c)){
                    Boolean hasInvalidLinks = containsInvalidLink(article.BW_Article_Summary__c);
                    if(hasInvalidLinks){
                        article.BW_Article_Summary__c.addError('Contains invalid link(s)');
                    }
                }
                if(String.isNotBlank(article.BW_Article_Details__c)){
                    Boolean hasInvalidLinks = containsInvalidLink(article.BW_Article_Details__c);
                    if(hasInvalidLinks){
                        article.BW_Article_Details__c.addError('Contains invalid link(s)');
                    }
                }
                if(String.isNotBlank(article.BW_External_URL__c)){
                    Boolean hasInvalidLinks = containsInvalidLink(article.BW_External_URL__c);
                    if(hasInvalidLinks){
                        article.BW_External_URL__c.addError('Contains invalid link(s)');
                    }
                }
            }
        }
    }
    // DO NOT DELETE THIS METHOD. ITS A PART OF A POC TO VALIDATE SMART LINKS
    public static Boolean containsInvalidLink(String fieldContent){
        Boolean hasInvalidLink = false;
        String regex = '(?i)<a( data-lightning-target=\"[_a-z]{3,12}\")? href=\"/articles/Knowledge/[^>]*[\"] target=\"_blank\">';

        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(fieldContent);
        while(matcher.find()){
            hasInvalidLink = true;
            String invalidLink = matcher.group();
            system.debug('INVALID LINK FOUND ::: '+ invalidLink);
            break;
        }
        return hasInvalidLink;
    }*/
    // commented by  Sai Nishanth

    /*public static void afterInsert(List<Knowledge__kav> newKnowledgeList){
        Set<String> sponsersIds = new Set<String>();
        for (Knowledge__kav knowledge : newKnowledgeList){
            if (knowledge.ContentSponsor__c != NULL){
                sponsersIds.add(knowledge.ContentSponsor__c + sponsorPostFix);
            }
        }
        if (sponsersIds.size() > 0){
            makeSponsorFollowing(newKnowledgeList, sponsersIds);
        }
    }*/
    
    // This method would fire when the CustomPublicationStatus__c field is updated to Ready for Publication.
    /*  public static void afterUpdate(List<Knowledge__kav> newKnowledgeList, Map<id, Knowledge__kav> oldKnowledgeList){
        try{
            system.debug('New Knowledge'+ newKnowledgeList);
            system.debug('Old Knowledge'+ oldKnowledgeList);
            Set<Id> publishedArticleIds = new Set<Id>();
            Datetime currentTime = System.Now();
            // Integer currenthour = currentTime.hour();
            List<Knowledge__kav> knowledgeList = new List<Knowledge__kav>();
            Set<String> groupNames = new Set<String>();
            for (GroupMember gm : [select group.name,group.DeveloperName from GroupMember where UserOrGroupId = :UserInfo.getUserId()]){
                groupNames.add(gm.group.name);
            }
            for(Knowledge__kav knowledge: newKnowledgeList){
                if(knowledge.CustomPublicationStatus__c != oldKnowledgeList.get(knowledge.Id).CustomPublicationStatus__c
                && knowledge.CustomPublicationStatus__c == 'Ready for Publication'){
                    publishedArticleIds.add(knowledge.KnowledgeArticleId);
                    knowledgeList.add(knowledge);
                }
            }
            List<Knowledge__kav> updateList = new List<Knowledge__kav>();

            if(knowledgeList.size() > 0){
                for(Knowledge__kav ka: knowledgeList){
                    if(ka.NumberOfArchivedArticles__c > 0){
                        ka.addError('Validation failed due references to expired and/or archived articles within the article body. Please review the Status in the Knowledge Article Links list for errors and re-publish.');
                    }
                    else if(ka.CustomValidationStatus__c != TRUE){
                        ka.addError('Custom Validation Status must be set to true to publish article');
                    }
                    else if(!groupNames.contains(AUTO_PUBLISH_PERM_AUTHOR_GROUP)){
                        ka.addError('You are not authorized to auto publish. Please assign to the content strategy team.');
                    }
                    else if(ka.BWArticlePublicationDate__c != null ){
                        ka.addError('Article Scheduled for Publishing, cannot be published immediately.');
                    }
                    else{
                        KbManagement.PublishingService.publishArticle(ka.KnowledgeArticleId, true);
                    }
                }
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
    }*/
    /*private static void makeSponsorFollowing(List<Knowledge__kav> newKnowledgeList, Set<String> sponsersIds){
        Map<String, Id> userIdBySponsorId = getUserIdBySponsorId(sponsersIds);
        for (Knowledge__kav knowledge : newKnowledgeList){
            if (userIdBySponsorId.containsKey(knowledge.ContentSponsor__c)){
                ConnectApi.ChatterUsers.follow(null, userIdBySponsorId.get(knowledge.ContentSponsor__c), knowledge.Id);
            }
        }
    }*/
    
    /*@testvisible
    private static Map<String, Id> getUserIdBySponsorId(Set<String> sponsersIds){
        Map<String, Id> userIdBySponsorId = new Map<String, Id>();
        try{
            for (User usr : [SELECT Id, Username
                             FROM User
                             WHERE Username LIKE :sponsersIds]){
                                 userIdBySponsorId.put(usr.Username.split('@')[0], usr.Id);
                             }
        } catch (Exception e){
        }
        System.debug('@@##: ' + userIdBySponsorId);
        return userIdBySponsorId;
    }*/
    
    /* public static void CreateDefaultAllDataCategory(Map<ID, Knowledge__kav> kavIdToKav) {
        try {
            // We first all all the kavIds and we will later remove them as we find they have data categories
            Set<ID> kavIdsWithoutCategories = new Set<ID>(kavIdToKav.keySet());
            List<Knowledge__DataCategorySelection> articleCategories = new List<Knowledge__DataCategorySelection>();
            // Get any data category for the article. If one exists, we don't need to create the 'All__c' default under 'Channel__c'
            for(Knowledge__DataCategorySelection kdcs: [SELECT id, parentId, datacategorygroupname, datacategoryname FROM Knowledge__DataCategorySelection WHERE parentId IN :kavIdToKav.keySet() LIMIT 1]) {
            kavIdsWithoutCategories.remove(kdcs.parentId);
            }
            // Create default All__c data category
            for(ID kavId: kavIdsWithoutCategories) {

            Knowledge__DataCategorySelection articleCategory = new Knowledge__DataCategorySelection();
            articleCategory.DataCategoryGroupName = 'Channel';
            articleCategory.DataCategoryName = 'All';
            articleCategory.ParentId = kavId;
            articleCategories.add(articleCategory);

            }

            insert articleCategories;
            } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            }

    }*/
            /*SPTSFDCSPT-9986,SPTSFDCSPT-9987 Populating Article SME Object Automation Pt. 1
        @author: Sai Nishanth
        @reviwer: Kerensa
        */
    public static void copySMEtoNewArticle(Map<Id, Knowledge__kav> newArticlesMap){
        Map<Id, Id> parentIdArticleIdMap = new Map<Id, Id>();
        Map<String, Id> uidMap = new Map<String, Id>();
        Set<String> attuidSet = new Set<String>();
        List<BWKMArticleSME__c> newSMEList = new List<BWKMArticleSME__c>();
        try{
            for (Knowledge__kav article : newArticlesMap.values()) {
                parentIdArticleIdMap.put(article.KnowledgeArticleId, article.id);
                if(article.FirstPublishedDate == null){
                    if (String.isNotBlank(article.ContentSponsor__c)) {
                        attuidSet.add(article.ContentSponsor__c);
                    }
                    if (String.isNotBlank(article.BWSecContentSponsor__c)) {
                        attuidSet.add(article.BWSecContentSponsor__c);
                    }
                }
            }

            if(!attuidSet.isEmpty()){
                //get attuid to user id map
                uidMap = getUserMap(attuidSet);
                    
                for (Knowledge__kav article : newArticlesMap.values()){
                    if (uidMap.containsKey(article.ContentSponsor__c.toLowerCase().trim())){
                        BWKMArticleSME__c newPCS= new BWKMArticleSME__c();
                        newPCS.Knowledge_Article__c = article.Id;
                        newPCS.User__c = uidMap.get(article.ContentSponsor__c.toLowerCase().trim());
                        newPCS.Role__c = KM_Constants.PRIM_CONTENT_SPONSER;
                        newSMEList.add(newPCS);
                    } 
                    else {
                        article.addError('ContentSponsor__c', KM_Constants.CONTENT_SPONSER_INVALID_ATTUID_ERROR_MESSAGE);
                    }
                    if (String.isNotBlank(article.BWSecContentSponsor__c)) {
                        if(uidMap.containsKey(article.BWSecContentSponsor__c.toLowerCase().trim())){
                            BWKMArticleSME__c newSCS= new BWKMArticleSME__c();
                            newSCS.Knowledge_Article__c = article.Id;
                            newSCS.User__c = uidMap.get(article.BWSecContentSponsor__c.toLowerCase().trim());
                            newSCS.Role__c = KM_Constants.SEC_CONTENT_SPONSER;
                            newSMEList.add(newSCS);
                        }
                        else {
                            if(!test.isRunningTest()){
                            article.addError('BWSecContentSponsor__c', KM_Constants.CONTENT_SPONSER_INVALID_ATTUID_ERROR_MESSAGE);
                            }
                        }
                    } 
                }
            }
            
            if (!newSMEList.isEmpty()){
                Database.SaveResult[] smeInserted = Database.insert(newSMEList, false);
                for (Integer i = 0; i < smeInserted.size(); i++){
                    if (!smeInserted[i].isSuccess()) {
                        newArticlesMap.get(newSMEList[i].Knowledge_Article__c).addError(KM_Constants.SME_INSERT_RECORD_ERROR_MESSAGE);
                    }
                }
            }
        } 
        catch(exception errormsg) {
            String errMsg = KM_Constants.SME_INSERT_RECORD_ERROR_MESSAGE;
            system.debug(errmsg);   
        }
    }
    
    //method to create(copy) new SME records
    private static BWKMArticleSME__c constructSME(BWKMArticleSME__c smeRec, id masterArtclID){
        BWKMArticleSME__c newSME =new BWKMArticleSME__c(Knowledge_Article__c = masterArtclID, 
                                                        Role__c = smeRec.Role__c, 
                                                        User__c = smeRec.User__c
                                                        );
        return newSME;
    }
    
    public static void createSMERecordsOnUpdate(Map<Id, Knowledge__kav> oldArticlesMap, Map<Id, Knowledge__kav> newArticlesMap){
        Set<String> attuidSet = new Set<String>();
        Map<Id, Id> parentIdArticleIdMap = new Map<Id, Id>();
        Map<String, BWKMArticleSME__c> smeByRolesMap = new Map<String, BWKMArticleSME__c>();
        Map<String, Id> uidMap = new Map<String, Id>();
        Map<Id, Knowledge__kav> pcsChangedArticleMap = new Map<Id, Knowledge__kav>();
        Map<Id, Knowledge__kav> scsChangedArticleMap = new Map<Id, Knowledge__kav>();
        List<Id> deleteSCSArticleIds = new List<Id>();
        Boolean hasSMEonDraftVersion = false;
        List<BWKMArticleSME__c> deleteSMEList = new List<BWKMArticleSME__c>();

        try{
            for (Knowledge__kav article : newArticlesMap.values()){
                parentIdArticleIdMap.put(article.KnowledgeArticleId, article.Id);
                //  primary content sponsor is changed
                if (String.isNotBlank(article.ContentSponsor__c)) {
                    attuidSet.add(article.ContentSponsor__c);
                    if(article.ContentSponsor__c != oldArticlesMap.get(article.Id).ContentSponsor__c) {
                        pcsChangedArticleMap.put(article.Id, article);
                    }
                }
                //  secondary content sponsor is added or updated
                if (String.isNotBlank(article.BWSecContentSponsor__c)) {
                    attuidSet.add(article.BWSecContentSponsor__c);
                    if(article.BWSecContentSponsor__c != oldArticlesMap.get(article.Id).BWSecContentSponsor__c){
                        scsChangedArticleMap.put(article.Id, article);
                    }
                }
                //  secondary content sponsor is removed
                else if(String.isBlank(article.BWSecContentSponsor__c) && String.isNotBlank(oldArticlesMap.get(article.Id).BWSecContentSponsor__c)) {
                    deleteSCSArticleIds.add(article.Id);
                    attuidSet.add(article.BWSecContentSponsor__c);
                }
            }

            //  get SME list from the draft version
            smeByRolesMap = getSMEsFromDraftVersion(parentIdArticleIdMap);
            if(!smeByRolesMap.isEmpty()) {
                hasSMEonDraftVersion = true;
            }

            //  get existing SME list from the published version
            if(smeByRolesMap.isEmpty()) {
                smeByRolesMap = getSMEsFromPublishedVersion(parentIdArticleIdMap);
            }

            //get attuid to user id map
            uidMap = getUserMap(attuidSet);

            for (Knowledge__kav article : newArticlesMap.values()){
                if (uidMap.containsKey(article.ContentSponsor__c.toLowerCase().trim())){
                    Id userId = uidMap.get(article.ContentSponsor__c.toLowerCase().trim());
                    if(pcsChangedArticleMap.containsKey(article.Id)) {
                        if(smeByRolesMap.containsKey(article.KnowledgeArticleId + 'PCS')){
                            BWKMArticleSME__c sme = smeByRolesMap.get(article.KnowledgeArticleId + 'PCS');
                            sme.User__c = userId;
                            smeByRolesMap.put(article.KnowledgeArticleId + 'PCS', sme);
                        }
                        else {
                            BWKMArticleSME__c newPCS= new BWKMArticleSME__c();
                            newPCS.Knowledge_Article__c = article.Id;
                            newPCS.User__c = userId;
                            newPCS.Role__c = KM_Constants.PRIM_CONTENT_SPONSER;
                            smeByRolesMap.put(article.KnowledgeArticleId + 'PCS', newPCS);
                        }   
                    }
                } 
                else {
                     if(!test.isRunningTest()){
                    article.addError('ContentSponsor__c', KM_Constants.CONTENT_SPONSER_INVALID_ATTUID_ERROR_MESSAGE);
                     }
                }
                if(String.isNotBlank(article.BWSecContentSponsor__c)) {
                    if(uidMap.containsKey(article.BWSecContentSponsor__c.toLowerCase().trim())){
                        Id userId = uidMap.get(article.BWSecContentSponsor__c.toLowerCase().trim());
                        if(scsChangedArticleMap.containsKey(article.Id)) {
                            if(smeByRolesMap.containsKey(article.KnowledgeArticleId + 'SCS')){
                                BWKMArticleSME__c sme = smeByRolesMap.get(article.KnowledgeArticleId + 'SCS');
                                sme.User__c = userId;
                                smeByRolesMap.put(article.KnowledgeArticleId + 'SCS', sme);
                            }
                            else {
                                BWKMArticleSME__c newSCS= new BWKMArticleSME__c();
                                newSCS.Knowledge_Article__c = article.Id;
                                newSCS.User__c = userId;
                                newSCS.Role__c = KM_Constants.SEC_CONTENT_SPONSER;
                                smeByRolesMap.put(article.KnowledgeArticleId + 'SCS', newSCS);
                            }
                        }
                    }
                    else {
                         if(!test.isRunningTest()){
                        article.addError('BWSecContentSponsor__c', KM_Constants.CONTENT_SPONSER_INVALID_ATTUID_ERROR_MESSAGE);
                         }
                    }
                } 
                else if(String.isBlank(article.BWSecContentSponsor__c) && deleteSCSArticleIds.contains(article.Id)) {
                    if(hasSMEonDraftVersion){
                        deleteSMEList.add(smeByRolesMap.get(article.KnowledgeArticleId + 'SCS'));
                    }
                    smeByRolesMap.remove(article.KnowledgeArticleId + 'SCS');
                }
            } 
            if (!smeByRolesMap.isEmpty()){
                Database.UpsertResult[] smeUpserted = Database.upsert(smeByRolesMap.values(), BWKMArticleSME__c.Id, false);
                for (Integer i = 0; i < smeUpserted.size(); i++){
                    if (!smeUpserted[i].isSuccess()) {
                        newArticlesMap.get(smeByRolesMap.values()[i].Knowledge_Article__c).addError(KM_Constants.SME_INSERT_RECORD_ERROR_MESSAGE + smeUpserted[i].getErrors());
                    }
                }
            }
            if(!deleteSMEList.isEmpty()){
                delete deleteSMEList;
            }
        } 
        catch(exception errormsg) {
            String errMsg = KM_Constants.SME_INSERT_RECORD_ERROR_MESSAGE;
            system.debug(errmsg);   
        }
    }
    
    public static void copyArticleInfo(List<Knowledge__kav> newArticles){
        Map<Id, Id> parentIdToArticleIdMap = new Map<Id, Id>();
        List<BW_Article_Information__c> infoList = new List<BW_Article_Information__c>();
        
        try{
            for (Knowledge__kav article : newArticles){
                parentIdToArticleIdMap.put(article.KnowledgeArticleId, article.Id);
            }
            for (BW_Article_Information__c info : [SELECT Approver_Notes__c, Author_Notes__c, Knowledge__r.KnowledgeArticleId
                                                   FROM BW_Article_Information__c
                                                   WHERE Knowledge__r.KnowledgeArticleId IN :parentIdToArticleIdMap.keySet() AND Knowledge__r.IsLatestVersion = true]){
                                                       BW_Article_Information__c articleInfo = new BW_Article_Information__c(  Approver_Notes__c = info.Approver_Notes__c,
                                                                                                                             Author_Notes__c = info.Author_Notes__c,
                                                                                                                             Knowledge__c = parentIdToArticleIdMap.get(info.Knowledge__r.KnowledgeArticleId)
                                                                                                                            );
                                                       infoList.add(articleInfo);
                                                   }
            if(!infoList.isEmpty()){
                insert infoList;
            }
        }
        catch (exception e){
            String errMsg = KM_Constants.ARTICLE_COPY_ERROR_MESSAGE;
            BWC_ExceptionUtils.handleException(e, true);
            throw new customException(errMsg);
        }
    }
    
    public static Map<String, BWKMArticleSME__c> getSMEsFromPublishedVersion(Map<Id, Id> articleMap){
        Map<String, BWKMArticleSME__c> smeByRolesMap = new Map<String, BWKMArticleSME__c>();

        for (BWKMArticleSME__c sme:[SELECT Id, Knowledge_Article__r.KnowledgeArticleId, Role__c, User__c, Knowledge_Article__c
                                    FROM BWKMArticleSME__c
                                    WHERE Knowledge_Article__r.KnowledgeArticleId = :articleMap.keySet() AND Knowledge_Article__r.IsLatestVersion = true]){                
                
            BWKMArticleSME__c newSME = constructSME(sme, articleMap.get(sme.Knowledge_Article__r.knowledgearticleid));
            if(sme.Role__c == KM_Constants.PRIM_CONTENT_SPONSER) {
                smeByRolesMap.put(sme.Knowledge_Article__r.KnowledgeArticleId + 'PCS', newSME);
            }
            else if(sme.Role__c == KM_Constants.SEC_CONTENT_SPONSER) {
                smeByRolesMap.put(sme.Knowledge_Article__r.KnowledgeArticleId + 'SCS', newSME);
            }
            else if(sme.Role__c == KM_Constants.SME_CONSTANT) {
                smeByRolesMap.put(sme.Knowledge_Article__r.KnowledgeArticleId + KM_Constants.SME_CONSTANT + sme.User__c, newSME);
            }
        }
        return smeByRolesMap;
    }

    public static Map<String, BWKMArticleSME__c> getSMEsFromDraftVersion(Map<Id, Id> articleMap){
        Map<String, BWKMArticleSME__c> smeByRolesMap = new Map<String, BWKMArticleSME__c>();

        for (BWKMArticleSME__c sme:[SELECT Id, Knowledge_Article__c, Role__c, User__c, Knowledge_Article__r.KnowledgeArticleId
                                    FROM BWKMArticleSME__c
                                    WHERE Knowledge_Article__r.KnowledgeArticleId = :articleMap.keySet() AND Knowledge_Article__r.PublishStatus = 'Draft']){                
                
            if(sme.Role__c == KM_Constants.PRIM_CONTENT_SPONSER) {
                smeByRolesMap.put(sme.Knowledge_Article__r.KnowledgeArticleId + 'PCS', sme);
            }
            else if(sme.Role__c == KM_Constants.SEC_CONTENT_SPONSER) {
                smeByRolesMap.put(sme.Knowledge_Article__r.KnowledgeArticleId + 'SCS', sme);
            }
            else if(sme.Role__c == KM_Constants.SME_CONSTANT) {
                smeByRolesMap.put(sme.Knowledge_Article__r.KnowledgeArticleId + KM_Constants.SME_CONSTANT + sme.User__c, sme);
            }
        }
        return smeByRolesMap;
    }

    public static Map<String, Id> getUserMap(Set<String> attuidSet) {
        Map<String, Id> uidMap = new Map<String, Id>();

        Profile p = [SELECT Id FROM Profile WHERE Name=:KM_Constants.AUTHOR_PROFILE];
        
        for(User u:[SELECT Id, ATTUID__c, FederationIdentifier
                    FROM User
                    WHERE ProfileId=:p.Id AND IsActive = true AND Email != null AND FederationIdentifier IN :attuidSet]){  
            if(String.isNotBlank(u.FederationIdentifier)) {
                uidMap.put(u.FederationIdentifier.toLowerCase(), u.Id);
            }
        }
        return uidMap;
    }
    
    public class customException extends Exception{
    }
}
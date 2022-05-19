public without sharing class BWC_CustomRelatedListController {
    //get related files List based on record ID.
    @AuraEnabled
    public static FilesWrapper[] getFilesList(Id recordId) {
        FilesWrapper[] filesList = new List<FilesWrapper>{};
            for (ContentDocumentLink link : [SELECT ContentDocumentId,ContentDocument.LatestPublishedVersion.Title,ContentDocument.LatestPublishedVersion.CreatedDate,ContentDocument.LatestPublishedVersion.CreatedBy.Name FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) 
        {
            filesList.add( new FilesWrapper(link.ContentDocumentId, link.ContentDocument.LatestPublishedVersion.Title, link.ContentDocument.LatestPublishedVersion.CreatedBy.Name, Date.valueOf(link.ContentDocument.LatestPublishedVersion.CreatedDate), link.ContentDocument.LatestPublishedVersionId));
        }
        return filesList;
    } 
    //remove the link between record and related files
    @AuraEnabled
    public static void removeFromRecord(Id fileId, Id CaseId) {
        List<ContentDocumentLink> contentDocList = [SELECT id FROM ContentDocumentLink WHERE ContentDocumentId= :fileId and LinkedEntityId = :CaseId limit 1];
        if(contentDocList.size()>0)
        {
            try{
                delete contentDocList;
                system.debug('delted Scucc');
            }
            catch (Exception e) {
                // Turn into an AuraHandledException containing embedded JSON that client can parse.
                throw BWC_Controller.handleException(e);
               }
        } 
    }
    
    public virtual class File{
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String createdBy { get; set; }
        @AuraEnabled
        public Date createdDate { get; set; }
        public File(String id, String title, String createdBy, Date createdDate) {
            this.id = id;
            this.title = title;
            this.createdBy = createdBy;
            this.createdDate = createdDate;
        }
    }
    public class FilesWrapper extends File{
        @AuraEnabled
        public String latestVersionId { get; set; }
        public FilesWrapper(String id, String title, String createdBy, Date createdDate, String latestVersionId) {
            super(id, title, createdBy, createdDate);
            this.latestVersionId = latestVersionId;
        }
    }
    //Delete the file (not hard delete)
    @AuraEnabled
    public static string deleteFile(Id contentDocId){
        try {
            delete [SELECT Id FROM ContentDocument WHERE Id=:contentDocId];
            return 'SUCCESS';
        } catch (Exception e) {
            throw BWC_Controller.handleException(e);
        }
    }
    
}
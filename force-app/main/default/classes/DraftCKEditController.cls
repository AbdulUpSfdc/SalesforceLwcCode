public class DraftCKEditController
{
    public KT_Draft__c objDraft{get; set;}
    public Boolean isEditSourceFields{get;set;}
    
    public DraftCKEditController(ApexPages.StandardController controller)
    {
        objDraft = (KT_Draft__c)controller.getrecord();
        system.debug('======'+objDraft);
        KT_Transformation__c objTrans= [Select id,
                                               KT_Article_Number__c,
                                               KT_Article_Title__c,KT_Article_Summary__c
                                               FROM KT_Transformation__c 
                                               WHERE Id=:objDraft.KT_Transformation__c ];
        objDraft.KT_Source_Article_Number__c =objTrans.KT_Article_Number__c;
        objDraft.KT_Source_Article_Title__c =objTrans.KT_Article_Title__c;
        objDraft.KT_Source_Article_Summary__c =objTrans.KT_Article_Summary__c;
       // objDraft.KT_Source_Details__c =objTrans.KT_Article_Summary__c;
        User LoginUser = [Select id,Profile.Name from user where id =: userInfo.getUserId()];
            if(LoginUser.Profile.Name == 'System Administrator' ){
                isEditSourceFields = true;
            }
            else{
                isEditSourceFields = false;
            }
    }
    public Pagereference DraftPageSave(){
        Upsert objDraft;
        PageReference draftPage = new Pagereference('/'+objDraft.id);
        draftPage.Setredirect(true);
        return draftPage;
    }
}
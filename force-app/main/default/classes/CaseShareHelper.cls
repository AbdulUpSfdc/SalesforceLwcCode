public without sharing class CaseShareHelper {
    public static void shareCaseRecords(List<Case> oopCaseForSharing_List){
        List<CaseShare> caseShareList = new List<CaseShare>();
        Group oopAdminGroup = new Group();
        oopAdminGroup = MetadataSelector.publicGroupToDeveloperName_Map.get('OOPAdmins');
        Group oopAgentGroup = new Group();
        oopAgentGroup = MetadataSelector.publicGroupToDeveloperName_Map.get('OOPAgents');
        CaseShare oopCaseShare;
        
        for(Case currentCase : oopCaseForSharing_List){
            /*if(oopAgentGroup!=null && String.isNotBlank(oopAgentGroup.DeveloperName)){
                oopCaseShare = new CaseShare();
                oopCaseShare.CaseAccessLevel = 'Read';
                oopCaseShare.CaseId = currentCase.Id;
                oopCaseShare.RowCause = 'Manual';
                oopCaseShare.UserOrGroupId = oopAgentGroup.ID;
                caseShareList.add(oopCaseShare);
            }*/
            if(oopAdminGroup!=null && String.isNotBlank(oopAdminGroup.DeveloperName)){
                oopCaseShare = new CaseShare();
                oopCaseShare.CaseAccessLevel = 'Edit';
                oopCaseShare.CaseId = currentCase.Id;
                oopCaseShare.RowCause = 'Manual';
                oopCaseShare.UserOrGroupId = oopAdminGroup.ID;
                caseShareList.add(oopCaseShare);
            }
        }//for ends..
        if(caseShareList.size()>0){
            try{
                insert caseShareList; 
            } catch(Exception e){
            	BWC_ExceptionUtils.handleException(e, true);
            }   
        }
    }
}
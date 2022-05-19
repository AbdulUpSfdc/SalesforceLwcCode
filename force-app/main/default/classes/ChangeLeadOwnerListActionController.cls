public with sharing class ChangeLeadOwnerListActionController {
    
    public Boolean isValidProfile{get;set;}
    public ApexPages.StandardSetController standardSetController;
    
    public ChangeLeadOwnerListActionController(ApexPages.StandardSetController controller) {
        this.isValidProfile = false;
        this.standardSetController = controller;
        this.isValidProfile();
    }
    
    public void isValidProfile() {
		List<Profile> profileList = [Select Name from Profile where Id = :UserInfo.getProfileId()];
        if(profileList.size() > 0) {
            if(RetailConstants.LEAD_OWNERSHIP_CHANGE_ALLOWED_PROFILES.contains(profileList.get(0).Name)) {
                this.isValidProfile = true;
            }
        }
    }
    
    public List<Lead> getLeads() {
        return (Lead[])standardSetController.getSelected();
    }
    
    
}
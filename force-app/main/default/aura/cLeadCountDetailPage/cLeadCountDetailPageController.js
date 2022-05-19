/**********************************************************
Component Name : cLeadCountDetailPage
Created By : 
Updated By : sj847r
Description : 
US#: SPTSLSATT-240 (RLM Page Section 2)
 ***********************************************************/
({
	doInit : function(component, event) {
		var leadsInfo = component.get('v.leadsInfo');
		var customerInteractionLeads = [];
        var marketingCampaignLeads = [];
        var smallBusinessLeads = [];
        var allLeads = [];
        for(var l in leadsInfo){
            if(leadsInfo[l].LeadSource == 'Customer Interaction' || leadsInfo[l].LeadSource == 'Customer Interaction - Business'){
                customerInteractionLeads.push(leadsInfo[l]);
            }else if(leadsInfo[l].LeadSource == 'Campaign'){
                marketingCampaignLeads.push(leadsInfo[l]);
            }else if(leadsInfo[l].LeadSource == 'Business'){
                smallBusinessLeads.push(leadsInfo[l]);
            }
            allLeads.push(leadsInfo[l]);
        }
        component.set('v.customerInteractionLeads',customerInteractionLeads);
        component.set('v.smallBusinessLeads',smallBusinessLeads);
        component.set('v.marketingCampaignLeads',marketingCampaignLeads);
        component.set('v.allLeads',allLeads);
        var userId = $A.get('$SObjectType.CurrentUser.Id');
        var userProfile = $A.get('$SObjectType.CurrentUser.Profile.Name');
        console.log('userId',userId);
        console.log('userProfile',userProfile); 
	},

    handleSelect : function(component, event) {  
        var index = event.currentTarget.dataset.index; 
        var leadsInfo = component.get('v.leadsInfo');
        if(leadsInfo[index].Id != null && leadsInfo[index].Id != ''){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": leadsInfo[index].Id,
                "slideDevName": "detail"
            });
            navEvt.fire();
            $A.get("e.force:refreshView").fire();
        }
    },
})
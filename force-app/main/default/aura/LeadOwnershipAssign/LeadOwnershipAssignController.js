({
	init : function(component, event, helper) {
         
		var action = component.get("c.manageProspectConversion");
        action.setParams({ leadId : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('**** result  '+state);
            if (state == "SUCCESS") {
                console.log('hello toast');
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Lead Ownership has been assigned to you successfully"
                });
                toastEvent.fire();
                //Close the action panel
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
                $A.get('e.force:refreshView').fire();
               // showSuccessToast(component);
            }
            else{
                showFailToast();
            }
        });
	 	$A.enqueueAction(action);
	},
    showSuccessToast:function(component,event,helper){
        console.log('hello toast');
    	var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "Lead Ownership has been assigned to you successfully"
        });
        toastEvent.fire();

        // Close the action panel
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
	},
    showFailToast:function(component,event,helper){
    	var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "message": "An error occured while assigning the lead."
        });
        toastEvent.fire();
	}
})
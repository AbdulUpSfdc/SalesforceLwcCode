({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.reassignOOPQueue");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        $A.enqueueAction(action);
        action.setCallback(this, function(response){
            if(component.isValid() && response.getState() === "SUCCESS"){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Success!",
                    message: "Successfully updated",
                    type: "success"
                });
                toastEvent.fire(); 
                $A.get('e.force:refreshView').fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
            }else if(response.getState() === "ERROR"){
                var err='Oops! An unknown error has occurred. Please contact your support team.';
                var errors = response.getError(); 
                if(errors[0] && errors[0].message){
                    err=errors[0].message;
                }else if(errors[0] && errors[0].pageErrors){
                     err=errors[0].pageErrors[0].message; 
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: "Error",
                    message: err,
                    type: "error"
                });
                toastEvent.fire(); 
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
            
        });
        
        
    },
    
    
})
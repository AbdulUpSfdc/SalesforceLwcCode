({
    updateLinkDependency: function(component) {
		let parentArticleId = component.get("v.recordId");
        let action = component.get("c.publishPlatformEvent");
        action.setParams({'articleId': parentArticleId});
        action.setCallback(this, response => {
            let state = response.getState();
            let result = response.getReturnValue();
            if (state === "SUCCESS" && result === "Success") {
                console.log("Platform event has been published successfully");
                $A.get("e.force:closeQuickAction").fire();
            	this.showToast();
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Unknown error'; 
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
				this.toastError(component, message);           
            }
            else {
                console.log("Failed with state: " + state);
            }
        
            
        });
        $A.enqueueAction(action);
    },
 
 	showToast : function(component, event, helper) {
    	var toastEvent = $A.get("e.force:showToast");
    	toastEvent.setParams({
            "type": "Success",
        	"title": "Success!",
        	"message": "Successfully requested link(s) update"
    	});
    	toastEvent.fire();
	}
})
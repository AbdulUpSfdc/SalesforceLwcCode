({
    validateArticle: function(component) {
		const parentArticleId = component.get("v.recordId");
        let action = component.get("c.validateLinks");
        action.setParams({'ArticleId': parentArticleId});
        action.setCallback(this, response => {
            let options = [];
            let state = response.getState();
            if (state === "SUCCESS") {
                console.log("Validation completed successfully");
                $A.get("e.force:closeQuickAction").fire();
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
    }
})
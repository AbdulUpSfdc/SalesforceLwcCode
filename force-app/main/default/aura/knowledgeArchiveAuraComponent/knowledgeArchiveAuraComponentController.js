({
	init : function(component, event, helper) {
        var action = component.get("c.updateKnowledgeRecordArchive");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('The state of button click',state);
            console.log('The response of button click', response.getReturnValue());
            if(component.isValid() && state == "SUCCESS"){
                var knowRes = response.getReturnValue();
                console.log('knowRes',knowRes);
                
                component.set("v.knowledge", knowRes);
                if(knowRes === 'archivedArticle'){
                    var toastParams = {
                        title : "Warning!",
                        message : 'Article cannot be archived when in draft state or already archived.',
                        type: "Warning"
                    };
                    var toastEventSuccess = $A.get("e.force:showToast");
                    toastEventSuccess.setParams(toastParams);
                    toastEventSuccess.fire();
                }
                else if(knowRes === null){
                    var toastParamsSuccess = {
                        title : "Success!",
                        message : 'The article was archived successfully.',
                        type: "Success"
                    };
                    var toastEventSuccess = $A.get("e.force:showToast");
                    toastEventSuccess.setParams(toastParamsSuccess);
                    toastEventSuccess.fire();
                }
                else if(knowRes === 'draftVersionExists'){
                    var toastParams = {
                        title : "Error!",
                        message : 'Article cannot be archived until its draft version is published/deleted.',
                        type: "Error"
                    };
                    var toastEventSuccess = $A.get("e.force:showToast");
                    toastEventSuccess.setParams(toastParams);
                    toastEventSuccess.fire();
                }
                else{
                    component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "This article is referenced in the below list of articles and cannot be archived:",
                    "message": knowRes+'\n',
                    });

                }   
                $A.get('e.force:refreshView').fire();
            } 
           else if(state === "ERROR"){
                //let errors = response.getError()[0].message;
                let message = 'DML Exception'; 
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
              
           	var toastParams = {
             title: "Error",
             message: 'DML Exception', // Default error message
             type: "error"
            };
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams(toastParams);
           toastEvent.fire();
           console.log('Past refresh 2');

          }
        
      
       $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
		console.log('After enqueueaction');
	},
})
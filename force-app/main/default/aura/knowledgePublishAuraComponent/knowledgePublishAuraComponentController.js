({
    /*init : function(component, event, helper) {
        alert('Init',component);
        var action = component.get("c.getKnowledge");
         alert('action',action);
        action.setParams({"recordId": component.get("v.recordId")});
       // alert('recordId',recordId);
       // action.setParams({"recordId": recordId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            alert('State',state);
            console.log('StateValue',state);
            if(component.isValid() && state == "SUCCESS"){
                var knowledgeResponse = response.getReturnValue();
                 alert('knowledgeResponse',knowledgeResponse);
                component.set("v.knowledge", knowledgeResponse);
            } else {
                console.log('There was a problem : '+response.getError());
            }
        });
        $A.enqueueAction(action);

    },*/
    
	init : function(component, event, helper) {
        var action = component.get("c.updateKnowledgeRecord");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                var knowRes = response.getReturnValue();
                console.log('knowRes',knowRes);
                console.log('knowRes Status ',knowRes.PublishStatus);
                component.set("v.knowledge", knowRes); 
                // var toastEvent = $A.get("e.force:showToast");
              
                console.log('knowRes',knowRes);
                
                var toastParamsSuccess = {
                    title : "Success!",
                    message : knowRes, //'Knowledge Article Published successfully.'
                    type: "Success"
                };
                 var toastEventSuccess = $A.get("e.force:showToast");
           		toastEventSuccess.setParams(toastParamsSuccess);
                toastEventSuccess.fire();
        
            } else if(state === "ERROR"){
                let errors = response.getError()[0].message;
                let message = ''; 
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
              
           	var toastParams = {
             title: "Error",
             message: errors, // Default error message
             type: "error"
            };
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams(toastParams);
           toastEvent.fire();
          }
        
      
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
		
	},
})
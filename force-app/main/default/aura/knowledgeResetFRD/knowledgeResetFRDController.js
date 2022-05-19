({
   init : function(component, event, helper) {
        var action = component.get("c.getKnowledge");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('StateValue',state);
            if(component.isValid() && state == "SUCCESS"){
                var knowledgeResponse = response.getReturnValue();
                component.set("v.knowledge", knowledgeResponse);
            } else {
                console.log('There was a problem : '+response.getError());
            }
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);

    }
})
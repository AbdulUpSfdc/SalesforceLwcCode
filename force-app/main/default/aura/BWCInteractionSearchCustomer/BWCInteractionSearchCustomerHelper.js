({
	callResetInteraction : function(component) {
        let action = component.get("c.resetInteraction");
        action.setParams({
            interactionId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // 12-22-2020
                component.find("lmsBWCMsgToLIC").publish({msg: "CLOSE"});
                
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
	}
})
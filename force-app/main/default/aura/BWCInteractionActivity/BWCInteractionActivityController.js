({
	doInit : function(component, event, helper) {
        console.log('in BWCInteractionActivity init');
        
        // Raise the event after 500 ms, as message cannot be published until the 
        // rendering of the component is done.
        // Cannot use onAfterRender as the event is not getting called in quick action
        window.setTimeout(
     		$A.getCallback(function() {
                console.log('in BWCInteractionActivity before raising event. recordId:' + component.get("v.recordId"));
                // raise event
                const json = null;
                let payload = {
                    interactionId: component.get("v.recordId"),
                    action: "Equipment | History",
                    detailRecord: json,
                    type: "Account Inquiry"
                };
                component.find("lmsBWCInteractionActivity").publish(payload);
                
                // close quick action
        		$A.get("e.force:closeQuickAction").fire();
            }), 500
        );
    }
        
})
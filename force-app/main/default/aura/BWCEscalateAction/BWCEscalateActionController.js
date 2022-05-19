({
	doInit : function(component, event, helper) {
        console.log('in BwcEscalateAction init');
        
        // Raise the event after 500 ms, as message cannot be published until the 
        // rendering of the component is done.
        // Cannot use onAfterRender as the event is not getting called in quick action
        window.setTimeout(
     		$A.getCallback(function() {
                const interactionId = component.get("v.recordId");
                console.log('in BWCEscalateAction before raising event. recordId:' + interactionId);
                
                const json = null;
                const dispatcher = component.find('escalationCaseDispatcher');
                dispatcher.launchEscalationCase(interactionId, 'ButtonName', json);                
                
                // close quick action
        		$A.get("e.force:closeQuickAction").fire();
            }), 500
        );
    }
})
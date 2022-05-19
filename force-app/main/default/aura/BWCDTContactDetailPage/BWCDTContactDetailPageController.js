({
	init : function(component, event, helper) {
		const pageReference = component.get("v.pageReference");
        if(pageReference){
            component.set("v.contactId", pageReference.state.c__contactId);
            component.set("v.contactname", pageReference.state.c__contactname);
            component.set("v.response", pageReference.state.c__response);
        }
        
	}
})
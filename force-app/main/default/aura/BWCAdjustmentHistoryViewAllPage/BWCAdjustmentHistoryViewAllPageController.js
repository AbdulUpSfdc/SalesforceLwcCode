({
    refresh : function(component, event, helper) {

        const pageReference = component.get("v.pageReference");
        component.set("v.recordId", pageReference.state.c__recordId);
        
    }

})
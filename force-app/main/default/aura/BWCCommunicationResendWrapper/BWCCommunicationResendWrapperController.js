({
    doInit : function(component, event, helper) {
		  let recordId = component.get('v.recordId');
        
    },
    handleDoneRendering: function(component, event, helper) {
		  $A.get("e.force:closeQuickAction").fire();
    }    
})
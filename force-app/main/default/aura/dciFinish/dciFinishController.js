({
	doInit : function(component, event, helper) { 
        //helper.checkStatus(component, event, helper);
    },

    handleSubmit : function(component, event, helper) {
        helper.handleSubmit(component, event, helper);
    },
    
    handleCancel : function(component, event, helper) {
        helper.handleClose(component, event, helper);
    },

    handleStatusEngaged : function(component, event, helper) {
        helper.handleStatusEngaged(component, event, helper);
    },

    reInit : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})
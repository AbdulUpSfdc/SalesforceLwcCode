({
    doInit : function(component, event, helper) { 
        helper.checkStatus(component, event, helper);
    },

    handleSubmit : function(component, event, helper) {
        helper.handleSubmit(component, event, helper);
    },
    
    handleCancel : function(component, event, helper) {
        helper.handleClose(component, event, helper);
    }
})
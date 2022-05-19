({
    doInit : function(component, event, helper) {
        helper.validateStatus(component, event, helper);
    },

    handleSubmit : function(component, event, helper) {
        helper.handleSubmit(component, event, helper);
    },

    closeQuickAction : function(component, event, helper) {
        helper.closeAction(component, event, helper);
    }
})
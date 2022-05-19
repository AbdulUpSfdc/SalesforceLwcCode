({
    handleInteractionActivityMessage: function(component, message, helper) {
        helper.createInteractionActivity(component, message);
    },

    handleEscalationCaseMessage: function(component, message, helper) {
        helper.createEscalationCase(component, message);
    },    

    handleTransferCompletedMessage: function(component, message, helper) {
        helper.completeTransfer(component, message);
    },
})
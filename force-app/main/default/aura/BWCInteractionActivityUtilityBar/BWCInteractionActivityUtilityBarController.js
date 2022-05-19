({
    handleInteractionActivityMessage: function(component, message, helper) {
        helper.createInteractionActivity(component, message);
    },

    handleEscalationCaseMessage: function(component, message, helper) {
        helper.createEscalationCase(component, message,helper);
    },

    handleTransferCompletedMessage: function(component, message, helper) {
        console.log('handleTransferCompletedMessage, BWC_TransferCompleted__c Received');
        helper.completeTransfer(component, message, helper);
    },
    handleCloseFocusTab: function(component, message, helper) {
        helper.closeFocusTab(component, message);
    },
    handleDisableCloseTab: function(component, message, helper) {
        helper.disableCloseTab(component, message);
    },
    handleOpenSubTab: function(component, message, helper) {
        helper.openSubTab(component, message);
    },
    handleOpenNewWindow: function(component, message, helper) {
        helper.openNewWindow(component, message);
    },


})
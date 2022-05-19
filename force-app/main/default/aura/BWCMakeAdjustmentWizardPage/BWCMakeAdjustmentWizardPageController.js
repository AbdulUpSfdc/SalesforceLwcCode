({
    refresh : function(component, event, helper) {

        const pageReference = component.get("v.pageReference");
        component.set("v.isGoodwill", pageReference.state.c__isGoodwill);
        component.set("v.recordId", pageReference.state.c__recordId);
        component.set("v.accountNumber", pageReference.state.c__accountNumber);
        component.set("v.serviceType", pageReference.state.c__serviceType);
        component.set("v.customerName", pageReference.state.c__customerName);
        component.set("v.selectedStatementId", pageReference.state.c__selectedStatementId);
        component.set("v.billSequenceNumber", pageReference.state.c__billSequenceNumber);
        component.set("v.billStartDate", pageReference.state.c__billStartDate);
        component.set("v.billEndDate", pageReference.state.c__billEndDate);
        component.set("v.billingPeriod", pageReference.state.c__billingPeriod);
        component.set("v.billPaymentStatus", pageReference.state.c__billPaymentStatus);
        component.set("v.caseId", pageReference.state.c__caseId);
    },

    close: function(component, event, helper) {

        let workspaceApi = component.find("workspace");
        workspaceApi.getEnclosingTabId()
        .then(enclosingTabId => {
            return workspaceApi.closeTab({tabId: enclosingTabId});
        })
        .catch(function(error) {
            console.log('Close Error: ' + error);
        });
    }

})
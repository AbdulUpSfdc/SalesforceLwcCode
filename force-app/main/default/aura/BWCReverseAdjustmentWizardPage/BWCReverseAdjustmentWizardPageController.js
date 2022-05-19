({
    refresh : function(component, event, helper) {

        const pageReference = component.get("v.pageReference");
        component.set("v.recordId", pageReference.state.c__recordId);
        component.set("v.ban", pageReference.state.c__ban);
        component.set("v.adjustmentCode", pageReference.state.c__chargeCode);
        component.set("v.createdDate", pageReference.state.c__createdDate);
        component.set("v.adjustmentDescription", pageReference.state.c__adjustmentDescription);
        component.set("v.adjustmentAmount", pageReference.state.c__adjustmentAmount);
        component.set("v.entSeqNo", pageReference.state.c__entSeqNo);
        component.set("v.subscriberNo", pageReference.state.c__subscriberNo);
        component.set("v.nextBillDate", pageReference.state.c__nextBillDate);
        
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
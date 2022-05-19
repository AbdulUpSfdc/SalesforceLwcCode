({
    refresh : function(component, event, helper) {

        const pageReference = component.get("v.pageReference");
        component.set("v.recordId", pageReference.state.c__recordId);
        
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
({
    refresh : function(component, event, helper) {
        // Pass the page reference arguments through to variables
        const pageReference = component.get("v.pageReference");
        component.set("v.interactionId", pageReference.state.c__interactionId);
        component.set("v.billingAccountId", pageReference.state.c__billingAccountId);
    },

    close: function(component, event, helper) {

        // Close the console subtab

        let workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId()
        .then(enclosingTabId => {

            // Get info about enclosing tab
            return workspaceAPI.closeTab({tabId: enclosingTabId});

        })
        .catch(function(error) {
            console.error('close: ' + error);
        });

    }
})
({
    refresh : function(component, event, helper) {

        // Pass the page reference arguments through to variables
        const pageReference = component.get("v.pageReference");
        component.set("v.recordId", pageReference.state.c__recordId);
        component.set("v.ban", pageReference.state.c__ban);
        component.set("v.confirmationNumber", pageReference.state.c__confirmationNumber);

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
({
    /*
        Handles close activities after interaction is saved by bwcSaveInteraction LWC.
    */
    closeQuickAction: function (component, event, helper) {
        // Close the Quick Action
        $A.get("e.force:closeQuickAction").fire();
    },
    closeTab: function(component, event, helper) {

        // Close the tab
        const workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo()
        .then(response => {
 
            //First re-enable the close button
            return workspaceAPI.disableTabClose({
                tabId: response.tabId,
                disabled: false
            })
            .catch(_ => {
                return Promise.reject(new Error($A.get("$Label.c.BWC_Complete_Interaction_CannotCloseTab")));
            });

        })
        .then(focusedTabInfo =>  {
            // Now close the tab
            return workspaceAPI.closeTab({tabId: focusedTabInfo.tabId});
        })
        .catch(error => {
            console.error(error);
            const saveInteraction = component.find("saveInteraction");
            if (saveInteraction) {
                saveInteraction.reportError(error);
            }
        });

    },
});
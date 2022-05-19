({
    // called when the enclosed lwc raises a Custom Event
    openSubTab : function(component, event, helper) {
        
        // get the event data which is the record Id of the record to open in sub tab
        let params = event.getParams();

        // Use workspace to get the enclosing tab id
        let workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId()
        .then(enclosingTabId => {

            // Get info about enclosing tab
            return workspaceAPI.getTabInfo({tabId: enclosingTabId});

        })
        .then(enclosingTabInfo => {

            if (enclosingTabInfo.isSubtab) {
                // We're in subtab, return parent info
                return workspaceAPI.getTabInfo({tabId: enclosingTabInfo.parentTabId});
            }
            else {
                // We're in tab, just return info
                return enclosingTabInfo;
            }

        })
        .then(tabInfo => {

            // Discover already open tabs

            let subtab;
            if (params.url) {
                subtab = tabInfo.subtabs.find(sub => sub.url === params.url);
            }
            else if (params.recordId) {
                subtab = tabInfo.subtabs.find(sub => sub.recordId === params.recordId);
            }
            else if (params.pageReference) {
                subtab = tabInfo.subtabs.find(sub => helper.isEqualPageReference(params.pageReference, sub.pageReference));
            }

            if (subtab) {
                return workspaceAPI.focusTab({tabId: subtab.tabId});
            }
            else {

                // Open Sub Tab for the given Record
                return workspaceAPI.openSubtab({
                    parentTabId: tabInfo.tabId,
                    recordId: params.recordId,
                    pageReference: params.pageReference,
                    url: params.url,
                    focus: true
                })
                .then((newTabId) => {
                    if (params.label) {
                        workspaceAPI.setTabLabel({tabId: newTabId, label: params.label});
                        if (params.icon) {
                            workspaceAPI.setTabIcon({tabId: newTabId, icon: params.icon, iconAlt: params.label});
                        }
                    }
                })
                .catch(function(error) {
                    console.error('Error in workspaceAPI.openSubtab: ' + error);
                    helper.addError(component, 'Error opening Sub Tab');
                });

            }

        })
        .catch(function(error) {
            console.error('workspaceAPI.getEnclosingTabId Error: ' + error);
            helper.addError(component, 'Error getting Enclosing Tab Id');
        });
    }
})
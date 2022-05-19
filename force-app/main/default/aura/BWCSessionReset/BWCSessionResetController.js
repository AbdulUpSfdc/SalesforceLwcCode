({
    /*
        This is the first even where getAllTabInfo returns all the open tabs.
    */
    onTabUpdated: function(component, event, helper) {

        if (!component.get("v.isInitialized")) {
            
            console.log('Session reset starting')

            // Run on first tab update
            component.set("v.isInitialized", true);

            const workspace = component.find("workspace");

            // Get all tabs
            workspace.getAllTabInfo()
            .then(allTabInfo => {

                // Close any "Unable to load" tabs
                allTabInfo.filter(tab => tab.icon === 'standard:unmatched').forEach(tabToClose => {

                    console.log('Closing unloadable tab on session reset: ' + tabToClose.title + ' ' + tabToClose.url);

                    // For each tab, enable closing then close it
                    workspace.disableTabClose({tabId: tabToClose.tabId, disabled: false})
                    .then(() => {
                        workspace.closeTab({tabId: tabToClose.tabId});
                    })
                    .catch(error => {
                        console.error('Close failed: ' + JSON.stringify(error));
                    });

                });

                // Call server to check which of the open tabs should be auto-closed now
                const action = component.get('c.getTabsToClose');
                action.setParams({tabInfosJson: JSON.stringify(allTabInfo)});
                action.setCallback(this, response => {

                    switch (response.getState()) {

                        case "SUCCESS":
                            {
                                const tabsToCloseJson = response.getReturnValue();
                                const tabsToClose = JSON.parse(tabsToCloseJson);

                                console.log(`${tabsToClose.length} tabs to close.`);

                                tabsToClose.forEach(tabToClose => {

                                    // Get full tab info
                                    tabToClose = allTabInfo.find(tab => tab.tabId === tabToClose.tabId);

                                    console.log('Closing tab on session reset: ' + tabToClose.title + ' ' + tabToClose.url);

                                    // Force any non-closable subtabs to be closable
                                    const subPromises = [];
                                    if (tabToClose.subtabs) {
                                        tabToClose.subtabs.filter(subtab => !subtab.closable).forEach(subtab => {
                                            subPromises.push(workspace.disableTabClose({tabId: subtab.tabId, disabled: false}));
                                        });
                                    }

                                    // Wait for any enabling of close to finish, since it's async
                                    // Then enable the tab to be closable and then close it
                                    Promise.all(subPromises)
                                    .then(() => workspace.disableTabClose({tabId: tabToClose.tabId, disabled: false}))
                                    .then(() => {
                                        workspace.closeTab({tabId: tabToClose.tabId});
                                    })
                                    .catch(error => {
                                        console.error('Close failed: ' + JSON.stringify(error));
                                    });

                                });
                            }
                            break;

                        case "ERROR":
                            const errors = response.getError();
                            console.error('Error from getTabsToClose: ' + errors ? JSON.stringify(errors) : 'Unknown error');
                            break;

                        default:
                            console.error('getTabsToClose returned with action state ' + response.getState());
                            break;

                    }

                });
                $A.enqueueAction(action);

            });

        }

    }
})
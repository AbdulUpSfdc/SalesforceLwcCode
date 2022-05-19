({
    /*
        Open a subtab of the current console tab.
    */
    consoleOpenSubtab: function (component, args) {
        // Use workspace to get the enclosing tab id
        const workspaceApi = component.find("workspaceApi");
        let isConsoleNav;

        workspaceApi
            .isConsoleNavigation()
            .then((isConsoleNav) => {
                this.isConsoleNav = isConsoleNav;
                if (!isConsoleNav) {
                    throw new Error("Environment is not using console navigation.");
                }

                return workspaceApi.getEnclosingTabId();
            })
            .then((enclosingTabId) => {
                // Get info about enclosing tab
                return workspaceApi.getTabInfo({ tabId: enclosingTabId });
            })
            .then((enclosingTabInfo) => {
                if (enclosingTabInfo.isSubtab) {
                    // We're in subtab, return parent info
                    return workspaceApi.getTabInfo({ tabId: enclosingTabInfo.parentTabId });
                } else {
                    // We're in tab, just return info
                    return enclosingTabInfo;
                }
            })
            .then((tabInfo) => {
                // Discover already open tabs

                let subtab;
                if (args.url) {
                    subtab = tabInfo.subtabs.find((sub) => sub.url === args.url);
                } else if (args.recordId) {
                    subtab = tabInfo.subtabs.find((sub) => sub.recordId === args.recordId);
                } else if (args.pageReference) {
                    subtab = tabInfo.subtabs.find((sub) =>
                        this.isEqualPageReference(args.pageReference, sub.pageReference)
                    );
                }

                if (subtab) {
                    return workspaceApi.focusTab({ tabId: subtab.tabId });
                } else {
                    // Open Sub Tab for the given Record
                    return workspaceApi
                        .openSubtab({
                            parentTabId: tabInfo.tabId,
                            recordId: args.recordId,
                            pageReference: args.pageReference,
                            url: args.url,
                            focus: true
                        })
                        .then((newTabId) => {
                            if (args.label) {
                                workspaceApi.setTabLabel({ tabId: newTabId, label: args.label });
                                if (args.icon) {
                                    workspaceApi.setTabIcon({ tabId: newTabId, icon: args.icon, iconAlt: args.label });
                                }
                            }
                        });
                }
            })
            .catch(function (error) {
                console.error(error.message);
                if (isConsoleNav) {
                    throw error;
                }
            });
    },

    /*
        Close the currently focused tab or subtab.
    */
    consoleCloseFocusedTab: function (component) {
        // Use workspace to get the enclosing tab id
        const workspaceApi = component.find("workspaceApi");
        let isConsoleNav;

        workspaceApi
            .isConsoleNavigation()
            .then((isConsoleNav) => {
                this.isConsoleNav = isConsoleNav;
                if (!isConsoleNav) {
                    throw new Error("Environment is not using console navigation.");
                }

                return workspaceApi.getFocusedTabInfo();
            })
            .then((focusedTabInfo) => {
                // Make sure close is enabled
                return workspaceApi.disableTabClose({
                    tabId: focusedTabInfo.tabId,
                    disabled: false
                });
            })
            .then((focusedTabInfo) => {
                // Close it
                return workspaceApi.closeTab({ tabId: focusedTabInfo.tabId });
            })
            .catch(function (error) {
                console.error(error.message);
                if (isConsoleNav) {
                    throw error;
                }
            });
    },

    /*
        Modal body is calling for an update to the modal header.
    */
    setModalHeaderRichText: function (header, event) {
        header.set("v.headerRichText", event.detail.headerRichText);
    },

    /*
        Modal body is calling for an update to the footer buttons.
    */
    setModalFooterButtons: function (footer, event) {
        footer.set("v.buttons", event.detail.buttons);
    },

    /*
        Modal body is commanding the modal to close. Event detail is the modal's response back to the caller, if any.
    */
    closeModal: function (component, event, openModal, bodyComponentName) {
        // Close the modal
        openModal.close();

        // Publish response message so original caller knows it closed.
        component.find("responseChannel").publish({ bodyComponentName, response: event.detail });
    },

    // Compare page references in order to find if a subtab is already open
    isEqualPageReference: function (newPageRef, existingPageRef) {
        // Compare type
        if (newPageRef.type !== existingPageRef.type) {
            return false;
        }

        if (
            (newPageRef.attributes && !existingPageRef.attributes) ||
            (!newPageRef.attributes && existingPageRef.attributes)
        ) {
            return false;
        }

        // Compare all attributes specified in the new reference
        if (newPageRef.attributes) {
            for (let propertyName of Object.getOwnPropertyNames(newPageRef.attributes)) {
                if (existingPageRef.attributes[propertyName] !== newPageRef.attributes[propertyName]) {
                    return false;
                }
            }

            for (let propertyName of Object.getOwnPropertyNames(existingPageRef.attributes)) {
                if (existingPageRef.attributes[propertyName] !== newPageRef.attributes[propertyName]) {
                    return false;
                }
            }
        }

        if ((newPageRef.state && !existingPageRef.state) || (!newPageRef.state && existingPageRef.state)) {
            return false;
        }

        // Compare all state specified in the new reference
        if (newPageRef.state) {
            for (let propertyName of Object.getOwnPropertyNames(existingPageRef.state).filter((name) =>
                name.startsWith("c__")
            )) {
                if (existingPageRef.state[propertyName] !== newPageRef.state[propertyName]) {
                    return false;
                }
            }

            for (let propertyName of Object.getOwnPropertyNames(newPageRef.state).filter((name) =>
                name.startsWith("c__")
            )) {
                if (existingPageRef.state[propertyName] !== newPageRef.state[propertyName]) {
                    return false;
                }
            }
        }

        return true;
    }
});
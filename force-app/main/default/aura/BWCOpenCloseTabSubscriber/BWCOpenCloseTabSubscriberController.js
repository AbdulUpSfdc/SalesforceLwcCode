({
    handleOpenCloseTab : function(component, event, helper) {
        let operation = event.getParam('operation');
        let recordId = event.getParam('recordID');
        console.log("operation :"+operation);
        console.log("recordId :"+recordId);
        
        let workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
        

    }
})
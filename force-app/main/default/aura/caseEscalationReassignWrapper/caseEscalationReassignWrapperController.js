({
    doInit : function(component, event, helper) {
        let workspaceAPI = component.find("workspace");
        console.log(component.get("v.recordId"));
        
        //Get parentTab
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            let parentTabId = response.parentTabId;
            //Getting info from parent tab
            return workspaceAPI.getTabInfo({tabId: parentTabId});
        })
        .then(function(enclosingTabInfo)
        {
            console.log('response', enclosingTabInfo);
            let currentTabId = enclosingTabInfo.tabId;
            let recordIdTab = enclosingTabInfo.recordId;

            console.log('EscalationReassign Wrapper: parentTab Record Id');
            console.log({recordIdTab});

            component.set("v.parentTabId", recordIdTab);
        })
        .catch(function(error) {
            console.error(error );
        });
    

    }
})
({
  onTabCreated: function (component, event, helper) {
    var newTabId = event.getParam("tabId");
    var workspaceAPI = component.find("workspace");
    workspaceAPI
      .getTabInfo({
        tabId: newTabId
      })
      .then(function (response) {
        var newTabUrl = response.url;
        if(newTabUrl.endsWith('/lightning/n/Knowledge_Landing')) {
            console.log('found km page tab');
            workspaceAPI.setTabLabel({
              tabId: newTabId,
              label: "Knowledge Management"
            });
            workspaceAPI.setTabIcon({
              tabId: newTabId,
              icon: "utility:education"
            }); 
        }
      });
   
  }
});
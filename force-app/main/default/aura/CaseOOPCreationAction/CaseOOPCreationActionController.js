({
    closeMethodInAuraController : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    getValueFromLwc : function(component, event, helper) {
        //console.log("WWWW",event.getParam('value'));	
        //alert("Work");
        
        var urlDetails='';
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(recDetails) {
            console.log("###Details",recDetails.pageReference.state.ws);
            urlDetails=recDetails.pageReference.state.ws;
            
            
            var workspaceAPI = component.find("workspace");
            workspaceAPI.openTab({
                url: urlDetails,
                focus: true
            }).then(function(response) {
                workspaceAPI.openSubtab({
                    parentTabId: response,
                    url: '/lightning/r/case/'+event.getParam('value')+'/view',
                    focus: true
                });
            })
            .catch(function(error) {
                console.log(error);
            });
            
            
        })
        .catch(function(error) {
            console.log(error);
        });
        
        
        
        
    }
})
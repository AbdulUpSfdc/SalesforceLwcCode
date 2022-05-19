({
    getUserAccess : function(component, event, helper) {
        var action = component.get("c.hasRecordAccess");
        action.setParams({
            title:$A.get("$Label.c.BWC_IMEI_Search_Title")
       });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
               helper.setFocusedTabLabel(component, event, helper);
            } else {
				helper.showToast();
            }
        });
        $A.enqueueAction(action);
    } ,

    setFocusedTabLabel : function(component, event, helper) {
        // helper.getUserAccess(component);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo()
        .then(response=>{
            for(var i=0; i<response.length; i++){
                if(response[i].pageReference.attributes && 
                        response[i].pageReference.attributes.apiName == "IMEI_Search"
                        ){
                            var focusedTabId = response[i].tabId;
                            workspaceAPI.setTabLabel({
                                tabId: focusedTabId,
                                label: "IMEI Search"
                            });
                            workspaceAPI.setTabIcon({
                                tabId: focusedTabId,
                                icon: "action:",
                                iconAlt: "IMEI Search"
                            });
                            
                        }
            }
        })
        .catch(error=>{
                console.error(error);
        });
    },
            
    showToast : function() {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    title : 'Access Error',
                    message:$A.get("$Label.c.BWC_IMEI_Access_Error_Message"),
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                    });
                    toastEvent.fire();
    }
})
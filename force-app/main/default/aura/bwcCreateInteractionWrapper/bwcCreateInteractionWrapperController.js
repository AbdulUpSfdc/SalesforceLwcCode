({
    getValueFromLwc : function(component, event) {
        var workspaceAPI = component.find("workspace");
        var staticLabel = $A.get("$Label.c.BWC_Create_Interaction_Error_Message");

        workspaceAPI.isConsoleNavigation()
        .then(isConsole => {

            if (isConsole) {

                // We're in the console, don't allow if other interactions are open
                return workspaceAPI.getAllTabInfo()
                .then(response => {
                    let isInteractionOpen = false;
                    for(var i=0; i<response.length; i++){
                        var tabTitle = response[i].title;
                        
                        if(response[i].pageReference.attributes && 
                        response[i].pageReference.attributes.objectApiName == "Interaction__c"
                        && response[i].pageReference.attributes.recordId){
                            isInteractionOpen = true;
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "Error",
                                "title": "Error",
                                "message": staticLabel,
                                "mode": "sticky"
                            });
                            toastEvent.fire();
                        }
                        
                    }
                    if(isInteractionOpen == false){
                        return component.find('bwcCreateInteraction').createInteraction();
                    }
                })
                .catch(error=>{
                    console.error(error);
                });

            }
            else {

                // Not in console, just do it
                return component.find('bwcCreateInteraction').createInteraction();

            }

        })
        .catch(function(error) {
            console.error(error);
        });

    },

    handleNavigationtoInteraction : function(component, event){

        var obj = JSON.stringify(event.getParam('value'));
        var stringify = JSON.parse(obj);
        console.log('Id==' + stringify.id);

        if(stringify){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.openTab({
                recordId: stringify.id,
                focus: true
            }).then(function(response) {
                workspaceAPI.getTabInfo({
                    tabId: response
                }).then(function(tabInfo) {
                    console.log("The url for this tab is: " + tabInfo.url);
                });
            })
            .catch(function(error) {
                console.error(error);
            });
        }

    }
})
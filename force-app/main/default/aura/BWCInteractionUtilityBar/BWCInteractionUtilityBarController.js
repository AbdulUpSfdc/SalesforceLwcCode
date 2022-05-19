({
	doInit : function(component, event, helper) {
        console.log('in BWCUtilityBar init');
        component.set("v.mapTabIdToTabInfo", new Map());

        helper.registerOnUtilityClickHandler( component, event, helper );
    },

    onTabClosed : function(component, event, helper) {

        helper.publishConsoleEvent(component, event);

        console.log('Tab closed');
        let tabId = event.getParam('tabId');

        let mapTabIdToTabInfo = component.get("v.mapTabIdToTabInfo");
        if (mapTabIdToTabInfo.has(tabId)) {
            console.log('Tab closed:' + JSON.stringify(mapTabIdToTabInfo.get(tabId)));
            let tabInfo = mapTabIdToTabInfo.get(tabId);
            
            // if Interaction tab is closed
            if (tabInfo.isSubtab == false && tabInfo.pageReference != null && 
                tabInfo.pageReference.type == "standard__recordPage" && 
                tabInfo.pageReference.attributes != null &&
                tabInfo.pageReference.attributes.objectApiName == "Interaction__c") {
                
                let interactionId = tabInfo.pageReference.attributes.recordId;
                component.set("v.interactionId", interactionId);
                helper.handleBWCInteractionComplete(component);
            }
        }
    },
    onTabCreated : function(component, event, helper) {

        helper.publishConsoleEvent(component, event);

        console.log('Tab created');
        let tabId = event.getParam('tabId');
        let workSpaceApiFix = component.get("v.WorkSpaceApi");

        let workspaceAPI = workSpaceApiFix;
        
        // Store the tab info in a map.
        workspaceAPI.getTabInfo({
            tabId: tabId
        }).then(function(response) {
            console.log('Tab created:' + JSON.stringify(response));
            let mapTabIdToTabInfo = component.get("v.mapTabIdToTabInfo");
            mapTabIdToTabInfo.set(tabId, response);
        })
        .catch(function(error) {
            console.log('Error in getTabInfo:' + error);
        });
    },
    
    closeModal: function(component, event){
        console.log('In closeModal');
        component.set("v.showModal", false);
    }, 
    
    saveNotes: function(component, event){
        console.log('In saveNotes');
        
        // TODO: save notes
        // 
        component.set("v.showModal", false);
    }, 
    onConsoleEvent: function(component, event, helper) {
        helper.publishConsoleEvent(component, event);
    },

    handleConsoleApi: function(component, event, helper) {
        if ( !event ) {
            return;
        }
        const params = event.getParams();
        console.debug( "params: " + JSON.stringify( params ) + ";" );
        if ( event.getParam("messageType") !== null && event.getParam("messageType") !== 'method') {
            return;
        }

        // Do we really need it?
        if ( event.getParam("pageUrl") !== window.location.href) {
            return;
        }

        const methodName = event.getParam("methodName");
        if ( methodName === "openSubtab" || methodName === "closeFocusedTab" ) {
            return; // code for that historically in the BWCPageHelper. Should it moved here?
        }

        const args = event.getParam("arguments");
    
        helper.execConsoleApiMethod( component, methodName, args );
    },
})
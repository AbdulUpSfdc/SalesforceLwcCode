({
    createInteractionActivity: function(component, message) {
        console.log('BWCIntTrackUtilityBar received BWC_InteractionActivity__c LMS');

        if (message != null) {
            const interactionId = message.getParam("interactionId");
            const action = message.getParam("action");
            const customerId = message.getParam("customerId");
            const detailRecord = message.getParam("detailRecord");
            const type = message.getParam("type");

            if(interactionId != null) {
                console.log('interactionId ' + interactionId);
            }
            if(action != null) {
                console.log('action ' + action);
            }
            if(customerId != null) {
                console.log('customerId ' + customerId);
            }
            if(detailRecord != null) {
                console.log('detailRecord ' + detailRecord);
            }
            if(type != null) {
                console.log('type ' + type);
            }

            // call Apex to create activity
            let createAction = component.get("c.createInteractionActivity");
            createAction.setParams({"interactionId": interactionId, "actionName": action, "detailRecord": detailRecord});
            createAction.setCallback(this, response => {
                const state = response.getState();
                if(state === "SUCCESS"){
                    console.log("Interaction Activity created successfully");
                }
                else if (state === "ERROR") {
                    console.log('Error creating record: ' + response.getError());
                }
        
            });

            $A.enqueueAction(createAction);
        }
    },

    createEscalationCase: function(component, message) {
        console.log('BWCIntTrackUtilityBar received BWC_EscalationCase__c LMS');

        const interactionId = message.getParam("interactionId");
        const detailRecord = message.getParam("detailRecord");
        const type = message.getParam('type');
        const feature = message.getParam('feature');

        // call Apex to create escalation case
        const createAction = component.get('c.createEscalationCase');
        createAction.setParams({"interactionId": interactionId, "ecType": type, "ecFeature": feature, "detailRecord": detailRecord});
    
        createAction.setCallback(this, response => {
            const state = response.getState();
            if(state === "SUCCESS"){
                const newCaseId = response.getReturnValue();
                console.log("Escalation Case created successfully, id = " + newCaseId);

                // send message to stop spinner
                const completionPayload = {scope: type};
                component.find("lmsCompletion").publish(completionPayload);        

                // open Case in subtab - Requires sending message to hidden BWCOpenSubTab.
                const message = {
                    recordId: newCaseId,
                    label: 'Escalation Case'
                }

                this.openSubTab(component, message);
            }
            else if (state === "ERROR") {
                console.log('Error creating record: ' + response.getError());
            }
    
        });

        $A.enqueueAction(createAction);

    },

    // open sub tab
    openSubTab : function(component, params) {

        let workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            let focusedTabId = response.tabId;

            workspaceAPI.openSubtab({
                parentTabId: focusedTabId,
                recordId:  params.recordId,
                focus: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    completeTransfer: function(component, message) {
        // close the tab  and publish BWC_InteractionComplete__c message.
        let interactionId = message.getParam("recordId");
        
        // find the tab of the Interaction and close it.
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function(response) {
            for (let tabInfo of response) {
                
                // Check if the tab matches the interaction id
                if (tabInfo.isSubtab == false && tabInfo.pageReference != null && 
                    tabInfo.pageReference.type == "standard__recordPage" && 
                    tabInfo.pageReference.attributes != null &&
                    tabInfo.pageReference.attributes.objectApiName == "Interaction__c" &&
                   	tabInfo.pageReference.attributes.recordId == interactionId) {
                    
                    //First re-enable the close button
                    workspaceAPI.disableTabClose({
                        tabId: tabInfo.tabId,
                        disabled: false
                    })
                    .then(function(interactionTabInfo) {
                        // Now close the tab
            			return workspaceAPI.closeTab({tabId: interactionTabInfo.tabId});
                    })
                    .catch(function(error) {
                        console.log('Error calling workspaceAPI.disableTabClose: ' + error);
                    });
                }
                
                
            }
        })
        .catch(function(error) {
            console.log('Error calling workspaceAPI.getAllTabInfo: ' + error);
        });
        
        // raise event BWC_InteractionComplete
        let payload = {
            recordId: interactionId,
            objectName: "Interaction__c"
        };
        component.find("lmsBWCInteractionComplete").publish(payload);
       
    }
    

})
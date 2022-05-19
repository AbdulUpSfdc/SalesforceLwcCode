({
    createInteractionActivity: function(component, message) {
        console.log('BWCIntTrackUtilityBar received BWC_InteractionActivity__c LMS');

        if (message != null) {
            // let interactionId = message.getParam("interactionId");
            const action = message.getParam("action");
            const customerId = message.getParam("customerId");
            const detailRecord = message.getParam("detailRecord");
            const type = message.getParam("type");

            // if(interactionId != null) {
            //     console.log('interactionId ' + interactionId);
            // }
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

            // Get the interaction id from the primary tab
            const workspaceAPI = component.get("v.WorkSpaceApi");
            workspaceAPI.getFocusedTabInfo()
            .then(focusedTabInfo => {

                if (focusedTabInfo.isSubtab) {

                    // This is sub tab, get its primary tab
                    return workspaceAPI.getTabInfo({tabId: focusedTabInfo.parentTabId});


                }
                else {

                    // Already on primary tab
                    return Promise.resolve(focusedTabInfo);

                }

            })
            .then(tabInfo => {

                let interactionId;
                if (tabInfo.pageReference &&
                    tabInfo.pageReference.type == "standard__recordPage" &&
                    tabInfo.pageReference.attributes &&
                    tabInfo.pageReference.attributes.objectApiName === "Interaction__c") {

                    // We found primary interaction tab -- use its interaction id
                    interactionId = tabInfo.pageReference.attributes.recordId;
                    console.log('Using tab interaction id: ' + interactionId);

                }
                else if(message.getParam("interactionId")) {

                    interactionId = message.getParam("interactionId");

                }else{

                    throw new Error('Unable to find Interaction ID from focused tab.');

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
                        console.log('Error creating record: ' + JSON.stringify(response.getError()));
                    }

                });

                $A.enqueueAction(createAction);

            })
            .catch(error => {
                console.error(error);
            });

        }
    },

    createEscalationCase: function(component, message, helper) {
        console.log('BWCIntTrackUtilityBar received BWC_EscalationCase__c LMS');
        const interactionId = message.getParam("interactionId");
        const detailRecord = message.getParam("detailRecord");
        const type = message.getParam('type');
        const feature = message.getParam('feature');
        let toastEvent = $A.get("e.force:showToast");
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
                console.log('Error creating record: ', response.getError());
                console.log(response.getError());
                toastEvent.setParams({
                    "title": "Error!",
                    "message": helper.cleanErrorMessage(response.getError()[0]),
                    "type":"error"
                });
                toastEvent.fire();
                const completionPayload = {scope: type};

                component.find("lmsCompletion").publish(completionPayload);

            }

        });

        $A.enqueueAction(createAction);

    },
    cleanErrorMessage : function(message) {
        let {fieldErrors, pageErrors} = message;

        if(pageErrors && Array.isArray(pageErrors)){
            return pageErrors.map(error=>error.message).join(', ');
        }

        if(fieldErrors){
            return Object.entries(fieldErrors).map(error=>error[1].message).join(', ');
        }


    },
    // open sub tab
    openSubTab : function(component, params) {
        let workSpaceApiFix = component.get("v.WorkSpaceApi");

        let workspaceAPI = workSpaceApiFix;
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            let focusedTabId = response.tabId;
            if(!params.recordId){ params=params.getParams();}
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

    completeTransfer: function(component, message, helper) {
        // close the tab  and publish BWC_InteractionComplete__c message.

        console.log('completeTransfer, BWC_TransferCompleted__c Received');

        const TRUE_STRING = 'true';

        //Actions
        const CONFERENCE_ACTION = 'Conference';
        const CONSULT_ACTION = 'Consult';
        const HANDOFF_ACTION = 'Handoff';

        console.log('Params: ', message.getParams());
        //params from method

        //treat as boolean
        let interactionId = message.getParam("recordId");
        let TransferType = message.getParam("TransferType");
        let HandOff = message.getParam("Handoff");
        let Join = message.getParam("Join");
        let Group = message.getParam("Group");
        let PhoneNumber = message.getParam("PhoneNumber");

        console.log({interactionId});
        console.log({TransferType});
        console.log('handoff: ',message.getParam("Handoff"));
        console.log('join: ',message.getParam("Join"));
        console.log('group: ',message.getParam("Group"));
        console.log({PhoneNumber});

        let conferenceConsult = Join ? CONFERENCE_ACTION : CONSULT_ACTION;
        let handoffNone = HandOff ? HANDOFF_ACTION : '';

        let action = `${TransferType} | ${conferenceConsult}`;

        if(handoffNone){
            action+=' '+handoffNone;
        }

        console.log('action: ', action);
        let detailRecord = {
            TransferType,
            HandOff,
            Join,
            Group,
            PhoneNumber
        }

        let detailRecordStr = JSON.stringify(detailRecord);

        let createAction = component.get("c.createInteractionActivity");
        createAction.setParams({"interactionId": interactionId, "actionName": action, "detailRecord": detailRecordStr});
        createAction.setCallback(this, response => {
            const state = response.getState();
            if(state === "SUCCESS"){
                console.log("Interaction Activity created successfully");
            }
            else if (state === "ERROR") {
                console.log('Error creating record: ' + JSON.stringify(response.getError()));
            }

        });

        $A.enqueueAction(createAction);

    },
    closeFocusTab: function(component, message) {

        let workspaceAPI = component.get("v.WorkSpaceApi");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                let focusedTabId = response.tabId;
                workspaceAPI.disableTabClose({
                    tabId: focusedTabId,
                    disabled: false
                });
                workspaceAPI.closeTab({tabId: focusedTabId});
            })
            .catch(function(error) {
                console.log(error);
            });
        },
    disableCloseTab: function(component, message) {

        let workspaceAPI = component.get("v.WorkSpaceApi");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            let focusedTabId = response.tabId;
            workspaceAPI.disableTabClose({
                tabId: focusedTabId,
                disabled: message.getParam('Enabled')
            });
        })
            .catch(function (error) {
                console.log(error);
            });
    },
    openNewWindow: function(component, message) {
        window.open(message.getParam('URL') ,"_blank");

    },
})
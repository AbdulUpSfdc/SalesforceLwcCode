({
    /*
    This method will run the component is loaded. It will read all the configuration
    in the BWC_OpusLIC__mdt metadata and store in the map object named globalParam.
    */
    doInit: function(cmp, event, helper) {
        // loading initialization attributes from custom metadata
        var action = cmp.get("c.getInitDetails");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let opusvar = response.getReturnValue();
                console.log("From server: " + response.getReturnValue());
                cmp.set("v.globalParam", opusvar);
                console.log('value of URL :'+opusvar['PageURL']);
                cmp.set("v.initComplete", true);

                helper.processTabIdQueue(cmp, helper);
            } else if (state === "ERROR") {
                helper.showInitDetailsFailedToast();
            }
        });
        $A.enqueueAction(action);
    },
    /*
        method will run when a tab will open. It will use tab Id to read the
        tab detail and check if the recordid is a interaction record. If its a
        Interaction record LIC Start. During LIC it will first check if the
        Interaction record has all the neceassary data by calling canlaunchOpus
        apex method.
    */
    onTabCreated: function(cmp, event, helper) {
        var focustabId = event.getParam('tabId');
        // check if init has completed
        let initComplete = cmp.get("v.initComplete");
        if (initComplete) {
            // if init is complete, process the tab creation
            helper.processTabCreated(cmp, helper, focustabId);
        } else {
            // queue the tab for when init completes
            let tabIdQueue = cmp.get("v.tabIdQueue");
            tabIdQueue.push(focustabId);
            cmp.set("v.tabIdQueue", tabIdQueue);
        }
    },
    // /*
    //     If the interaction tab is closed, also close the OPUS window.
    // */
    // onTabClosed : function(cmp, event, helper) {
    //     var tabId = event.getParam("tabId");
    //     var currTab = cmp.get("v.currTab");
    //     if (currTab == tabId) {
    //         // TODO: Shouldn't we just call helper.closeExistingTab(cmp);?
    //         var winRef = cmp.get("v.windowHandle");
    //         winRef.close();
    //     }
    // },
    // /*
    //  Listener method responsible for listening Message channel named BWC_MsgToLIC__c
    //  It will react when the message is received. Currently it is build to open tab.
    // */
    // // TODO: Is this still used? Looks like the component calls handleEventListener() instead of this
    // handleChanged : function(cmp, event, helper) {
    //     let msg = event.getParam('msg');
    //     let params = event.getParam('params'); // TODO: this doesn't appear to be used?
    //     console.log("msg :"+msg);
    //     console.log("params :"+params);
    //     if (msg == 'INTERACTION_READY') {
    //         // TODO: I think we should call helper.closeExistingTab() from helper.openOPUSWithRetry()
    //         helper.closeExistingTab(cmp, helper);
    //         helper.openOPUSWithRetry(cmp, helper, intRecId);
    //     }
    // },
    /**
     * Handles the event fired from click events. Basically when user clicks something like "Add a Line" an event is
     * fired to LIC to OPUS. This is the listener for that event.
     * @param {*} cmp Aura Component
     * @param {*} event Aura Event
     * @param {*} helper Aura Helper
     */
    handleEventListener : function(cmp, event, helper) {
        let workSpaceApiFix = cmp.get("v.WorkSpaceApi");

        var workspace = workSpaceApiFix;
        let msg = event.getParam('msg');
        let ban = event.getParam('ban');
        let params = event.getParam('params'); //not being used
        let opusStatus = cmp.get("v.opusStatus");
        let currban = cmp.get("v.currBan");
        let intRecId = cmp.get("v.intRecId");
        var globalParam = cmp.get("v.globalParam");
        var currTab = cmp.get("v.currTab");
        console.log({msg});
        console.log({params});
        // console.log(Object.keys(params));
        console.log('****** inside Handle event listener');
        console.log({opusStatus});
        console.log({intRecId});
        console.log({ban});
        console.log({currban});
        console.log("Enabled: "+globalParam['Enabled']);
        // TODO: Is this the only message supported?
        if (globalParam['Enabled'] == 'true') {
            // the 'CLOSE' message is when the 'Interaction' is closed/completed
            if (msg == 'CLOSE') {
                // TODO: explain what is happening in the 'CLOSE' event
                workspace.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    console.log('currTab :'+currTab );
                    console.log('focusedTabId :'+focusedTabId );
                    if (currTab == focusedTabId) {
                        console.log('current tab are equal');
                        helper.closeExistingTab(cmp, helper);
                        // initialize vars
                        helper.resetVars(cmp, helper);
                    }
                })
                .catch(function(error) {
                    console.log(error);
                });
            // 'INIT' is basically the event requesting the LIC to OPUS
            } else if (msg == 'INIT') {
                console.log('inside INIT');
                workspace.getFocusedTabInfo().then(function(response) {
                    var focusId = response.tabId;
                    console.log('focustabId :'+focusId);
                    workspace.getTabInfo({
                        tabId: focusId
                    }).then(function(response) {
                        // TODO: explain...
                        console.log('response.recordId :'+response.recordId);
                        console.log('globalParam-RecordIdPrefix '+globalParam['RecordIdPrefix']);
                        if (response.recordId != null &&
                            response.recordId.startsWith(globalParam['RecordIdPrefix']) == true
                            && globalParam['Enabled'] == 'true') {


                           //if Interaction is not accessible anymore or the user has close permissions, show close button
                            let focusId = response.tabId;

                            // TODO: explain?
                            // save the current tab so that...
                            cmp.set("v.currTab", focusId);

                            // TODO: explain?
                            cmp.set("v.Attempt",0);
                            cmp.set("v.opusResponseAttempts",0);
                            cmp.set("v.opusStatus","STARTED");

                            // TODO: explain
                            var action = cmp.get("c.canLaunchOpus");

                            // TODO: do we need to put this into a new variable?
                            var intRecId = response.recordId;
                            cmp.set("v.intRecId", intRecId);
                            action.setParams({ recordId : intRecId });
                            action.setCallback(this, function(response) {
                                var state = response.getState();
                                if (state === "SUCCESS") {
                                    let opusConfig = response.getReturnValue();

                                    let canCloseTab = opusConfig['CanCloseTab'] === 'true';
                                    cmp.set('v.canCloseTab', canCloseTab);

                                    helper.processCloseTabPermisison(cmp);

                                    console.log("canLaunchOpus: " + opusConfig['status']);
                                    console.log("ban: " + opusConfig['ban']);
                                    // TODO: explain
                                    if (opusConfig['status'] == 'true') {
                                        if (opusConfig['hasPermission'] == 'true' && opusConfig['ban'] != null) {
                                            console.log('Launch OPUS now');
                                            cmp.set("v.currBan", opusConfig['ban']);
                                            helper.closeExistingTab(cmp, helper); // TODO: should this be called implicitly from helper.callOPUSWithRetry()?
                                            //helper.openOPUSWithRetry(cmp, helper, intRecId); // TODO: remove?
                                            helper.callOPUS(cmp, helper, intRecId)
                                        }
                                    }
                                }
                                // TODO: do we need to account for the 'else'?
                            });
                            $A.enqueueAction(action);
                        }
                    });
                })
                .catch(function(error) {
                    console.log(error);
                });
                ///end here
            } else if (opusStatus == 'FAILED') {

                helper.launchOpusFromEvent(cmp, helper);

            } else if (opusStatus == 'LOADING') {

                let tofocus =  cmp.get("v.windowHandle");
                //if window is closed or null, launch opus window again
                if (tofocus == null || tofocus.closed) {

                    // window was closed, start trigger 1 again
                    helper.launchOpusFromEvent(cmp, helper);

                }else{

                    tofocus.focus();
                    helper.createOpusLog(cmp, 'Setting focus on OPUS', false);
                    // Send sending opus_sf_init message to opus
                    let opustask = 'opus_sf_init';
                    cmp.set("v.lastMsg", opustask);
                    helper.sendPostMessageWithData(cmp, helper, intRecId, opustask);

                }

            } else if (opusStatus === 'STARTED' || opusStatus == 'READY'){

                //Opus status is STARTED when opus is waiting for second trigger.
                //If user closes opus window, the opusStatus will remain as started.

                let tofocus =  cmp.get("v.windowHandle");

                if (tofocus == null || tofocus.closed) {
                    // window was closed, start trigger 1 again
                    helper.launchOpusFromEvent(cmp, helper);
                }else{
                    tofocus.focus();
                    helper.createOpusLog(cmp, 'Setting focus on OPUS', false);
                }

            }
            else {
                // OPUS is not loaded or failed, queue the click event for when OPUS has finished loading...

                // build the trigger #2 message
                var opustask = 'opus_sf_init';
                helper.getMessage(cmp, intRecId, opustask);

                // queue the message
                let queue = cmp.get("v.msgQueue");
                queue.push(cmp.get("v.sfdcmsg"));
                cmp.set("v.msgQueue", queue);
                console.log('Message added to queue: ' + queue);
            }
        } else {
            helper.showOpusDisable();
        }
    }
})
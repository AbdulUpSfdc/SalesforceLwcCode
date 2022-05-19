({
    /*
    method responsible to close the OPUS tab. It will call in two time
    1) When OPUS did't send ready message. We close tab and retry.
    2) When user close the Interaction record tab. it will close the
    correponding OPUS tab.
    */
    // TODO: naming this 'closeWindow' may be a more accurate name
    closeExistingTab : function(cmp, helper) {
        const globalParam = cmp.get("v.globalParam");
        const content = cmp.get('v.windowHandle');
        // TODO: do we need both the undefined and null checks?
        if (content != undefined && content != null && !content.closed) {
            let trackingId =  cmp.get("v.trackingIdent");
            if (trackingId) {
                let postMsg = {"msg" : {"task" : "opus_sf_close", "data" : {"trackingIdent" : trackingId}}};
                console.log('Close Message :' + postMsg);
                content.postMessage(postMsg, globalParam['PopUpUrl']);
            }
            window.setTimeout($A.getCallback(function() {
                console.log('Now closing tab');
                content.close();
            }), 5000);

        }
    },
    /*
    method responsible to open tab and load visualforce page on that tab. This
    visualforce page is responsible to open OPUS launch.
    */
    callOPUS : function(component, helper, recordId) {

        helper.makeCallout(component, recordId, helper);

        // If we don't get a response from opus in 40 sec, we close the opus window
        var timer = window.setTimeout(
            $A.getCallback(function() {
                console.log('***timeOut');
                let opusResponded = component.get('v.opusResponded');
                if (!opusResponded) {
                    console.log('***message not received');
                    helper.closeExistingTab(component, helper);
                }
            }),40000
        );

        // Store the timeout reference so it can be cleared later
        component.set('v.waitForResponseTIMER', timer);
    },
    /*
    method to open the tab and start the listener to listen the post message
    */
    makeCallout : function (component, recordId, helper) {
        console.log('makeCallout :recordId'+recordId);
        var globalParam = component.get("v.globalParam");
        var attempt = component.get("v.Attempt");
        var relaunch = component.get("v.launchFromEvent") ? 'Y' : 'N';
        let height = window.innerHeight;
        let width = window.innerWidth;
        let popheight = height * .9;
        let popwidth = width * .9;
        const trackingIdent = component.get("v.trackingIdent");

        // build the url for the OPUS LIC, this actually opens a VF page that then makes an HTTP POST to OPUS
        let url = globalParam['PageURL'] + '?Id=' + recordId + '&attempt='+attempt+'&relaunch='+relaunch;

        console.log('MakeCallout: opening window');
        // open OPUS in a new window (so we can popunder) and save the window handle so we can interact with it later
        var winRef = window.open(url, globalParam['WindowName'], "width="+popwidth+", height="+popheight);

        if (!winRef || winRef.closed || typeof winRef == 'undefined' || typeof winRef.closed == 'undefined') {

            console.log('popup is blocked');
            helper.showPopupBlockToast();

            helper.createOpusLog(component, 'Unable to launch OPUS because of Popup Blocker', true);

            // If OPUS window did not launch, we should not continue executing the rest of the process
            return;
        } else {
            console.log('popup are allowed');
        }
        component.set("v.windowHandle", winRef);

        // by opening a new browser tab & immediately closing it, we can cause OPUS to launch as a "popunder"
        // this is effectively bringing focus back to Salesforce
        // Note, this will require the browser to allow popups from Salesforce

        let shouldFocusOpus = component.get("v.launchFromEvent");
        console.log({shouldFocusOpus});
        if (!shouldFocusOpus) {
            window.open().close();
        }else{
            helper.createOpusLog(component, 'Setting focus on OPUS', false);
        }

        helper.createOpusLog(component, `Launching OPUS - Relaunch ${relaunch} - TrackingIdent ${trackingIdent}`, false);

        // start listening to messages from the popup
        helper.startListener(component, helper);
    },
   /*
    most important method of this application. This method reacts when a post
    message received from OPUS. As per documentation we shouldnot take any
    action until we did't receive the the ready message.
    LIC -0001 - happy path. OPUS successfully launched
    LIC -0006 - retry opus with previously send message
    LIC 02/03/04 - retry opus with opus_sf_search
   */
    responseCodeAction : function(component, helper, msg) {
        // TODO: explain what these variables are
        const responseCode = component.get("v.opusResponse");
        const globalParam = component.get("v.globalParam");
        const recordId = component.get("v.intRecId");
        console.log('REPONSE CODE ACTION STARTED : '+responseCode);
        // TODO: should this be a switch/case statement instead of an if/else if?

        if (responseCode == null) {
            console.log('Dont do anything no response from OPUS');
        }
        // LIC-0001: LIC Established - OPUS is ready with the data for dashboard display
        else if (responseCode == 'LIC-0001'  || responseCode == 'LIC-0011') {
            // Success Scenario
            console.log('START KEEP ALIVE TIMER.');
            //Add focus on OPUS window. Milon do tomorrow.
            // reset the keep-alive timer by clearing it and starting it again
            clearTimeout(component.get("v.keepaliveTIMER"));
            helper.keepAlive(component, helper, recordId);

            console.log('Getting LIC Established code.');
            component.set("v.opusStatus","READY");
            component.set("v.opusResponseAttempts",0);
            console.log('Focus window');
            //get the window handler and set the focus
            var tofocus =  component.get("v.windowHandle");
            console.log({tofocus});
            tofocus.focus();

            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, false);
            helper.createOpusLog(component, 'Setting focus on OPUS', false);
        }
        // LIC-0002: LIC established - OPUS searching customer - API failed
        // LIC-0003: LIC Established - Mandatory parameter missing in Display request(second trigger)
        // LIC-0004: Tracking Ident mismatch in second trigger
        else if (responseCode == 'LIC-0002' || responseCode == 'LIC-0003' || responseCode == 'LIC-0004') {

            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, true);

            let opusResponseAttempts = component.get("v.opusResponseAttempts");
            //Only three attempts when we receive any if these codes.
            if(opusResponseAttempts<3){
                // Salesforce will search again via messaging - opus_sf_search
                console.log('Search Again');
                var opustask = 'opus_sf_search';
                component.set("v.lastMsg", opustask);

                opusResponseAttempts++;
                component.set("v.opusResponseAttempts", opusResponseAttempts);

                helper.sendPostMessageWithData(component, helper, recordId, opustask);

            }else{
                helper.resetVars();
                helper.closeExistingTab(component, helper); // TODO: should this be called implicitly from helper.callOPUSWithRetry()?
                //Do we need to close the window?
            }
        }
        // LIC-0005: LIC Established - OPUS already displayed dashboard. User is triggering the action again from Salesforce
        else if (responseCode == 'LIC-0005') {
            // User is in session and active ordering is in progress. Salesforce will display a corresponding warning message.
            // TODO: display warning message
            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, false);
        }
        // LIC-0006: LIC Established - OPUS is still working on API calls for the current customer,
        //     and Salesforce is sending display request before OPUS is ready with data.
        else if (responseCode == 'LIC-0006') {
            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, false);
            console.log('inside if lic0006 ');
            // wait for X seconds and retry
            window.setTimeout(
                $A.getCallback(function() {
                    var opustask = component.get("v.lastMsg");
                    console.log('opustask :'+opustask);
                    if (opustask == undefined) {
                        opustask = 'opus_sf_init';
                        component.set("v.lastMsg", opustask);
                    }
                    helper.sendPostMessageWithData(component, helper, recordId, opustask);
                    component.set("v.launchFromEvent", false);
                }), globalParam['XsecWaiting']
           );
        }
        // LIC-0007: LIC is established - OPUS receives a different customer in display request and does not match the customer in context
        else if (responseCode == 'LIC-0007') {
            // Salesforce will display message indicating error occurred. This is not a recoverable error.
            // TODO: close OPUS popup
            // TODO: show error
            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, true);
        }
        // LIC-0008: LIC established - Second trigger came after OPUS session timed out
        else if (responseCode == 'LIC-0008') {
            // Salesforce will have to close the tab and will have to re-launch OPUS.
            // TODO: close OPUS popup
            // TODO: re-launch OPUS
            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, true);
        }else{
            helper.createOpusLog(component, `First response from OPUS: ${JSON.stringify(msg)}`, true);
        }
    },
    showOpusDisable : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            type : 'warning',
            message: $A.get("$Label.c.BWC_LIC_OPUS_DISABLE"),
        });
        toastEvent.fire();
    },
    showPopupBlockToast : function(msg) {
        var toastEvent = $A.get("e.force:showToast");
        console.log('show toast :');
        toastEvent.setParams({
            mode: 'dismissible',
            type : 'warning',
            message: 'Please disable your pop-up blocker and retry',
        });
        toastEvent.fire();
    },
    /*
    Listener method to listen the postmessage posted by OPUS. We are only
    interested in two type of message.
    opus_sf_ready : First message from opus. OPUS is ready
    opus_sf_response : Response message from OPUS on salesforce request init/search
    */
    startListener : function(component, helper) {
        // check if we have already initialized the listener
        let listenerInit = component.get("v.listenerInit");
        if (!listenerInit) {
            // subscribe to the JavaScript 'postMessage()' from the OPUS window
            window.addEventListener("message", $A.getCallback(function(event) {
                // get message
                let msg = event.data['msg'];

                // check if there is an OPUS response message
                if (!msg) {
                    return;
                }

                component.set('v.opusResponded', true);
                let timer = component.get('v.waitForResponseTIMER');
                clearTimeout(timer);

                if (msg.task == 'opus_sf_ready') {

                    helper.createOpusLog(component, `Received SF_READY from OPUS: ${JSON.stringify(msg)}` , false);
                    helper.checkTrackingIdent(component, helper, event.data['msg'].data.trackingIdent);

                }
                else if (msg.task == 'opus_sf_response') {

                    const opusResCode = event.data['msg'].data.opusResponseCode
                    console.log("opus_sf_response", opusResCode);
                    component.set("v.opusResponse", opusResCode);
                    helper.responseCodeAction(component, helper, msg);

                }
            }), false);

            // mark the postMessage() event listener as initialized so we do not subscribe multiple times...
            component.set("v.listenerInit", true);
        }
    },
    /*
    We need to call OPUS every 45min to send the heart beat. This method is
    responsible to send opus_sf_init message every 45 min.
    // TODO: We should probably say that the time is defined in the custom metadata
    */
    keepAlive : function(component, helper, recordId) {
        var globalParam = component.get("v.globalParam");
        // TODO: is this necessary? What does it give you over hard-coding this into the method call a few lines below?
        var opustask = 'opus_sf_init';
        // TODO: explain what you are doing here
        var keepalive = window.setTimeout(
            $A.getCallback(function() {
                 helper.sendPostMessageWithData(component, helper, recordId, opustask)
            }), globalParam['KeepAlive']
       );
       // TODO: explain, e.g. 'save the timer so we can clear/reset it later'
       component.set("v.keepaliveTIMER", keepalive);
    },
    /*
    method responsible to get the message from Apex controller based on parameter
    and send the postmessage to OPUS.
    */
    sendPostMessageWithData : function(component, helper, recordId, opustask) {
        // TODO: explain this action
        console.log('sendPostMessageWithData: recordID ', recordId)
        console.log('sendPostMessageWithData: opustask ', opustask)
        component.set("v.lastMsg", opustask);
        var action = component.get("c.getInitMessage");
        let ban  = component.get("v.currBan");
        console.log('ban used to create request :'+ban);
        action.setParams({
            recordId : recordId,
            messageType : opustask,
            relaunch: component.get("v.launchFromEvent")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // TODO: explain
                console.log('POST MSG' +response.getReturnValue())
                helper.sendPostMessage(component, response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    /*
    method to send the post message.
    */
    sendPostMessage : function(component, data) {
        var globalParam = component.get("v.globalParam");
        let postMsg = JSON.parse(data);
        var winRef = component.get("v.windowHandle");
        console.log('SENDING POST MESSAGE :'+data);
        //winRef.postMessage(postMsg, globalParam['DestURL']);
        winRef.postMessage(postMsg, globalParam['PopUpUrl']);
    },

    getMessage : function(cmp, recordId, opustask) {
        var action = cmp.get("c.getInitMessage");
        action.setParams({
            recordId : recordId,
            messageType : opustask,
            relaunch: cmp.get("v.launchFromEvent")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // TODO: explain
                console.log('POST MSG' +response.getReturnValue())
                cmp.set("v.sfdcmsg", response.getReturnValue());
            }
        });
    },
    /**
     * This method will submit queued OPUS 'trigger #2' messages that were queued while waiting for OPUS to become ready.
     * @param {*} cmp Aura Component
     * @param {*} helper Aura Helper
     */
    processQueueMessage : function(cmp, helper) {
        console.log('processQueueMessage');
        // get the queued messages, loop through them, and send them to OPUS
        let queue = cmp.get("v.msgQueue");
        for (let i=queue.length-1; i>=0; i--) {
            let msg = queue.pop();
            console.log('Pending Message to post : ',msg);
            helper.sendPostMessage(cmp, msg);
        }
        cmp.set("v.msgQueue", queue);
        console.log('Finished processing message queue');

        // If we launch opus from a click event, send the search event to opus when queued messages are sent
        let launchFromEvent = cmp.get("v.launchFromEvent");
        console.log({launchFromEvent});
        if (launchFromEvent) {
            console.log('OPUS launched from event, send post message: opus_sf_init');
            var opustask = 'opus_sf_init';
            let recordId = cmp.get("v.intRecId");
            console.log({recordId});
            helper.sendPostMessageWithData(cmp, helper, recordId, opustask);
        }
    },
    /**
     * Compare the tracking identifier returned from OPUS to the one generated via Apex.
     * @param {*} cmp Aura Component
     * @param {*} helper Aura Helper
     * @param {*} tracking Tracking identification string.
     */
    checkTrackingIdent : function(cmp, helper, tracking) {
        console.log("opus_sf_ready");
        var action = cmp.get("c.getTrackingIdent");
        let recordId = cmp.get("v.intRecId");
        action.setParams({
            recordId : recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // get the tracking identifier for the current interaction and compare to the one returned from OPUS
                let gtrackingIdent = response.getReturnValue();
                if (tracking == gtrackingIdent) {
                    console.log('tracking id are matched');
                    cmp.set("v.opusStatus", 'LOADING');
                    cmp.set("v.trackingIdent", gtrackingIdent);

                    // process queued messages
                    helper.processQueueMessage(cmp, helper);
                } else {
                    // TODO: should we show an error toast?
                    console.log('tracking id are NOT matched');
                }
            }
        });
        $A.enqueueAction(action);
    },

    showInitDetailsFailedToast : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'sticky',
            type : 'error',
            message: 'There was an error retrieving the init details',
        });
        toastEvent.fire();
    },

    processTabIdQueue : function(cmp, helper) {
        console.log('processTabIdQueue method')
        var tabIdQueue = cmp.get("v.tabIdQueue");
        for (var i in tabIdQueue) {
            var tabId = tabIdQueue.pop();
            console.log('Pending created tabId to prorcess: '+tabId);
            helper.processTabCreated(cmp, helper, tabId);
        }
        cmp.set("v.tabIdQueue", tabIdQueue);
    },

    /**
     * Logic to be executed once a tab is created AND initDetails have been retrieved
    */
    processTabCreated : function(cmp, helper, focustabId) {
        console.log('processTabCreated Method');
        var workspace =  cmp.get("v.WorkSpaceApi");
        var globalParam = cmp.get("v.globalParam");

        workspace.getTabInfo({
            tabId: focustabId
        }).then(function(response) {

            if (response.recordId != null &&
                response.recordId.startsWith(globalParam['RecordIdPrefix']) == true
                && globalParam['Enabled'] == 'true'
                && !response.isSubtab) {

                if (response.title === 'Unable to load') {

                    workspace.disableTabClose({
                        tabId: focustabId,
                        disabled: false
                    })
                    .then(function(tabInfo) {
                        console.log('tab should be closeable: ', tabInfo);
                    })
                    .catch(function(error) {
                        console.log(error);
                    });

                    return;
                }

                // TODO: explain?
                // save the current tab so that...
                cmp.set("v.currTab", focustabId);

                // TODO: explain?
                cmp.set("v.Attempt",0);
                cmp.set("v.opusResponseAttempts",0);
                cmp.set("v.opusStatus","STARTED");

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
                        console.log("hasPermission: " + opusConfig['hasPermission']);
                        // TODO: explain
                        if (opusConfig['status'] == 'true') {

                            if (opusConfig['hasPermission'] == 'true' && opusConfig['ban'] != null) {
                                console.log('Launch OPUS now');
                                cmp.set("v.currBan", opusConfig['ban']);
                                helper.closeExistingTab(cmp, helper); // TODO: should this be called implicitly from helper.callOPUSWithRetry()?
                                helper.callOPUS(cmp, helper, intRecId);
                            }

                        }
                    }
                    // TODO: do we need to account for the 'else'?
                });
                $A.enqueueAction(action);
            }
        });
    },

    /** This method is used to call processTabCreated with the appropriate params
     *  This method is called when opus window is closed but an event wants to set the focus on opus
     * @param  {} cmp
     * @param  {} helper
     */
    launchOpusFromEvent : function(cmp, helper){
        // window was closed, start trigger 1 again
        let workspace = cmp.get("v.WorkSpaceApi");
        console.log('OPUS is closed. Launching again due UI event');
        cmp.set("v.launchFromEvent", true);

        workspace.getFocusedTabInfo()
        .then(focusedTabInfo => {
            console.log({focusedTabInfo});
            if (focusedTabInfo.isSubtab) {
                helper.processTabCreated(cmp, helper, focusedTabInfo.parentTabId);
            }else{
                helper.processTabCreated(cmp, helper, focusedTabInfo.tabId);
            }
        })
        .catch((error)=>{
            let opusStatus = cmp.get("v.opusStatus");
            console.log('error on  status: ',opusStatus);
        });
    },

    /**
     * This method is used to reset the component variables. Helpful when closing an Interaction.
     * @param {*} cmp Component handle.
     * @param {*} helper Helper handle.
     */
    resetVars : function(cmp, helper) {
        cmp.set("v.opusStatus", "WAITING");
        cmp.set("v.windowHandle", null);
        cmp.set("v.currTab", null);
        cmp.set("v.currBan", null);
        cmp.set("v.trackingIdent", null);
        cmp.set("v.msgQueue", []);
        cmp.set("v.sfdcmsg", null);
        cmp.set("v.intRecId", null);
        clearTimeout(cmp.get("v.keepaliveTIMER")); // clear timer before null'ing it
        cmp.set("v.keepaliveTIMER", null);
        cmp.set("v.lastMsg", null);
        cmp.set("v.Attempt", null);
        cmp.set("v.opusResponse", null);
        cmp.set("v.tabIdQueue", []);
        cmp.set("v.launchFromEvent", false);
        cmp.set("v.opusResponseAttempts", 0);
        cmp.set("v.opusResponded", false);
    },

    /**
     * Method used to validate if the user can close a tab manually.
     * If interaction does not have a completed date value yet, user cannot close tab.
     *
    */
    processCloseTabPermisison : function(component){

        let canCloseTab = component.get("v.canCloseTab");
        let focusTabId = component.get("v.currTab");
        let workspace =  component.get("v.WorkSpaceApi");

        if (!canCloseTab) {
            console.log('User cannot close tab')
            workspace.disableTabClose({
                tabId: focusTabId,
                disabled: true
            })
            .then(function(tabInfo) {
                console.log('tab should be closeable: ', tabInfo);
            })
            .catch(function(error) {
                console.log(error);
            });
        }
    },

    /**
     * @param  {} component
     * @param  {} detail Message sent by OPUS / Label indicating what happened
     * @param  {} isError  if true creates a log of type Error otherwise will be of type Info
     */
    createOpusLog : function(component, detail, isError){

        const logResponse = component.get('c.logOpusResponse');
        const intRecId = component.get("v.intRecId");

        detail = typeof detail === 'string' ? detail : JSON.stringify(detail);

        logResponse.setParams(
            {
                detail: detail,
                recordId:intRecId,
                isError: isError
            }
        );

        logResponse.setCallback(this, function(response){

            const state = response.getState();
            if(state === "SUCCESS"){
                console.log('%cOpus Response logged', 'color:green');
            } else if(state === "ERROR"){

                const errors = response.getError();
                console.error('ERROR Logging opus response', errors);

            }

        });

        $A.enqueueAction(logResponse);
    }


})
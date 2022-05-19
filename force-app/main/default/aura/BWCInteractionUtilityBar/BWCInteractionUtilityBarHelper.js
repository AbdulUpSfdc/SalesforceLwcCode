({
	
	handleBWCInteractionComplete : function(component) {
        console.log('in handleBWCInteractionComplete');
		let interactionId = component.get("v.interactionId");    
        
        console.log('before load. id' + interactionId);
        // load interaction as id is changed
        component.find('recordUpdator').reloadRecord(true, function() { 
            // after loading record, update CompletedDate__c with current time
            let today = new Date();
        	console.log('before save2. id' + interactionId);
        	console.log('before save3. date' + today.toISOString());
            // component.set("v.interactionFields.CompletedDate__c", today.toISOString());
            
            // save the record
            component.find("recordUpdator").saveRecord($A.getCallback(function(saveResult) {
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    console.log("Interaction Updated successfully.");
                    // show modal
                    component.set("v.notes", null);
                    component.set("v.showModal", true);
                    
                    // raise event BWC_InteractionComplete
                    let payload = {
                        recordId: interactionId,
                        objectName: "Interaction__c"
                    };
                    component.find("lmsBWCInteractionComplete").publish(payload);
                    console.log('after raising evennt');
                } else if (saveResult.state === "ERROR") {
                    console.log('Problem saving interaction record, error: ' +
                               JSON.stringify(saveResult.error));
                } else {
                    console.log('Unknown problem saving interaction record, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                }
            }));
        });
        
        
	},

    /*
        Publish a Lightning Console API event to a message channel where it can be received by LWC component.
    */
    publishConsoleEvent: function(component, event, eventName) {

        const workSpaceApi = component.get("v.WorkSpaceApi");

        // Get all tab info to send back with event info
        workSpaceApi.getAllTabInfo().then(function(allTabInfo) {

            const eventPayload = {
                messageType: 'event',
                eventType: event.getType(),
                eventBody: {
                    type: event.getType(),
                    params: event.getParams(),
                    allTabInfo: allTabInfo
                }
            }
        
            component.find("consoleApiMessageChannel").publish(eventPayload);

        })
        .catch(function(error) {
            console.log('Error in getTabInfo:' + error);
        });

    },

    execConsoleApiMethod: function( component, methodName, args ) {
        console.debug( "Entering execConsoleApiMethod..." );
        const wsApi = component.get("v.WorkSpaceApi");
        const utilityBar = component.find( "utilitybar" );

        wsApi.isConsoleNavigation()
            .then( isCon => {
                if ( isCon ) {
                    console.debug( "Inside console" ); 
                    const m = (wsApi[ methodName ]) ? wsApi[ methodName ] : utilityBar[ methodName ];
                    if ( m ) {
                        const prom = (args) ? m( args ) : m();
                        prom.then( res => {
                            component.find( "consoleApiMessageChannel").publish({
                                eventType: "methodResponse",
                                methodName: methodName,
                                result: res
                            });
                        });
                    }
                }
            })
            .catch( err => {
                console.error( "Failed to excute consoleAPI " + methodName + ":", JSON.stringify(err) );
            });
    },

    registerOnUtilityClickHandler: function( component, event, helper ) {
        // Subscribe to all utilities
        const utilityBar = component.find( "utilitybar" );

        const onClickHandler = ( resp ) => {
            // console.debug( "Utility onClick: " + JSON.stringify( resp ), resp ); 
            component.find( "consoleApiMessageChannel").publish({
                eventType: "onUtilityClick",
                activeUtility: resp // {"utilityId":"649:0","panelVisible":true}
            });
        }

        utilityBar.getAllUtilityInfo()
            .then( utils => {
                utils.forEach( u => {
                    console.debug( "Registering Utility id=" + u.id + ";" );
                    utilityBar.onUtilityClick({
                        utilityId: u.id,
                        eventHandler: onClickHandler
                    });
                });
            })
            .catch( err => {
                console.error( "Failed to subscribe to the Utilities onClick event" )
            });    
    },
})
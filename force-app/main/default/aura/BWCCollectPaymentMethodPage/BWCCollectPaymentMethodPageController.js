({
    refresh : function(component, event, helper) {
        // Pass the page reference arguments through to variables
        const pageReference = component.get("v.pageReference");
        component.set("v.recordId", pageReference.state.c__recordId);
        component.set("v.capabilities", JSON.parse(pageReference.state.c__capabilities));
    },

    close: function(component) {

        // Close the console subtab

        let workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId()
        .then(enclosingTabId => {

            // Get info about enclosing tab
            return workspaceAPI.closeTab({tabId: enclosingTabId});

        })
        .catch(function(error) {
            console.error('close: ' + error);
        });

    },
    handleCompleted: function(component, event) {
        let pp = event.getParam('paymentProfile');
		const payload = {
            source: "Aura",
            messageBody: pp
        };
		//console.log('### PAYLOAD: ', payload);
		component.find('paymentMethodCompleteMC').publish(payload);
        component.set("v.disableDone", false);
        component.set("v.disableCancel", true);
		/*this.close(component);
		*/
    },
    /*handleTestMessageChannel: function(component, event) {
		console.log('### ENTERED handleTestMessageChannel');
        let pp = '{"profileProcessTime":"2021-04-22","profileOwnerId":"NEWCONNECT-SF-DH276034012678-1",'+
		'"profileName":"American Express1100","profileCreatedTime":"2021-04-22","paySource":'+
		'{"sourceUser":"kc434j","sourceSystem":"SFORCECC","sourceLocation":"CS"},'+
		'"paymentMethodType":"CARD","card":{"zipCode":"12345","trueCreditCardIndicator":true,'+
		'"expireYear":"2026","expireMonth":"11","cardType":"AMEX","cardNumber":"XXXXXXXXXXX1100",'+
		'"cardHolderName":"kevin collins"}}';
		const payload = {
            source: "Aura",
            messageBody: pp
        };
		console.log('### PAYLOAD: ', payload);
		console.log('### paymentMethodCompleteMC: ',component.find('paymentMethodCompleteMC'))
		component.find('paymentMethodCompleteMC').publish(payload);
		this.close(component, event);
    },*/
})
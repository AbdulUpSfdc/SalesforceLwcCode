({
	handleCancelClick : function(component, event, helper) {
        //fire the confirmation event
        
        var myEvent = component.getEvent("ConfirmationUtility_Event");
        myEvent.setParams({ "confirmationStatus": false});
        myEvent.fire();
	},

	handleOkClick : function(component, event, helper) {

        //fire the confirmation event
        var myEvent = component.getEvent("ConfirmationUtility_Event");
        myEvent.setParams({ "confirmationStatus": true});
        myEvent.fire();
	}
})
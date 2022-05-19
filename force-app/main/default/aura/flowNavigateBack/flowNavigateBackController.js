({ invoke : function (component, event, helper) {
//    var action = component.get("c.getListViews");
    action.setCallback(this, function(response){
        var state = response.getState();
        if (state === "SUCCESS") {
            var listviews = response.getReturnValue();
            var navEvent = $A.get("e.force:navigateToList");
            navEvent.setParams({
                "listViewId": "00B6g00000EQmAHEA1",
                "listViewName": null,
                "scope": "BW_RAID_Log__c"
            });
            navEvent.fire();
        }
    });
    $A.enqueueAction(action);
}
})
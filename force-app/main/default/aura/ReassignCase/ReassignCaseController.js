({
    doInit: function (component, event, helper) {
        component.set("v.mode", "reset");
        helper.initReassignButton(component);
    },
    
    recordUpdated: function(component, event, helper) {
        helper.retrieveUsersRole(component);
    },

    handleWorkgroupChange: function (component, event, helper) {
        const selectedQueueId = event.getParam("value");
        helper.processSelectedQueue(component, selectedQueueId);
    },
    
    handleUserChange: function (component, event) {
        const selectedUserId = event.getParam("value");
        component.set("v.userId", selectedUserId);
    }, 
    
    handleReassignClick: function (component, event, helper) {
        const resetButton = event.getSource();
        const mode = component.get("v.mode");
        console.log("In handleReassignClick ");
        console.log("mode " + mode);
        if(mode === "reset") {            
    		const userRoleName = component.get("v.userRoleName");
            console.log("userRoleName " + userRoleName);
            const caseRecord = component.get("v.caseRecord");           
         	
            const rtName = caseRecord.RecordType.DeveloperName;
            const OwnerRole = caseRecord.OwnersRole__c;
            console.log('*** rtName:1 ' + rtName);
            console.log('*** OwnerRole:1 ' + OwnerRole);
            
            if(userRoleName === "Field Admin") {
                console.log("Call validateFieldAdmin " + userRoleName);
             	helper.validateFieldAdmin(component);
            } else {
                helper.prepare(component);
                helper.disableReassignButton(component, true);
            }
        } 
        else if (mode === "queue") {
            const recordId = component.get("v.recordId");
            if (!$A.util.isUndefinedOrNull(recordId)) {
                const caseRecord = component.get("v.caseRecord");
                if (!$A.util.isUndefinedOrNull(caseRecord)) {
                    helper.saveRecord(component, event); 
                }
            }
    	}
    },
    
})
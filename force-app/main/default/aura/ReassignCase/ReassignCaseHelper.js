({
    initReassignButton: function(component) {
        const currentUserId = $A.get("$SObjectType.CurrentUser.Id");
        let action = component.get("c.enableAssignButton");
        const recordId = component.get("v.recordId");
        //const caseRecord = component.get("v.caseRecord");
        //const rtName = caseRecord.RecordType.DeveloperName;
        //console.log('*** rtName: ' + rtName);
        action.setParams({caseId: recordId, userId: currentUserId});
        action.setCallback(this, response => {
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
            	console.log('*** result: ' + result);
            	component.set("v.enableButton", result);
            }
            else if (state === "ERROR") {
            	console.log('error');
            }
        });
    
        $A.enqueueAction(action);        
    },
    
    retrieveUsersRole:function(component) {
        const currentUserId = $A.get("$SObjectType.CurrentUser.Id");
        let action = component.get("c.roleInfoForUser");
        action.setParams({userId: currentUserId});
        action.setCallback(this, response => {
            const state = response.getState();
            if (state === "SUCCESS") {
                const result = response.getReturnValue();
                const key = Object.keys(result)[0];
                const roleName = result[key];
                component.set("v.userRoleId", key);
                component.set("v.userRoleName", roleName);
            }
            else if (state === "ERROR") {
                console.log('Error updating record: ' + response.getError());
        		this.toastError(component, response.getError());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);        
    },
 
    validateFieldAdmin: function(component) {
        console.log("In validateFieldAdmin " );
    	let valid = true;
    	const userRoleName = component.get("v.userRoleName");
        const kFieldAdminRoleName = "Field Admin";
        if(userRoleName === kFieldAdminRoleName) {
            this.fieldAdminInWorkgroup(component);
        }
    },
        
    fieldAdminInWorkgroup: function(component) {
        console.log("In fieldAdminInWorkgroup ");
    	let matched = false;   
    	const roleName = component.get("v.userRoleName");
    	const kFieldAdminRoleName = "Field Admin";
        if(roleName === kFieldAdminRoleName) {
            const caseRecord = component.get("v.caseRecord");           
         	const workgroupName = caseRecord.WorkGroup__c;
            const rtName = caseRecord.RecordType.DeveloperName;
            console.log('*** rtName: ' + rtName);
            console.log('*** workgroupName: ' + workgroupName);
            if(!$A.util.isUndefinedOrNull(workgroupName)) {
                // get the Queues for the current user
                let action = component.get("c.getAssignedQueuesForUser");
                console.log('lingesh'+$A.get("$SObjectType.CurrentUser.Id"));
                const role = $A.get("$SObjectType.CurrentUser.Id");
                action.setParams({userId : role});
                action.setCallback(this, function(response) {
                    let state = response.getState();
                    if (state === "SUCCESS") {
                        const results = response.getReturnValue();
                        for (let key in results) {
                            let queueInfo = results[key];
                            if(queueInfo.DeveloperName === workgroupName) {
                                matched = true;
                                break;
                            }
                       	}
                        if(!matched){
                            this.disableReassignButton(component, true);  
                            this.toastError(component, 'You cannot reassign this Case because you are not a member of the workgroup');
                        }else{
                             this.prepare(component);
                            this.disableReassignButton(component, true);
                        }
                   }
                });
              
                $A.enqueueAction(action);               
            }
        }        
    },
        
    prepare: function (component) {
        const kOopAgentRoleName = "OOP Agent";
        const kFieldAgentRoleName = "Field Agent";
        const kIntakeAgentRoleName = "Intake Agent";
        const currentUsersRole = component.get("v.userRoleName");        
        if(!$A.util.isUndefinedOrNull(currentUsersRole)) {
            if(currentUsersRole === kOopAgentRoleName || currentUsersRole === kIntakeAgentRoleName ) {
                component.set("v.mode", "auto");
                this.retrieveAutoAssignment(component);
            } 
            else if(currentUsersRole === kFieldAgentRoleName) {
                component.set("v.mode", "auto");
                this.retrieveFieldAgentAutoAssignment(component);
        	} 
            else {
                // otherwise show queue/user selection
                component.set("v.mode", "queue");
                this.populateQueues(component);
            }
        }
    },
    
    // default the queue menu for child or response record type
    defaultQueue: function(component, options) {
        const kChildCaseRecordTypeName = "OOPField";
        const kResponseCaseRecordTypeName = "OOPResponse";
        const caseRecord = component.get("v.caseRecord");
        const rtName = caseRecord.RecordType.DeveloperName;
        if(rtName === kChildCaseRecordTypeName || rtName == kResponseCaseRecordTypeName) {        
            const workgroup = caseRecord.WorkGroup__c;
            if(!$A.util.isUndefinedOrNull(workgroup)) {
                options.forEach(option=> {
                    if(option.details === workgroup) {
                        // set default and disable
                        const queueMenu = component.find("queueComboboxId");
                        const selectedQueueId = option.value;
                        queueMenu.set('v.disabled', true);
                        queueMenu.set("v.value", selectedQueueId);
                        this.processSelectedQueue(component, selectedQueueId);
                    } 
                }); 
            }
        }
    },
    
    processSelectedQueue: function(component, selectedQueueId) {
        component.set("v.queueId", selectedQueueId);
        this.disableReassignButton(component, false);
        this.populateUsers(component, selectedQueueId);
    },

    // assign case based on role matched in metadata
    retrieveAutoAssignment: function(component) {        
        const caseRecord = component.get("v.caseRecord"); 
    	const role = caseRecord.OwnersRole__c;
        
        let action = component.get("c.autoAssignedQueueForRole");        
        action.setParams({caseId: caseRecord.Id, inputRoleName: role});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                console.log("Record updated successfully");
               	$A.get('e.force:refreshView').fire();
            	this.toastSuccess(component);

                /*let result = response.getReturnValue();
                let key = Object.keys(result)[0];
                component.set("v.assigneeId", key);
                component.set("v.assigneeName", result[key]);
                component.set("v.queueId", key);
                //clear the userId
                component.set("v.userId", "");
                this.saveRecord(component);
                */
            }
            else if (state === "ERROR") {
                console.log('Error updating record: ' + response.getError());
        		this.toastError(component, response.getError());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);        
    },
    
    // assign case for Field Agent users
    retrieveFieldAgentAutoAssignment: function(component) {        
        const caseRecord = component.get("v.caseRecord"); 
       	const workgroup = caseRecord.WorkGroup__c;
        console.log('*** workgroup [' + workgroup + ']');

        //let action = component.get("c.autoAssignmentForFieldAgent");
        let action = component.get("c.autoAssignmentForFieldAgentFix");
        action.setParams({caseId: caseRecord.Id, workgroup: workgroup});
        action.setCallback(this, response => {
            const state = response.getState();
            if (state === "SUCCESS") {
                console.log("Record updated successfully");
               	$A.get('e.force:refreshView').fire();
            	this.toastSuccess(component);

            	/*const result = response.getReturnValue();
                if(!$A.util.isUndefinedOrNull(result)) {
                    component.set("v.assigneeId", result);
                    if(result.startsWith('00D')) {
                        component.set("v.queueId", result);
                        component.set("v.userId", "");
                    }
                    if(result.startsWith('005')) {
                        component.set("v.queueId", "");
                        component.set("v.userId", result);
                    }
                    
                    //this.saveRecord(component);
                } else {
                	console.log('*** No assignee found for auto assignment');   
                }
                */
            }
            else if (state === "ERROR") {
                console.log('Error updating record: ' + response.getError());
        		this.toastError(component, response.getError());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);        
    },
    
    	// load queues for current user
    populateQueues: function(component) {
        let items = [];
        const currentUserId = $A.get("$SObjectType.CurrentUser.Id");
        
        // get the Queues for the current user
        let action = component.get("c.getAssignedQueuesForUser");
        action.setParams({userId : currentUserId});
        action.setCallback(this, response => {
            let options = [];
            let state = response.getState();
            if (state === "SUCCESS") {
                const results = response.getReturnValue();
                for (let key in results) {
            		let queueInfo = results[key];
            		let item = {"label": queueInfo.Name, "value": key, "details": queueInfo.DeveloperName};
                    options.push(item);
                }
                component.set("v.queueList", options);
                this.defaultQueue(component, options);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
	},
    
    	// load users for selected queue
    populateUsers : function(component, selectedQueueId) {
        let items = [];
        
        // get the Users for the selected Queue
        let action = component.get("c.getUsersForQueue");
        action.setParams({queueId : selectedQueueId});
        action.setCallback(this, function(response) {
            let options = [];
            let state = response.getState();
            if (state === "SUCCESS") {
                let results = response.getReturnValue();
                for(var key in results) {
                    let item = {"label": results[key], "value": key};
                    options.push(item);
                }
                component.set("v.userList", options);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
	},
        
    saveRecord: function(component, event) {        
        // update the Case Owner to the selected User if defined
        // or the selected Queue
        const queueId = component.get("v.queueId");
        const userId = component.get("v.userId");
        let userOrGroupId = "";
        if(!$A.util.isUndefinedOrNull(userId) && userId) {
         	userOrGroupId = userId;   
        } else if(!$A.util.isUndefinedOrNull(queueId) && queueId) { 
         	userOrGroupId = queueId;   
       	}
                
       	// call Apex to update
        const caseRecord = component.get("v.caseRecord");
       	let updateAction = component.get("c.updateCaseOwner");
		updateAction.setParams({"caseId": caseRecord.Id, "userOrGroupId": userOrGroupId});
        updateAction.setCallback(this, response => {
            const state = response.getState();
            if(state == "SUCCESS"){
                console.log("Record updated successfully");
               	$A.get('e.force:refreshView').fire();
            	this.toastSuccess(component);
            }
            else if (state === "ERROR") {
                console.log('Error updating record: ' + response.getError());
        		this.toastError(component, response.getError());
            }
        
         	component.set("v.mode", "reset");
        });
        $A.enqueueAction(updateAction);
    },
    
        
    /*
     * saveRecord: function(component, event) {
        const caseRecordData = component.find("caseRecordData");
        const caseRecord = component.get("v.caseRecord"); 
        
        // update the Case Owner to the selected User if defined
        // or the selected Queue
        const queueId = component.get("v.queueId");
        const userId = component.get("v.userId");
        let userOrGroupId = "";
        if(!$A.util.isUndefinedOrNull(userId) && userId) {
         	userOrGroupId = userId;   
        } else if(!$A.util.isUndefinedOrNull(queueId) && queueId) { 
         	userOrGroupId = queueId;   
       	}
            
        caseRecord.OwnerId = userOrGroupId;

   		caseRecordData.saveRecord($A.getCallback(saveResult => {
      		if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Record updated successfully");
            	this.toastSuccess(component);
            } else if (saveResult.state === "ERROR") {
               	const error = JSON.stringify(saveResult.error);                 
                console.log('Error updating record: ' + error);
        		this.toastError(component, error.message);
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
            
 			component.set("v.mode", "reset");
        }));
	},
    */            
    toastSuccess: function(component) {
        const assigneeName = component.get("v.assigneeName");
        let message = 'Case successfully reassigned';
        if(assigneeName.length > 0) {
            message += ' to ' + assigneeName;
        }
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: 'success',
            message: message
        });
        toastEvent.fire();
    },
        
    toastError: function(component, message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: 'error',
            message: message
        });
        toastEvent.fire();
    },
        
    disableReassignButton: function(component, disable) {
        console.log("In disableReassignButton");
     	const button = component.find("reassignButtonId");
      	button.set('v.disabled', disable);
    }

})
({
    doInit : function(component, event, helper) {
        component.set("v.isLoading",true);
        var action = component.get("c.getPublishStatus");
        action.setParams({
            recordId : component.get("v.recordId") 
        });
        action.setCallback(this, function(response){
            component.set("v.isLoading",false);
            var resValue = response.getReturnValue();
            if(resValue == 'Archived') {
                helper.showToast('error','Archived Articles cannot be cloned','Error');
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
    cancel : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    cloneKnowledgeArticle : function(component, event, helper) {
        component.set("v.isLoading",true);
        var action = component.get("c.cloneArticle");
        action.setParams({
            recordId : component.get("v.recordId") 
        });
        action.setCallback(this, function(response){
            component.set("v.isLoading",false);
            var responseObj = response.getReturnValue();
            let state = response.getState();
            console.log('state: '+state);
            console.log('responseObj: '+responseObj);
            if (state === "SUCCESS") {
				var article = responseObj.split('-*-');
                helper.showToast('success','Knowledge Article '+article[0]+' created Successfully!','success');
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": article[1],
                    "slideDevName": "detail"
                });
                navEvt.fire();                
            } else {
                let errors = response.getError();
                let message = 'error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                    console.log('message: '+message);
                }
                if(message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION'))
                {
                message=message.substring(message.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 35);
                if(message.includes('No active author found/Invalid ATTUID: [ContentSponsor__c]'))
                {
                    message='The article cannot be cloned - No active author found or invalid ATTUID';
                }
                }    
                helper.showToast('error',message,'Error');
            }
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
    }
})
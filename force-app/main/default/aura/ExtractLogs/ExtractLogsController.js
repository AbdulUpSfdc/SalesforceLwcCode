({
    doInit: function(component, event, helper) {
       /* var action=component.get('c.getuserattid');   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.Attuid', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);*/
        /*var action1=component.get('c.checkpermission');
        action1.setParams({AttId:component.get('v.Attuid')});
        action1.setCallback(this, function(response) {
            var state1 = response.getState();
            if (state1 === "SUCCESS") {
                if(response.getReturnValue()==false){
                    component.set('v.show',false);
                }
            }
        });
        $A.enqueueAction(action1);*/
    },
    
    doAction : function(component, event, helper) {
        alert ('attid '+component.get('v.Attid'));
        alert ('start date1 '+component.get('v.starttime'));
        alert ('stop date1 '+component.get('v.stoptime'));
        
        var action=component.get('c.getLogs');   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.Attuid', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        
    }
})
({
    doInit : function(component, event, helper) {
        var action = component.get('c.getLoggedInUserInfo'); 
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                var userInfo = a.getReturnValue();
                console.log(userInfo.dueTodayListViewName);
                component.set('v.listViewNameDueToday', userInfo.dueTodayListViewName);
                
            }
        });
        $A.enqueueAction(action);
       
    }
})
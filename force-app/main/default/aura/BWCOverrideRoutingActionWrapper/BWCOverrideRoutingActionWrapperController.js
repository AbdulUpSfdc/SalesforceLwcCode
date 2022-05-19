({
    handleCaseUpdated : function(component, event, helper) {
        console.log('Closing quick action');
        $A.get('e.force:refreshView').fire();
    },

    handleUpdateSpinner : function(component, event, helper){
        var value = event.getParam('value');
        component.set("v.isLoading", value);
    }
})
({
    doInit : function(component, event, helper) {
        window.setTimeout(
            $A.getCallback(function(){
                var payload = {
                    show: 'true'
                };

                component.find('msgToNewCustomer').publish(payload);

                var closeAction = $A.get("e.force:closeQuickAction");
                closeAction.fire();
            }),500
        );
    }
})
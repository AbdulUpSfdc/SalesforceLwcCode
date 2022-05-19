({

    handleNewCustomerMessage : function(component, event, helper) {
        console.log('handleNewCustomerMessage');
        console.log(event.getParam('show'));
        let showPopup = event.getParam('show') === 'true';

        if(showPopup){
            helper.showOpusWindow(component, event, helper);
        }else{
            helper.closeOpusWindow(component, event, helper);
        }
    }

})
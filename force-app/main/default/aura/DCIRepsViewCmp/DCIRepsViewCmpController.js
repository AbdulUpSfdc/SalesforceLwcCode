({
    handleClick : function(component, event, helper) {
        var buttomClicked = event.getSource().get("v.name");
         component.set('v.buttonName',buttomClicked);
         console.log(buttomClicked);
       console.log('recordId'+component.get('v.recordId'));
         helper.updateStatus(component, event);
    },

    handleNextCustomer : function(component, event, helper) {

      helper.handleNextCustomer(component, event);
    },

    doInit : function(component, event, helper) {
      helper.init(component, event);
   }
})
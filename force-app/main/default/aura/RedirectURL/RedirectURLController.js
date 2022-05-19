({
  // init function here
   invoke : function(component, event, helper) {
    
        console.log("inside invoke function....");       

        var homeEvent = $A.get("e.force:navigateToURL");
        homeEvent.setParams({
        "url": component.get('v.redirectURL')
        });
        homeEvent.fire();       
       
    },
})
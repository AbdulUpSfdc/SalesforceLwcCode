({
    doInit : function(component, event, helper) {
      
      
      const closer =  $A.get("e.force:closeQuickAction");

      helper.getTSRMConfigs(component).then((result)=>{

        //console.log(result);
        component.set('v.TSRMConfigs',result);
      
      }).then((result)=>{
       helper.getRequest(component).then((result)=>{
       
        //console.log(result);
        helper.handleFetch(JSON.parse(component.get("v.TSRMConfigs")),result,helper,component,closer);
        helper.createActivity(component);

      }).then((result)=>{
        
      }).finally(()=>{
        

      });
    });



    },
})
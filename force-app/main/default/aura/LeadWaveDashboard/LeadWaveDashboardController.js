/**********************************************************

Component Name :  LeadWaveDashboard
Created By     :  nd7003
Description    :  SFDev - Lightning Component to Pass Check in Store Name to Einstein team
US#            :  SPTSLSATT-591 SFDev - Lightning Component to Pass Check in Store Name to Einstein team

************************************************************/

({
    doInit: function(component, event, helper) 
    {
         
        var action = component.get("c.getUserCurrentLocation");
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            
            if (state === "SUCCESS") {
                             
                component.set("v.user", response.getReturnValue());
                
                let userdetails = component.get("v.user");
                
                var  LeadStoreName = userdetails["storename"];
                
                console.log('LeadStoreName==>'+LeadStoreName);
                                                                          
                component.set("v.ProfileName", userdetails["userProfile"]);
                
                console.log('ProfileName==>'+component.get("v.ProfileName"));
                                                               
                var filterValue = {"datasets":{"LeadsByProduct":[{"fields":["RetailStore.Name"],"filter":{"operator":"matches","values":[LeadStoreName]}}]}}
                              					
				var filterJSON = JSON.stringify(filterValue);
                
                console.log('filterJSON==>'+filterJSON);
                
                component.set('v.filter', filterJSON);  
            }
        });
        $A.enqueueAction(action);                      
    }
    
})
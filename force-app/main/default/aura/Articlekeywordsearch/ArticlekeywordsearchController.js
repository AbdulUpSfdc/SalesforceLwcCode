({
    doInit: function(component, event, helper) {
        var action=component.get('c.getuserattid');   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.Attuid', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
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
        var Keyword = component.find('Keyword');
        var value = Keyword.get('v.value');
        var Attid = component.find('Attid');
        var value1 = Attid.get('v.value');
        console.log('Keyvalue '+value);
        var action1=component.get('c.checkpermission');
        action1.setParams({AttId:component.get('v.Attuid')});
        action1.setCallback(this, function(response) {
            var state1 = response.getState();
            //alert('show '+response.getReturnValue());
            if (state1 === "SUCCESS") {
                if(response.getReturnValue()==true){
                    if(value =='' || value=='Enter keyword' || value==null || value=='undefined') {
                        Keyword.set('v.validity', {valid:false, badInput :true});
                        Keyword.showHelpMessageIfInvalid();
                    }
                    else if(value1 =='' || value1=='Enter keyword' || value1==null || value1=='undefined') {
                        Attid.set('v.validity', {valid:false, badInput :true});
                        Attid.showHelpMessageIfInvalid(); 
                    }
                        else{
                            var action=component.get('c.InvokeBatch');
                            let button = event.getSource();
                            button.set('v.disabled',true);
                            action.setParams({SearchText:component.get('v.SearchText'), Attuid:component.get('v.Attuid')});   
                            action.setCallback(this, function(response) {
                                var state = response.getState();
                                var flag=false;
                                
                                if (state === "SUCCESS") {
                                    console.log('success');
                                    alert('Report Generation Submitted Successfully'); 
                                    if (state === "SUCCESS"){
                                        if(response.getReturnValue()==null){
                                            component.set('v.responseMsg','Batch failed with following errors'+ component.get('v.apexJob').NumberOfErrors);
                                            var toastEvent = $A.get("e.force:showToast");
                                            toastEvent.setParams({
                                                "title": "Error!",
                                                "message": "Batch failed with following No.errors: "+ component.get('v.apexJob').NumberOfErrors,
                                                "type" : "error",
                                                "mode": 'sticky'
                                            });
                                            toastEvent.fire();
                                        }
                                        else{
                                            
                                            var interval = setInterval($A.getCallback(function () {
                                                var jobStatus = component.get("c.getBatchJobStatus");
                                                ///alert(jobStatus);
                                                if(jobStatus != null){
                                                    //alert('1');
                                                    jobStatus.setParams({ jobID : response.getReturnValue()});
                                                    jobStatus.setCallback(this, function(jobStatusResponse){
                                                        var state = jobStatus.getState();
                                                        if (state === "SUCCESS"){
                                                            var job = jobStatusResponse.getReturnValue();
                                                            component.set('v.apexJob',job);
                                                            var processedPercent = 0;
                                                            if(job.JobItemsProcessed != 0){
                                                                processedPercent = (job.JobItemsProcessed / job.TotalJobItems) * 100;
                                                            }
                                                            var progress = component.get('v.progress');
                                                            component.set('v.progress', progress === 100 ? clearInterval(interval) :  processedPercent);
                                                            
                                                            
                                                            if(component.get('v.apexJob').Status=='Completed' && flag==false){
                                                                if(component.get('v.apexJob').NumberOfErrors==0){
                                                                    //component.set('v.responseMsg','Batch run is successful');
                                                                    var toastEvent = $A.get("e.force:showToast");
                                                                    toastEvent.setParams({
                                                                        "title": "Success!",
                                                                        "message": "Report is generated and sent to ATT mailbox",
                                                                        "type" : "success",
                                                                        "mode": 'sticky'
                                                                    });
                                                                    toastEvent.fire();
                                                                    //alert('Batch run is successful');
                                                                    let button = event.getSource();
                                                                    button.set('v.disabled',false);
                                                                    component.set('v.SearchText','');
                                                                }
                                                                else{
                                                                    component.set('v.responseMsg','Batch failed with following errors'+ component.get('v.apexJob').NumberOfErrors);
                                                                    var toastEvent = $A.get("e.force:showToast");
                                                                    toastEvent.setParams({
                                                                        "title": "Error!",
                                                                        "message": "Batch failed with following No.errors: "+ component.get('v.apexJob').NumberOfErrors,
                                                                        "type" : "error",
                                                                        "mode": 'sticky'
                                                                    });
                                                                    toastEvent.fire();
                                                                    //alert('Batch failed with following errors'+ component.get('v.apexJob').NumberOfErrors);
                                                                    
                                                                }
                                                                flag=true;  
                                                            }
                                                        }
                                                    });
                                                    $A.enqueueAction(jobStatus);
                                                }
                                            }), 2000);
                                        }}   
                                }
                                else{
                                    var errors=response.getError();
                                    alert('Error submitting the Form: '+errors[0].message);
                                }
                            });
                            $A.enqueueAction(action);
                        }
                    
                    
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "User does not have access to generate report",
                        "type" : "error",
                        "mode": 'sticky'
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action1);
        
        
        
    }
})
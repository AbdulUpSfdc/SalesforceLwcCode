({
    executeAction : function(component, helper, action, isMobileApp, callback) {
    
        var msgMobile = "Error in Sending Message: \n";
        var message ='';   
        return new Promise(function(resolve, reject) {
          action.setCallback(this, function(result) {      
            var state = result.getState();
            if (state === "SUCCESS"){           
                var data = result.getReturnValue();
                console.log("data is"+ JSON.stringify(data));
                resolve(data);
            }
            else{
                reject(new Error(result.getError()));
            }
          });
           
         $A.enqueueAction(action);
      })
    },


    
    resendSMS : function(component, event, helper, isMobileApp)  {
        var message = '';
        var msgMobile = "Error in Sending Message: \n";
        var recordId =  component.get("v.recordId");
        const $closeQuickAction = $A.get('e.force:closeQuickAction');

      
        var action= component.get("c.getMessage");
        action.setParams({"messagingMessageId" : component.get("v.recordId")});

        var messagePromise = this.executeAction(component, helper, action, isMobileApp);  
       
        messagePromise.then(
              function(result) {
                  console.log("Message Record -->" + JSON.stringify(result));
                  console.log(result.Was_Sent__c);
                  if(result.Was_Sent__c==true)
                  {
                    $closeQuickAction.fire();
                    component.set("v.showSpinner" , false);
                      var toastEvent=$A.get("e.force:showToast");
                      toastEvent.setParams({title:'SMS Already Released',
                                            message:'This message was already sent successfully.',
                                            type:'warning'
                                           });
                      toastEvent.fire();

                  }
                  if(result.Was_Sent__c==false)
                  {
                  helper.invokeOutboundFlow(component, event, helper, result, recordId, isMobileApp);
                  }
            }
        )
        .catch(
            function(error){
                 console.log('error in promise.....' + error);            
             }
        );
    },

    invokeOutboundFlow : function(component, event, helper, messageRecord, recordId, isMobileApp) {
        console.log("Input variables///////" + recordId + "///////" + JSON.stringify(messageRecord) + "////////" + isMobileApp);
        var inputVariables = [
                {
                    name : "leadId",
                    type: "String",
                    value: messageRecord.Lead__c
                },
                {
                    name: "msgContent",
                    type: "String",
                    value: messageRecord.Message_Content__c
                },               
                {
                  name: "MessageId",
                  type: "String",
                  value: recordId
                },
            ];
            var flow = component.find("flowMessage");
            flow.startFlow("RetailLeadSMSOutbound", inputVariables);                   
            console.log("Flow Completed" + component.get("v.SentMessageContent"));
     
      },
  
    handleFlowComplete : function(component, event) {  
        //Hide Flow Complete Message on UI   
        if(event.getParam("status") === "FINISHED_SCREEN") {
          component.set("v.flowNotCompleted" , false);
          component.set("v.showSpinner" , false);
          $A.get("e.force:closeQuickAction").fire()
          $A.get('e.force:refreshView').fire();   
        }  
      },


})
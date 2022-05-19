({
    handleError : function(errorMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": $A.get("$Label.c.Error"),
            "message": errorMessage,
            "type":"error"
        });
        toastEvent.fire();
    },

    handleActionError: function(response, helper) {
        if(response.getState() == 'ERROR') {
            let errors = response.getError();
            let message = $A.get("$Label.c.GenericError") +' '; // Default error message
            // Retrieve the error message sent by the server
            if (errors && Array.isArray(errors) && errors.length > 0) {
                for (var i = 0; i < errors.length; i++) { 
                    message += errors[i].message +', ';
                }
                message = message.slice(0, -2);
            }
            helper.handleError(message);
        }
    }
})
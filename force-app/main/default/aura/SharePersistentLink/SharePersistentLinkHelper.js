({
    getPersistentUrl: function(component) {
        
		let parentArticleId = component.get("v.recordId");
        let action = component.get("c.getPersistentLink");
        action.setParams({'articleId': parentArticleId});
        console.log("articleId: " + parentArticleId);
        action.setCallback(this, response => {
            
            let state = response.getState();
            let persistentURL = response.getReturnValue();
            //if the response is success
            if (state === "SUCCESS") {
            	console.log("Success with articleId: " + parentArticleId);
            	$A.get("e.force:closeQuickAction").fire();
                let copyText = document.createElement('input');
            	copyText.setAttribute("value", persistentURL);
            	document.body.appendChild(copyText);
            	copyText.select();
            	copyText.setSelectionRange(0, 99999)
            	document.execCommand("copy");
            	
            	//alert(" \r\nThis URL has been copied to the clipboard: \r\n  \r\n" + persistentURL);
            	var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'This URL has been copied to the clipboard: ' + persistentURL,
                    key: 'info_alt',
                    type: 'success',
                    mode: 'dismissible'
                });
                toastEvent.fire();
            }
            //if the response is error
            else {
                console.log("Failed with state: " + state);
            }
        
        });
        $A.enqueueAction(action);
    }
})
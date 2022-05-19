({
    // build the column list for the data table
    buildColumns: function(component) {
        //Person Account Name, BAN, Account Type, Billing Street, Billing Apt, Billing City, Billing State and Billing Zip
        component.set('v.columns', [
            {label: 'Person Account Name', fieldName: 'custName', type: 'text'},
            {label: 'BAN/CPID', fieldName: 'ban', type: 'text'},
            {label: 'Account Type', fieldName: 'accountType', type: 'text'},
            {label: 'Billing Street', fieldName: 'billingStreet', type: 'text'},
            {label: 'Billing City', fieldName: 'billingCity', type: 'text'},
            {label: 'Billing State', fieldName: 'billingState', type: 'text'},
            {label: 'Billing Zip', fieldName: 'billingZip', type: 'text'},
        ]);
    },
    
    // fill in the account info to display in the datatable        
    buildAccountList: function(component, ban, results) {
        let accountList = [];
        const foundAccounts = component.get("v.foundAccounts");
       	
		for(const junction of results) {
           	let info = {};
            
            // fill the default
            //- defaulting to retrieved Billing account BAN-> info.ban = ban;
            info.personAccountId = foundAccounts[0].personAccountId;

            const account = junction.Billing_Account__r;
            info.custName = account.First_Name__c + ' ' + account.Last_Name__c;
            info.billingStreet = account.Billing_Address_Line_1__c;
            info.billingCity = account.Billing_City__c;
            info.billingState = account.Billing_State__c;
            info.billingZip = account.Billing_Zipcode__c;
            info.accountType = account.Account_Type__c;
            /*if($A.util.isUndefinedOrNull(info.ban)) {
            	info.ban = account.Billing_Account_Number__c;
            }*/
            info.ban = account.Billing_Account_Number__c;
            
            accountList.push(info);
        }
        
        component.set("v.accountList", accountList);
        component.set("v.searching", false);
 	},
            
    // disable/enable the Save button
    disableSaveButton: function(component, disable) {
     	const button = component.find("saveButtonId");
      	button.set('v.disabled', disable);
    },
            
    // close the Quick Action that loaded us and refresh
    closeQuickAction: function() {
    	$A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
	},
   
    // callout to update case with account info
    updateCaseWithAccount: function(component, personAccountId, ban, searchProduct) {
		const caseId = component.get("v.recordId");
        let action = component.get("c.updateCaseWithAccount");
        action.setParams({'caseId': caseId, 
                          'ban': ban, 
                          'accountId': personAccountId,
                          'searchProduct': searchProduct});
        action.setCallback(this, response => {
            let state = response.getState();
            if (state === "SUCCESS") {
                console.log("Case updated successfully");
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Unknown error'; 
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
				this.toastError(component, message);           
            }
            else {
                console.log("Failed with state: " + state);
            }
        
            this.closeQuickAction();
        });
        $A.enqueueAction(action);
    },

    // display error message
 	toastError: function(component, message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: 'error',
            message: message
        });
        toastEvent.fire();
    },
        
    // callout to retrieve account information from either BAN or Person Account
  	retrieveAccountInfo: function(component, ban, personAccountId) {
		let action = component.get("c.getBillingAccountInfo");
        action.setParams({'ban': ban, 'accountId': personAccountId});
        action.setCallback(this, response => {
            let state = response.getState();
            if (state === "SUCCESS") {
				const results = response.getReturnValue();
            	console.log(results);
            	this.buildAccountList(component, ban, results);
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Unknown error'; 
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.log(message);            
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    } 
 
})
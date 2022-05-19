({
    fetchCustomerCaseCount: function(component) {
        const caseRecord = component.get("v.caseRecord");
        if(!$A.util.isUndefinedOrNull(caseRecord) && !$A.util.isUndefinedOrNull(caseRecord.Account)) {
            const customerName = caseRecord.Account.Name;
            const currentCaseId = caseRecord.Id;
            const billAcctId = caseRecord.Billing_Account__c;
            if(!$A.util.isUndefinedOrNull(customerName)) {
                let action = component.get("c.countOpenCasesForSameCustomer");
                action.setParams({accountName: customerName, currentCaseId: currentCaseId,caseBillingAcctId:billAcctId});
                action.setCallback(this, function(response) {
                    const state = response.getState();
                    if (state === "SUCCESS") {
                        component.set("v.customerCaseCount", response.getReturnValue());
                    }
                    else if (state === "INCOMPLETE") {
                    }
                    else if (state === "ERROR") {
                        const errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
                });
                $A.enqueueAction(action);
            }
        }
    },

})
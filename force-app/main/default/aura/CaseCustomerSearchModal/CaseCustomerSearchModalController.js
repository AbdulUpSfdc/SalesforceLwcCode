({
    doInit: function(component, event, helper) {
        helper.buildColumns(component);
    },
    
    // results were found by the BWC Customer Search component
    handleRecordFound: function(component, event, helper) {
		let account = event.getParam('account');
        console.log('Found account:' + JSON.stringify(account));
        let accounts = [account];
		component.set("v.foundAccounts", accounts);
        
        let ban;
        const inputBanKey = 'searchInputBAN';
        if(account.hasOwnProperty(inputBanKey)) {
            let inputBan = account[inputBanKey];
            if(!$A.util.isUndefinedOrNull(inputBan)) {
               ban = inputBan;
          	}
        }
		
		helper.retrieveAccountInfo(component, ban, account.personAccountId);  

		/*
		 * Found account:{"urlPath":"https://attone--ctci.lightning.force.com/lightning/r/Account/001030000057ag7AAA/view",
		 * "street":null,"status":"Active","state":null,"product":null,"personAccountId":"001030000057ag7AAA",
		 * "Id":"633011194","email":"MYATT.TESTING@ATT.COM","custName":"IPTVHSIADATA DONOTUSE",
		 * "city":null,"ban":"633011791","acctNum":"633011194","accountType":"UVERSE",
		 * "searchInputBAN":"633011791"}        
		 */

	},
    
    // prevent selection of multiple rows
    handleRowSelect: function(component, event, helper) {
    	const selectedRows = event.getParam('selectedRows'); 
        const dataTable = component.find("dataTableId");
        if(selectedRows.length == 1) {
            //dataTable.set("v.errors", NULL);
            helper.disableSaveButton(component, false);
        } else {
            //dataTable.set("v.errors", {table:{title:["Please select a single row"]}});
            helper.disableSaveButton(component, true);
        }

    },
    
    // update the case with the selected row
    handleSaveClick: function(component, event, helper) {
        const accountTable = component.find("dataTableId");
        const selectedRows = accountTable.getSelectedRows();
        if (selectedRows && selectedRows.length) {
            const accountId = selectedRows[0].personAccountId;
            const ban = selectedRows[0].ban;
            const searchProduct = selectedRows[0].accountType;
            helper.updateCaseWithAccount(component, accountId, ban, searchProduct);
        }
 	}, 
    
    // cancel
    handleCancelClick: function(component, event, helper) {
        helper.closeQuickAction();
    }

})
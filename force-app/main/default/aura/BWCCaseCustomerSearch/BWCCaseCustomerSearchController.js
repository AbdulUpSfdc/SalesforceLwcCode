({
	handleRecordFound : function(component, event, helper) {
		let account = event.getParam('account');
        console.log('Found account:' + JSON.stringify(account));

        // account will have these fields
        // {"urlPath":"https://attone--c360.lightning.force.com/lightning/r/Account/0013K00000RMaFJQA1/view","street":null,"status":"Active","state":null,"product":null,"personAccountId":"0013K00000RMaFJQA1","Id":"200807164169949","email":"myatt.testing@att.com","custName":"CHERYL EDMONDSON","city":null,"ban":"200807164169949","acctNum":"200807164169949","accountType":"dtvnow","searchInputBAN":"200807164169949"}
        // Determine what to do with this account.
        // 
        
	}
})
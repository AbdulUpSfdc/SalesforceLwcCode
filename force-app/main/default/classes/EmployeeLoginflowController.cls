public without sharing class EmployeeLoginflowController {

    public list<EmployeeStoreRetail__c> listEmployeeStore {get; set;}
    public list<Employee__c> objCurrEmployee {get; set;}
    public boolean hasMessageToDisplay {get; set;}
    public String strSelectedValue {get; set;}
    public string strCurrUserName {get; set;}
    public list<SelectOption> listStoreOptions {get; set;}
    public boolean IsValidForCertCheck {get; set;}
    //used for debug screen
    public boolean showDebugButton {get; set;}
    public boolean debugScreenToggle {get; set;}
    public string urlJsonP {get; set;}
    public string urlDebug {get; set;}
    public virtual class testException extends Exception {}
    public String isIpadOS { public get; public set; }
    // a constant for unknown Browser or OS
    public String message { private set; public get; }
    @TestVisible public transient String relay {
        public get {

            MTLS_Detail__mdt  mahalo = MTLS_Detail__mdt.getInstance('Default');

            String expiration = String.valueOf(
                DateTime.now()
                        .addMinutes(3)
                        .getTime() / 1000L
            );

            String md5 = EncodingUtil.base64Encode(
                Crypto.generateDigest(
                    'MD5',
                    Blob.valueOf(
                        ApexPages.currentPage().getHeaders().get('USER-AGENT')
                        + ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP')
                        + expiration
                        + ' '
                        + mahalo.UUID__c
                    )
                )
            ).replace('+','-')
             .replace('/','_')
             .remove('=');

            return mahalo.Proxy_Endpoint__c
                   + '?md5='
                   + md5
                   + '&expires='
                   + expiration;
        }
        private set;
    }
    public transient String cypherText { public get; public set; }
    @TestVisible public boolean hasTerminal { public get; private set; }
	@TestVisible private String terminal = null;
    @TestVisible private Boolean mTLS = false;
    //constructor
    public EmployeeLoginflowController () {
        this.isIpadOS = '';
        this.IsValidForCertCheck = MTLS_Rollout_Indicator__c.getInstance()?.IsRolloutAvailable__c;
        this.showDebugButton = MTLS_Rollout_Indicator__c.getInstance()?.Enable_Debug__c;
        this.debugScreenToggle = False;
        this.urlJsonP = MTLS_Detail__mdt.getInstance('Default')?.Debug_JSONP__c;
        this.urlDebug = MTLS_Detail__mdt.getInstance('Default')?.Debug_url__c;
        reset(null);
    }
    public transient boolean allows_mTLS {
        public get {
			Boolean returnValue = true;

            return returnValue;
        }

        private set;
    }

    private void reset(String message) {
        //this.authStatusId = null;
        //this.counter = 5000;
        //this.granted = false;
        //this.pending = false;
        this.message = message;
    }
    public PageReference doMahalo() {
        try {


            MTLS_Detail__mdt  MTLS_Detail = MTLS_Detail__mdt.getInstance('Default');

            Map<String,String> m = MTLS_Service.getVerify(MTLS_Detail, this.cypherText);

            if(m.containsKey('message')){
                this.mTLS = false;
                this.message = m.get('message');
                if(test.isRunningTest()){
                    throw new testException('Forcing exception for testClass');
                }
                return null;
            }
            if (m.containsKey('verify') && m.get('verify').equals('SUCCESS')) {
                system.debug('Verified:');
                this.terminal = m.get('fingerprint');
                this.message = null;
                this.mTLS = true;
                return null;
            }

            this.mTLS = false;

        } catch (System.Exception e) {
            reset(
                     e.getLineNumber() + ':' + e.getMessage() + ':' + e.getStackTraceString()
            );
            Logger.error('EmployeeLoginflowController: ',e);
        } finally {
            Id HomeStoreLocation = (objCurrEmployee ==null)?null:objCurrEmployee[0]?.HomeStoreLocation__c;

            if (HomeStoreLocation <> null && objCurrEmployee[0]?.NumberOfAssociatedStores__c == 1) { // Only if one store is associated w/ Employee
                try {
                    return FinalizeRetailUserLogin(HomeStoreLocation);
                } catch (exception e) {
                    setErrorMessage(e.getMessage());
                }
                // Use Case - More than one store associated with employee
            }
            Logger.saveLog();
        }

        return null;
    }
    public PageReference doMTLSError() {
        this.message = System.Label.VFLoginFlowUnableTo;
        return null;
    }
    public PageReference doLogout() {
        // Initiated when user clicks on logout link

        PageReference refLogout = new PageReference ('/secur/logout.jsp');
        refLogout.setRedirect(true);
        refLogout.setRedirectCode(302);
        return refLogout;
    }
    public PageReference FinalizeRetailUserLogin(Id HomeStoreLocation) {
        List<Id> listStoreLocation = new list<Id>();
        listStoreLocation.add(HomeStoreLocation);

        // Set cache value for the current store in context of current employee
        StoreController.putStoreInCache(String.valueof(HomeStoreLocation));
        // Set User Location Custom setting value
        UserLocationTrace.putUserLocationInCustomSetting(listStoreLocation);
        // Redirect to leads listview
        PageReference LeadsView = Auth.SessionManagement.finishLoginFlow();
        LeadsView.setRedirect(false);

        if(this.IsValidForCertCheck){
            if(!this.mTLS){
                LeadsView = null;
                doMTLSError();
            }
        }
        return LeadsView;
    }
    public PageReference doInitialCheck() {
        //Check current employee store record

        //Instantiate variables
        listStoreOptions = new list<SelectOption>();
        List<Id> listStoreLocation = new list<Id>();
        String UserId;
        hasMessageToDisplay = false; // No error messages to display in the beginning
        // Get current UserId for the logged in User session in the login flow context
        if(!TEST.isRunningTest()){UserId = Auth.SessionManagement.getCurrentSession().get('UsersId');strCurrUserName = Auth.SessionManagement.getCurrentSession().get('Username');}
        try {
            // Find current employee record; If record doesn't exist, it will throw error and be caught
            objCurrEmployee = [SELECT Id, HomeStoreLocation__c, NumberOfAssociatedStores__c, FirstName__c, LastName__c  FROM Employee__c
                               WHERE User__c = :UserId WITH SECURITY_ENFORCED];
            if (objCurrEmployee[0] <> null ) { // Employee Record identified

                String strEmployeeId = objCurrEmployee[0]?.Id;
                // Use Case - Only when associated with one store only
                Id HomeStoreLocation = objCurrEmployee[0]?.HomeStoreLocation__c;
                if (HomeStoreLocation <> null && objCurrEmployee[0]?.NumberOfAssociatedStores__c == 1) { // Only if one store is associated w/ Employee
                    strSelectedValue = HomeStoreLocation;
                    if(!this.IsValidForCertCheck){
                        return FinalizeRetailUserLogin(HomeStoreLocation);
                    }
                }
                else if(HomeStoreLocation <> null && objCurrEmployee[0]?.NumberOfAssociatedStores__c > 1) {
                    // This query should not throw error since Rollup summary value was checked for the employee
                    listEmployeeStore = [SELECT Id, Store__c, StoreName__c  FROM EmployeeStoreRetail__c
                                         WHERE Employee__c =:strEmployeeId AND IsExpired__c <> TRUE WITH SECURITY_ENFORCED ];
                    if (listEmployeeStore <> null) {
                        for (EmployeeStoreRetail__c iter : listEmployeeStore) {
                            SelectOption unitOpt = new SelectOption(iter.Store__c, iter.StoreName__c);
                            listStoreOptions.add(unitOpt);
                            // setting default store as homestore
                            if (HomeStoreLocation == iter.Store__c) {
                                strSelectedValue = iter.Store__c;
                            }
                        }
                    }
                }
            } else {
                setErrorMessage(MTLS_Constants.NO_VALID_STORE_ERROR);
            }
        } catch (exception e) {
            setErrorMessage(MTLS_Constants.NO_VALID_EMPLOYEE_ERROR);
            Logger.error('EmployeeLoginflowController: ',e);
        } finally {
            Logger.saveLog();
        }
        //return to current flow
        return null;
    }
    public PageReference toggleDebug(){

        debugScreenToggle = !debugScreenToggle;
        return null;
    }
    public PageReference doUpdatePostSelection() {
        try {
            Id SelectedHomeStoreId = Id.valueof(strSelectedValue);
             return FinalizeRetailUserLogin(SelectedHomeStoreId);

        } catch (exception e) {
            setErrorMessage(e.getMessage());
        }
        return null;
    }
    public PageReference loadCurrentPage() {
        PageReference currPage = ApexPages.currentPage();
        currPage.setRedirect(false);
        return currPage;
    }
    private void setErrorMessage(String Message) {
        hasMessageToDisplay = true;
        ApexPages.getMessages()?.clear();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.valueof(Message)));
    }
}
/*-----------------------------------------------------------------------------
Test Data Factory Class reposible for creating all the test data required for
test classes associated with BWC project.

History
<Date>       <Authors Name>     <Brief Description of Change>

-----------------------------------------------------------------------------*/
@isTest
public class BWC_TestDataFactory {
    /* No need to pass Record type. BWC project only work on Person Account
     @return personAccount
    */
    public static Account createAccount() {
        Account acctObj = new Account();
        acctObj.BillingCity = 'Dallas';
        acctObj.BillingCountry = 'United States';
        acctObj.BillingCountryCode = 'US';
        acctObj.BillingPostalCode = '75462';
        acctObj.BillingStreet = '123 Test Dr';
        acctObj.Employee__c = false;
        acctObj.FirstName = 'Natasha';
        acctObj.Global_ID__c = '2544948781';
        acctObj.Interactions_in_Last_30_Days__c = 2;
        acctObj.LastName = 'Romanov';
        acctObj.PersonEmail = 'test@somewhere.com';
        acctObj.Phone = '(555) 111 222 3333';
        acctObj.Primary_BAN__c = '423432423';
        acctObj.Primary_Product__c = 'Wireless';
        acctObj.RecordTypeId = getRecordTypeIdByName(BWC_Constants.PERSON_ACCOUNT, 'Account');
        acctObj.ShippingCity = 'Dallas';
        acctObj.ShippingCountry = 'United States';
        acctObj.ShippingCountryCode = 'US';
        acctObj.ShippingPostalCode = '75462';
        acctObj.ShippingStreet = '123 Test Dr';
        insert acctObj;
        return acctObj;
    }

    public static Account createBSSeAccount() {
        Account acctObj = new Account();
        acctObj.BillingCity = 'Dallas';
        acctObj.BillingCountry = 'United States';
        acctObj.BillingCountryCode = 'US';
        acctObj.BillingPostalCode = '75462';
        acctObj.BillingStreet = '123 Test Dr';
        acctObj.Employee__c = false;
        acctObj.FirstName = 'Natasha';
        acctObj.Global_ID__c = '2544948781';
        acctObj.Interactions_in_Last_30_Days__c = 2;
        acctObj.LastName = 'Romanov';
        acctObj.PersonEmail = 'test@somewhere.com';
        acctObj.Phone = '(555) 111 222 3333';
        acctObj.Primary_BAN__c = '423432423';
        acctObj.Primary_Product__c = 'Wireless';
        acctObj.RecordTypeId = getRecordTypeIdByName(BWC_Constants.PERSON_ACCOUNT, 'Account');
        acctObj.ShippingCity = 'Dallas';
        acctObj.ShippingCountry = 'United States';
        acctObj.ShippingCountryCode = 'US';
        acctObj.ShippingPostalCode = '75462';
        acctObj.ShippingStreet = '123 Test Dr';
        acctObj.PersonMailingPostalCode = '12345';
        acctObj.Individual_ID__c = 'eb407049-c555-46fa-9bf2-010bcfa6333a';
        acctObj.Is_Digital_Customer__c = true;
        insert acctObj;
        return acctObj;
    }

    public static Adjustment__c createAdjustment() {
        // Create a new billing account, case, adjustment, and adjustment line item for testing purposes
        // Create approvers for testing purposes
        User manager = createEmployeeWithManager();

        Billing_Account__c billingAccount = new Billing_Account__c(
            Billing_Account_Number__c = '177057327797',
            External_Id__c = 'Consumer|000000000000',
            Account_Type__c = 'Wireless',
            Billing_Market__c = 'DLS'
        );
        insert billingAccount;

        Case testCase = new Case(
            Type = 'Billing | Adjustment',
            Status = 'New',
            Response__c = 'Not Required',
            Billing_Account__c = billingAccount.Id
        );
        insert testCase;

        Adjustment__c testAdjustment = new Adjustment__c(
            Status__c = 'New',
            Case__c = testCase.Id,
            Channel__c = 'Digital Life',
            Sub_Channel__c = 'Digital Life',
            Billing_Account__c = billingAccount.Id,
            Manager__c = manager.Id,
            Delegate_1__c = manager.ManagerId,
            Decision_Update_Transaction_ID__c = 'TDATA-2d69bea0-5801-4f51-b65b-5c9eeb1323a0'
        );

        System.runAs(manager) {
            insert testAdjustment;
        }

        Adjustment_Line_Item__c testLineItem = new Adjustment_Line_Item__c(
            Adjustment__c = testAdjustment.Id,
            Requested_Amount__c = 405,
            Agent_Adjusted_Amount__c = 405,
            Adj_Reason_System_Code__c = 'CRTSYA',
            Adjustment_Type__c = 'Goodwill',
            CDE_Product_Level_Id__c = '1'
        );

        System.runAs(manager) {
            insert testLineItem;
        }

        return testAdjustment;
    }

    /*  Method is used to create Billing Account based on Record type pass and
        link the billing account to person account via Customer Account
        relationship object

        Object record created for
        Billing_Account__c
        Customer_Account_Relation__c

        @return Billing_Account__c
    */
    public static Billing_Account__c createBillingAccount(String recordTypeName, Account acct) {
        Date mydate = System.Today();
        Billing_Account__c billAcctObj = new Billing_Account__c();
        billAcctObj.Account_Status__c = 'S';
        billAcctObj.Account_Type__c = recordTypeName;
        billAcctObj.Billing_Account_Number__c = '423432423';
        billAcctObj.Billing_Market__c = 'NBI';
        billAcctObj.Billing_Address_Line_1__c = '123 Test Dr';
        billAcctObj.Billing_Address_Line_2__c = '123 Test Dr';
        billAcctObj.Billing_City__c = 'Dallas';
        billAcctObj.Billing_State__c = 'TX';
        billAcctObj.Billing_Zipcode__c = '75462';
        billAcctObj.Service_Address_Line_1__c = '123 Test Dr';
        billAcctObj.Service_Address_Line_2__c = '123 Test Dr';
        billAcctObj.Service_City__c = 'Dallas';
        billAcctObj.Service_State__c = 'TX';
        billAcctObj.Service_Zipcode__c = '75462';
        billAcctObj.BMG_Contract_Type__c = '';
        billAcctObj.Contact_Number__c = '(555) 111 222 3333';
        billAcctObj.CPNI_Preference__c = '';
        billAcctObj.CustomerID__c = '123';
        billAcctObj.Customer_Liability__c = 'Value 1';
        billAcctObj.Customer_Since__c = mydate.addYears(-5);
        billAcctObj.Device_Protection_Plan__c = 'No';
        billAcctObj.DigitalLife__c = false;
        billAcctObj.Email__c = 'test@somewhere.com';
        billAcctObj.Enrolled_in_Large_Print__c = false;
        billAcctObj.FAN_Category__c = '3423';
        billAcctObj.Fan_Name__c = '';
        billAcctObj.FAN_Number__c = '1234567';
        billAcctObj.FAN_Sub_Category_2__c = '242214';
        billAcctObj.FAN_Sub_Category_3__c = '242214';
        billAcctObj.FAN_Sub_Category_4__c = '242214';
        billAcctObj.First_Name__c = 'Natasha';
        billAcctObj.Fixed_Wireless_Internet__c = false;
        billAcctObj.Is_Employee__c = false;
        billAcctObj.Language_Preference__c = 'English';
        billAcctObj.Last_Name__c = 'Romanov';
        billAcctObj.Retail_Serviceable__c = false;
        billAcctObj.Security_Level__c = '';
        billAcctObj.Security_Question__c = '';
        billAcctObj.Service_Start_Date__c = mydate.addYears(-5);
        billAcctObj.UserID__c = 'johnatt@slid.dum';
        billAcctObj.Visually_Impaired__c = false;

        insert billAcctObj;

        //now create Customer_Account_Relation__c record to related
        Customer_Account_Relation__c carObj = new Customer_Account_Relation__c();
        carObj.Billing_Account__c = billAcctObj.Id;
        carObj.Customer__c = acct.Id;
        insert carObj;

        return billAcctObj;
    }

    public static Plan__c createPlan(String recordTypeName, Billing_Account__c billAcctObj) {
        Plan__c plan = new Plan__c();
        plan.Account_Status__c = 'Active';
        plan.Account_Type__c = recordTypeName;
        plan.Billing_Account__c = billAcctObj.Id;
        plan.Contract_End_Date__c = System.Today().addYears(2);
        plan.Device_Protection__c = false;
        plan.Highest_Available_Speed__c = '47.6 GB';
        plan.Limit__c = '';
        plan.Monthly_Cost__c = 56.0;
        plan.Number_Of_Add_Ons__c = 6;
        plan.Number_Of_Lines__c = 6;
        plan.Number_Of_Receivers__c = 8.0;
        plan.Phone__c = '';
        plan.Plan_Name__c = 'AT&T Unlimited Plus Multi Line';
        plan.Plan_Unique_Name__c = 'a2B3K000000HoT3UAKAT&T Unlimited Plus Multi Line';
        plan.Product__c = 'DIRECTV';
        plan.Usage__c = '47.6 GB';

        insert plan;
        return plan;
    }

    public static User createEmployeeWithManager() {
        // Creating users
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User managerOne = new User(
            Alias = 'jdoe',
            Email = 'johndoe@salesforce.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Doe',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'johndoe+att@salesforce.com'
        );
        insert managerOne;

        User delOne = managerOne.clone();
        delOne.Alias = 'ddoe';
        delOne.Email = 'dylandoe@salesforce.com';
        delOne.UserName = 'dylandoe+att@salesfore.com';
        insert delOne;

        managerOne.ManagerId = delOne.Id;
        update managerOne;

        // Creating employees
        List<Employee__c> newEmps = new List<Employee__c>();

        Employee__c emp = new Employee__c();
        emp.Name = 'John Doe';
        emp.Organization__c = 'Centers';
        emp.Channel__c = 'Collections';
        emp.Channel1__c = 'Collections';
        emp.Sub_Channel__c = 'Collections';
        emp.EmployeeId__c = 'jdoe1234';
        emp.User__c = managerOne.Id;
        emp.Manager__c = delOne.Id;
        newEmps.add(emp);

        Employee__c man = emp.clone();
        man.Name = 'Dylan Doe';
        emp.EmployeeId__c = 'ddoe1234';
        man.User__c = delOne.Id;
        man.Manager__c = managerOne.Id;
        newEmps.add(man);

        insert newEmps;
        return managerOne;
    }

    // createEquipment should now return Asset object as equipments are stored in Asset object
    // to create Asset object, Account Id is also needed.
    public static Asset createEquipment(
        String recordTypeName,
        Account acctObj,
        Billing_Account__c billAcctObj,
        Plan__c planObj
    ) {
        Asset equipment = new Asset();
        equipment.AccountId = acctObj.Id;

        // set Asset name same as Phone Number.
        equipment.Name = '4056553566';
        equipment.Billing_Account__c = billAcctObj.Id;
        equipment.Device_Protection__c = true;
        equipment.Device_Type__c = 'Digital';
        equipment.Device__c = 'Apple Iphone';
        equipment.Equipment_Unique_Identifier__c = 'a2B3K000000HoT3UAK4056553566';
        equipment.Group_ID__c = '65432';
        equipment.Installments_Amount__c = 23.67;
        equipment.Installment__c = '23 Remaining';
        equipment.Is_Primary__c = true;
        equipment.Phone_Number__c = '4056553566';
        equipment.Receiver_Model__c = 'IRD-Advanced';
        equipment.Receiver_Type__c = 'Genie Mini';
        equipment.Room__c = 'LIVING RM';
        equipment.SerialNumber = '34567884994';
        equipment.Status = 'Active';
        equipment.Technology__c = 'Residential Gateway';
        equipment.Type__c = '';
        equipment.Upgrade__c = false;
        equipment.User__c = 'John King';
        equipment.Warranty__c = 'Expired';
        if (planObj != null) {
            equipment.Plan__c = planObj.Id;
        }

        insert equipment;
        return equipment;
    }

    public static String getRecordTypeIdByName(String recordTypeName, String obj) {
        String Id = [SELECT id FROM RecordType WHERE Name = :recordTypeName AND SobjectType = :obj].Id;
        return Id;
    }

    public static BWC_MakePayment.MakePaymentRequest createMakePaymentRequest() {
        BWC_MakePayment.PaySource paySource = new BWC_MakePayment.PaySource();
        paySource.sourceLocation = 'TestSourceLoc';
        paySource.sourceSystem = 'TestSourceSys';
        paySource.sourceUser = 'TestSourceUser';

        BWC_MakePayment.PromiseToPay promToPay = new BWC_MakePayment.PromiseToPay();
        promToPay.method = 'TestMethod';

        BWC_MakePayment.PaymentProfile payProfile = new BWC_MakePayment.PaymentProfile();
        payProfile.paySource = paySource;
        payProfile.profileOwnerId = 'TestProfileOwnnerId';
        payProfile.profileName = 'TestProfileName';
        payProfile.merchantId = '';
        payProfile.securityCode = '784589';

        BWC_MakePayment.BillingAddress billAddr = new BWC_MakePayment.BillingAddress();
        billAddr.zipCode = '78458';

        BWC_MakePayment.Card card = new BWC_MakePayment.Card();
        card.cardNumber = '589647589';
        card.expireMonth = 'TestExpMnth';
        card.expireYear = 'TestExpYr';
        card.securityCode = 'TestSecCode';
        card.cardHolderName = 'TestCardHolderName';
        card.billingAddress = billAddr;
        card.merchantId = '';
        card.cardMethodType = 'TestMethodType';
        card.cardType = 'TestCardType';

        BWC_MakePayment.BankAccount bankAcct = new BWC_MakePayment.BankAccount();
        bankAcct.bankAccountNumber = '9876';
        bankAcct.routingNumber = '45789';
        bankAcct.accountType = 'TestAcctType';
        bankAcct.accountHolderName = 'TestAcctHolderName';

        BWC_MakePayment.PaymentMethod payMethod = new BWC_MakePayment.PaymentMethod();
        payMethod.type = 'TestType';
        payMethod.bankAccount = bankAcct;
        payMethod.card = card;
        payMethod.paymentProfile = payProfile;
        payMethod.promiseToPay = promToPay;

        list<BWC_MakePayment.PaymentItemRequest> mpirList = new List<BWC_MakePayment.PaymentItemRequest>();
        BWC_MakePayment.PaymentItemRequest mpir = new BWC_MakePayment.PaymentItemRequest();
        mpir.sequenceNumber = 'TestSeqNum';
        mpir.amount = '234';
        mpir.profileName = 'TestProfile';
        mpir.savePaymentProfile = true;
        mpir.futurePaymentDate = 'TestFPD';
        mpir.paymentItemCategory = 'TestPmtCat';
        mpir.preAssignedServiceHandle = 'TestSH';
        mpir.invoiceNumber = '34567';
        mpir.paymentMethod = payMethod;
        mpir.enrollInAutopay = true;
        mpirList.add(mpir);

        list<BWC_MakePayment.MakePaymentAccountRequest> mparList = new List<BWC_MakePayment.MakePaymentAccountRequest>();
        BWC_MakePayment.MakePaymentAccountRequest mpar = new BWC_MakePayment.MakePaymentAccountRequest();
        mpar.accountNumber = '15689';
        mpar.accountType = 'TestAcctType';
        mpar.firstName = 'TestFN';
        mpar.lastName = 'TestLN';
        mpar.systemId = 'TestSysId';
        mpar.divisionId = 'TestDivId';
        mpar.makePaymentItemRequest = mpirList;
        mparList.add(mpar);

        BWC_MakePayment.MakePaymentRequest mpr = new BWC_MakePayment.MakePaymentRequest();
        mpr.locationId = 'Texas';
        mpr.sourceBusinessUnit = 'TestBU';
        mpr.customerAgreement = 'TestAgreement';
        mpr.appName = 'TestApp';
        mpr.sourceSystem = 'TestSource';
        mpr.sourceLocation = 'TestSourceLoc';
        mpr.sourceUser = 'TestSourceUser';
        mpr.idempotencyKey = 'TestIdempotencyKey';
        mpr.convenienceFee = 'TestConvenienceFee';
        mpr.tncId = 123;
        mpr.autopayTncId = 456;
        mpr.autopayCustomerAgreement = 'TestAutoPayCA';
        mpr.storeTermsConditionConsent = true;
        mpr.transactionId = 'TestTransactionId';
        mpr.confirmationAddtionalInformation = new List<String>{ 'TestAI1', 'TestAI2' };
        mpr.makePaymentAccountRequest = mparList;

        return mpr;
    }

    public static BWC_MakePayment.UpdatePaymentRequest createUpdatePaymentRequest() {
        list<BWC_MakePayment.PendingPaymentId> listPId = new List<BWC_MakePayment.PendingPaymentId>();
        BWC_MakePayment.PendingPaymentId pid = new BWC_MakePayment.PendingPaymentId();
        pid.pendingPaymentId = 'TestPPID';
        listPId.add(pid);

        BWC_MakePayment.BankAccount bankAcct = new BWC_MakePayment.BankAccount();
        bankAcct.bankAccountNumber = '9876';
        bankAcct.routingNumber = '45789';
        bankAcct.accountType = 'TestAcctType';
        bankAcct.accountHolderName = 'TestAcctHolderName';

        BWC_MakePayment.BillingAddress billAddr = new BWC_MakePayment.BillingAddress();
        billAddr.zipCode = '78458';

        BWC_MakePayment.Card card = new BWC_MakePayment.Card();
        card.cardNumber = '589647589';
        card.expireMonth = 'TestExpMnth';
        card.expireYear = 'TestExpYr';
        card.securityCode = 'TestSecCode';
        card.cardHolderName = 'TestCardHolderName';
        card.billingAddress = billAddr;
        card.merchantId = '';
        card.cardMethodType = 'TestMethodType';
        card.cardType = 'TestCardType';

        BWC_MakePayment.PromiseToPay promToPay = new BWC_MakePayment.PromiseToPay();
        promToPay.method = 'TestMethod';

        BWC_MakePayment.PaySource paySource = new BWC_MakePayment.PaySource();
        paySource.sourceLocation = 'TestSourceLoc';
        paySource.sourceSystem = 'TestSourceSys';
        paySource.sourceUser = 'TestSourceUser';

        BWC_MakePayment.PaymentProfile payProfile = new BWC_MakePayment.PaymentProfile();
        payProfile.paySource = paySource;
        payProfile.profileOwnerId = 'TestProfileOwnnerId';
        payProfile.profileName = 'TestProfileName';
        payProfile.merchantId = '';
        payProfile.securityCode = '784589';

        BWC_MakePayment.PaymentMethod payMethod = new BWC_MakePayment.PaymentMethod();
        payMethod.type = 'TestType';
        payMethod.bankAccount = bankAcct;
        payMethod.card = card;
        payMethod.paymentProfile = payProfile;
        payMethod.promiseToPay = promToPay;

        list<BWC_MakePayment.PaymentItemRequest> mpirList = new List<BWC_MakePayment.PaymentItemRequest>();
        BWC_MakePayment.PaymentItemRequest mpir = new BWC_MakePayment.PaymentItemRequest();
        mpir.sequenceNumber = 'TestSeqNum';
        mpir.amount = '234';
        mpir.profileName = 'TestProfile';
        mpir.savePaymentProfile = true;
        mpir.futurePaymentDate = 'TestFPD';
        mpir.paymentItemCategory = 'TestPmtCat';
        mpir.preAssignedServiceHandle = 'TestSH';
        mpir.invoiceNumber = '34567';
        mpir.paymentMethod = payMethod;
        mpir.enrollInAutopay = true;
        mpirList.add(mpir);

        BWC_MakePayment.UpdatePaymentRequest upr = new BWC_MakePayment.UpdatePaymentRequest();
        upr.locationId = 'TestLocationId';
        upr.sourceBusinessUnit = 'TestSourceBU';
        upr.customerAgreement = 'TestCustAgrmt';
        upr.appName = 'TestAppName';
        upr.sourceSystem = 'TestSourceSys';
        upr.sourceLocation = 'TestSourceLoc';
        upr.sourceUser = 'TestSourceUser';
        upr.idempotencyKey = 'TestIdemKey';
        upr.convenienceFee = 'TestConvFee';
        upr.tncId = 43267;
        upr.autopayTncId = 478596;
        upr.autopayCustomerAgreement = 'TestAutoPay';
        upr.storeTermsConditionConsent = true;
        upr.transactionId = 'TestTranscId';
        upr.accountNumber = '478596585321';
        upr.accountType = 'TestAcctType';
        upr.firstName = 'TestFN';
        upr.lastName = 'TestLN';
        upr.existingPendingPaymentId = listPId;
        upr.modifyFuturePaymentRequest = mpirList;

        return upr;
    }

    public static Interaction__c createInteraction(Account acct) {
        Interaction__c interaction = new Interaction__c();
        interaction.Customer__c = acct.Id;
        interaction.User_Account_Number__c = '423432423';
        interaction.User_Telephone_Number__c = '4056553566';
        interaction.trackingIdent__c = 'SALESFORCE-MD809K-414707-11242020-0610-51-018';
        insert interaction;
        return interaction;
    }

    public static Interaction__c createInteractionWithAuthorization(Account acct, Billing_Account__c billAcct) {
        Interaction__c interaction = new Interaction__c();
        interaction.Customer__c = acct.Id;
        interaction.User_Account_Number__c = '423432423';
        interaction.User_Telephone_Number__c = '4056553566';
        interaction.trackingIdent__c = 'SALESFORCE-MD809K-414707-11242020-0610-51-018';
        interaction.Authorization_Json__c =
            '{  "recommendedStepUps" : [ {    "stepUpType" : "PASSCODE",    "billingAccountId" : "' +
            billAcct.Id +
            '",    "accountType" : "WIRELESS",    "accountBan" : "423432423"  }, {    "stepUpType" : "OTP",    "otpPhoneNumber" : [ "6824013319", "9725715283", "2146492017" ],    "billingAccountId" : "' +
            billAcct.Id +
            '",    "accountType" : "WIRELESS",    "accountBan" : "423432423"  } ],  "associatedAccounts" : [ {    "billingAccountId" : "' +
            billAcct.Id +
            '",    "authorizationLevel" : "BYPASS",    "accountType" : "WIRELESS",    "accountBan" : "423432423"  } ]}';
        insert interaction;
        return interaction;
    }

    /*
        Should insert interaction record with minimal required fields.
    */
    public static Interaction__c createNewInteraction() {
        Interaction__c interaction = new Interaction__c(
            RecordTypeId = Schema.Interaction__c.getSObjectType()
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get(BWC_Interaction.RECORD_TYPE_INBOUND)
                .getRecordTypeId(),
            CTI_Call_Identifier__c = 'Test',
            Is_Manual_Search__c = true
        );
        insert interaction;
        return interaction;
    }

    public static User createUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0, 8);
        User u = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uid + '@att.com'
        );
        u.ATTUID__c = 'md809k';
        u.StoreLocationId__c = 'DMDR';
        insert u;
        return u;
    }

    public static Map<String, User> createUsers(Integer numberOf) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        Map<String, User> users = new Map<String, User>();

        for (Integer i = 0; i < numberOf; i++) {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String uid = h.SubString(0, 8);
            User u = new User(
                Alias = 'standt',
                Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = uid + '@att.com'
            );
            u.ATTUID__c = 'md809k';
            u.StoreLocationId__c = 'DMDR';
            users.put(u.UserName, u);
        }

        insert users.values();

        return users;
    }

    public static list<BWC_BillingStatement.BillingStatementRequest> createBillingStatementRequest() {
        list<BWC_BillingStatement.BillingStatementRequest> listbsr = new List<BWC_BillingStatement.BillingStatementRequest>();

        BWC_BillingStatement.BillingStatementRequest bsr = new BWC_BillingStatement.BillingStatementRequest();
        bsr.product = 'Wireless';
        bsr.ban = '325310161';
        listbsr.add(bsr);

        BWC_BillingStatement.BillingStatementRequest bsr1 = new BWC_BillingStatement.BillingStatementRequest();
        bsr1.product = 'Wireline';
        bsr1.ban = '325310163';
        listbsr.add(bsr1);

        return listbsr;
    }

    public static BWC_NotesSearch.NotesSearchRequest createNotesSearchRequest() {
        list<BWC_NotesSearch.Ban> listBans = new List<BWC_NotesSearch.Ban>();

        BWC_NotesSearch.Ban b = new BWC_NotesSearch.Ban('287273108130', 'wireless');
        listBans.add(b);

        BWC_NotesSearch.Ban b1 = new BWC_NotesSearch.Ban('287273122837', 'wireless');
        listBans.add(b1);

        BWC_NotesSearch.NoteFilterParams nfp = new BWC_NotesSearch.NoteFilterParams();
        nfp.callingApp = BWC_Constants.NOTES_CALLING_APP;
        nfp.bans = listBans;

        BWC_NotesSearch.NotePaginationParams npp = new BWC_NotesSearch.NotePaginationParams();
        npp.pageSize = -1;
        npp.pageNumber = 1;

        BWC_NotesSearch.NotesSearchRequest nsr = new BWC_NotesSearch.NotesSearchRequest();
        nsr.noteSortTypeEnum = '';
        nsr.noteFilterParams = nfp;
        nsr.notePaginationParams = npp;

        return nsr;
    }
    //need to complete
    public static Employee__c createEmployee() {
        Employee__c e = new Employee__c();

        return e;
    }

    public static Account createAccountForParent() {
        Account acctObj = new Account();
        acctObj.BillingCity = 'Austin';
        acctObj.BillingCountry = 'United States';
        acctObj.BillingCountryCode = 'US';
        acctObj.BillingPostalCode = '75461';
        acctObj.BillingStreet = '1234 Test Dr';
        acctObj.Employee__c = false;
        acctObj.FirstName = 'Natasha1';
        acctObj.Global_ID__c = '2544948780';
        acctObj.Interactions_in_Last_30_Days__c = 2;
        acctObj.LastName = 'Romanov1';
        acctObj.PersonEmail = 'test@somewhere.com';
        acctObj.Phone = '(555) 111 222 4444';
        acctObj.Primary_BAN__c = '423432424';
        acctObj.Primary_Product__c = 'Wireless';
        acctObj.RecordTypeId = getRecordTypeIdByName(BWC_Constants.PERSON_ACCOUNT, 'Account');
        acctObj.ShippingCity = 'Austin';
        acctObj.ShippingCountry = 'United States';
        acctObj.ShippingCountryCode = 'US';
        acctObj.ShippingPostalCode = '75461';
        acctObj.ShippingStreet = '123 Test Dr';
        insert acctObj;
        return acctObj;
    }

    /*  Method is used to create Billing Account based on Record type pass and
        link the billing account to person account via Customer Account
        relationship object

        Object record created for
        Billing_Account__c
        Customer_Account_Relation__c

        @return Billing_Account__c
    */
    public static Billing_Account__c createBillingAccountforParent(String recordTypeName, Account acct) {
        Date mydate = System.Today();
        Billing_Account__c billAcctObj = new Billing_Account__c();
        billAcctObj.Account_Status__c = 'S';
        billAcctObj.Account_Type__c = recordTypeName;
        billAcctObj.Billing_Account_Number__c = '423432424';
        billAcctObj.Billing_Address_Line_1__c = '1234 Test Dr';
        billAcctObj.Billing_Address_Line_2__c = '1234 Test Dr';
        billAcctObj.Billing_City__c = 'Austin';
        billAcctObj.Billing_State__c = 'TX';
        billAcctObj.Billing_Zipcode__c = '75461';
        billAcctObj.Service_Address_Line_1__c = '1234 Test Dr';
        billAcctObj.Service_Address_Line_2__c = '1234 Test Dr';
        billAcctObj.Service_City__c = 'Austin';
        billAcctObj.Service_State__c = 'TX';
        billAcctObj.Service_Zipcode__c = '75461';
        billAcctObj.BMG_Contract_Type__c = '';
        billAcctObj.Contact_Number__c = '(555) 111 222 4444';
        billAcctObj.CPNI_Preference__c = '';
        billAcctObj.CustomerID__c = '124';
        billAcctObj.Customer_Liability__c = 'Value 1';
        billAcctObj.Customer_Since__c = mydate.addYears(-5);
        billAcctObj.Device_Protection_Plan__c = 'No';
        billAcctObj.DigitalLife__c = false;
        billAcctObj.Email__c = 'test@somewhere.com';
        billAcctObj.Enrolled_in_Large_Print__c = false;
        billAcctObj.FAN_Category__c = '3423';
        billAcctObj.Fan_Name__c = '';
        billAcctObj.FAN_Number__c = '1234567';
        billAcctObj.FAN_Sub_Category_2__c = '242214';
        billAcctObj.FAN_Sub_Category_3__c = '242214';
        billAcctObj.FAN_Sub_Category_4__c = '242214';
        billAcctObj.First_Name__c = 'Natasha1';
        billAcctObj.Fixed_Wireless_Internet__c = false;
        billAcctObj.Is_Employee__c = false;
        billAcctObj.Language_Preference__c = 'English';
        billAcctObj.Last_Name__c = 'Romanov1';
        billAcctObj.Retail_Serviceable__c = false;
        billAcctObj.Security_Level__c = '';
        billAcctObj.Security_Question__c = '';
        billAcctObj.Service_Start_Date__c = mydate.addYears(-5);
        billAcctObj.UserID__c = 'johnatt1@slid.dum';
        billAcctObj.Visually_Impaired__c = false;

        insert billAcctObj;

        //now create Customer_Account_Relation__c record to related
        Customer_Account_Relation__c carObj = new Customer_Account_Relation__c();
        carObj.Billing_Account__c = billAcctObj.Id;
        carObj.Customer__c = acct.Id;
        insert carObj;

        return billAcctObj;
    }

    public static List<Charge_Code_By_Market__c> getChargeCodesByMarket(Integer numberOf, String billingMarket) {
        List<Charge_Code_By_Market__c> chargeCodes = new List<Charge_Code_By_Market__c>();

        for (Integer i = 0; i < numberOf; i++) {
            chargeCodes.add(
                new Charge_Code_By_Market__c(
                    Charge_Amount__c = 5.00,
                    Charge_Code__c = 'Test Code ' + i,
                    Charge_Code_Description__c = 'Test Code' + i,
                    Charge_Level__c = 'S',
                    External_Id__c = 'TESTID' + i,
                    Market_Code__c = billingMarket,
                    Taxed_Feature__c = 'No'
                )
            );
        }

        return chargeCodes;
    }

    public static List<Reason_Code_for_Charge_Code__c> getReasonsForChargeCode(
        Integer numberOf,
        String chargeCode,
        String chargeType
    ) {
        List<Reason_Code_for_Charge_Code__c> reasonCodes = new List<Reason_Code_for_Charge_Code__c>();

        for (Integer i = 0; i < numberOf; i++) {
            reasonCodes.add(
                new Reason_Code_for_Charge_Code__c(
                    Biller__c = 'Enabler',
                    Charge_Code__c = chargeCode,
                    Charge_Type__c = chargeType,
                    Adj_Reason_Explanation_Code__c = 'Test-Code ' + i,
                    Adj_Reason_System_Code__c = 'Test-Code ' + i,
                    External_Id__c = chargeCode + '-Test-Code' + i
                )
            );
        }
        return reasonCodes;
    }

    public static User createC360AgentUser() {
        List<Profile> customerServiceRepProfiles = [SELECT Id FROM Profile WHERE Name = 'Customer Service Rep'];
        if (customerServiceRepProfiles.isEmpty()) {
            throw new BWC_Exception('Test relies on profile "Customer Service Rep" which cannot be found.');
        }
        List<PermissionSet> agentPermissionSets = [SELECT Id FROM PermissionSet WHERE Name = 'C360_Agent'];
        if (agentPermissionSets.isEmpty()) {
            throw new BWC_Exception('Test relies on permission set "C360_Agent" which cannot be found.');
        }

        User agentUser = new User(
            Username = 'unitTestAgent@attone.com',
            Alias = '360agent',
            FirstName = 'Test',
            LastName = 'C360Agent',
            ProfileId = customerServiceRepProfiles[0].Id,
            Email = 'unitTestAgent@attone.com',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US'
        );

        agentUser.ATTUID__c = 'md809k';

        // Prevents Mixed DML exception
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert agentUser;
            insert new PermissionSetAssignment(AssigneeId = agentUser.id, PermissionSetId = agentPermissionSets[0].Id);
        }

        return agentUser;
    }

    /**
     * @description Generate an interaction with various billing accounts.
     * @param       authorizationLevel      Init Authorization_Json__c: NONE, STEPUPSONLY, L0, L1, BYPASS
     * @param       authenticationMethod    Set as authenticated per BWC_Authentication.AUTHENTICATION_METHOD_x: NONE, PASSCODE, OTP, BYPASS
     * @return      The inserted Interaction__c
     */
    public static Interaction__c createFullInteraction(String authorizationLevel, String authenticationMethod) {
        String ctiCallId = BWC_Utils.generateRandomString(10);

        // Billing Accounts
        Billing_Account__c wirelessBillingAccount = new Billing_Account__c(
            Account_Type__c = 'Wireless',
            Billing_Account_Number__c = '1111111111111',
            CTI_Call_Identifier__c = ctiCallId,
            Product_Name_360__c = 'wireless',
            Customer_Type__c = 'Consumer',
            First_Name__c = 'Natasha',
            Last_Name__c = 'Romanov',
            Email__c = 'test@somewhere.com',
            Billing_City__c = 'Dallas',
            Billing_Address_Line_1__c = '123 Test Dr',
            Billing_Country__c = 'United States',
            Billing_Zipcode__c = '75462',
            Language_Preference__c = 'English',
            Contact_Number__c = '(555) 123-4567'
        );

        Billing_Account__c uverseBillingAccount = new Billing_Account__c(
            Account_Type__c = 'uverse',
            Billing_Account_Number__c = '22222222',
            CTI_Call_Identifier__c = ctiCallId,
            Product_Name_360__c = 'uverse',
            Customer_Type__c = 'Consumer',
            First_Name__c = 'Natasha',
            Last_Name__c = 'Romanov',
            Email__c = 'test@somewhere.com',
            Billing_City__c = 'Dallas',
            Billing_Address_Line_1__c = '123 Test Dr',
            Billing_Country__c = 'United States',
            Billing_Zipcode__c = '75462',
            Language_Preference__c = 'English',
            Contact_Number__c = '(555) 123-4567'
        );

        Billing_Account__c dtvNowBillingAccount = new Billing_Account__c(
            Account_Type__c = 'dtvnow',
            Billing_Account_Number__c = '333333333333',
            CTI_Call_Identifier__c = ctiCallId,
            Product_Name_360__c = 'dtvnow',
            Customer_Type__c = 'Consumer',
            First_Name__c = 'Natasha',
            Last_Name__c = 'Romanov',
            Email__c = 'test@somewhere.com',
            Billing_City__c = 'Dallas',
            Billing_Address_Line_1__c = '123 Test Dr',
            Billing_Country__c = 'United States',
            Billing_Zipcode__c = '75462',
            Language_Preference__c = 'English',
            Contact_Number__c = '(555) 123-4567'
        );

        Billing_Account__c potsBillingAccount = new Billing_Account__c(
            Account_Type__c = 'POTS',
            Billing_Account_Number__c = '4444444444444',
            CTI_Call_Identifier__c = ctiCallId,
            Product_Name_360__c = 'phone',
            Customer_Type__c = 'Consumer',
            First_Name__c = 'Natasha',
            Last_Name__c = 'Romanov',
            Email__c = 'test@somewhere.com',
            Billing_City__c = 'Dallas',
            Billing_Address_Line_1__c = '123 Test Dr',
            Billing_Country__c = 'United States',
            Billing_Zipcode__c = '75462',
            Language_Preference__c = 'English',
            Contact_Number__c = '(555) 123-4567'
        );

        List<Billing_Account__c> billingAccounts = new List<Billing_Account__c>{
            wirelessBillingAccount,
            uverseBillingAccount,
            dtvNowBillingAccount,
            potsBillingAccount
        };
        insert billingAccounts;

        // Customer Account
        Account testAccount = new Account(
            RecordTypeId = Schema.Account.getSObjectType()
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get(BWC_Constants.ACCOUNT_RECORD_TYPE_PERSON_ACCOUNT)
                .getRecordTypeId(),
            FirstName = 'Natasha',
            LastName = 'Romanov',
            PersonEmail = 'test@somewhere.com',
            Phone = '(555) 123-4567',
            BillingCity = 'Dallas',
            BillingStreet = '123 Test Dr',
            BillingCountry = 'United States',
            BillingCountryCode = 'US',
            BillingPostalCode = '75462',
            ShippingCity = 'Dallas',
            ShippingCountry = 'United States',
            ShippingCountryCode = 'US',
            ShippingPostalCode = '75462',
            Primary_BAN__c = wirelessBillingAccount.Billing_Account_Number__c
        );
        insert testAccount;

        // Relate all billing accounts to the customer
        List<Customer_Account_Relation__c> relationships = new List<Customer_Account_Relation__c>();
        for (Billing_Account__c billingAccount : billingAccounts) {
            relationships.add(
                new Customer_Account_Relation__c(Customer__c = testAccount.Id, Billing_Account__c = billingAccount.Id)
            );
        }
        insert relationships;

        // Authorization level
        BWC_AuthorizationCallout.AuthorizationStatusContent authorizationContent;
        if (authorizationLevel != null && authorizationLevel != 'NONE') {
            authorizationContent = new BWC_AuthorizationCallout.AuthorizationStatusContent();
            authorizationContent.recommendedStepUps = new List<BWC_AuthorizationCallout.RecommendedStepUp>{
                new BWC_AuthorizationCallout.RecommendedStepUp('PASSCODE', wirelessBillingAccount, null, null),
                new BWC_AuthorizationCallout.RecommendedStepUp(
                    'OTP',
                    wirelessBillingAccount,
                    new List<String>{ '2144350011' },
                    new List<String>{ 'test@email.com' }
                ),
                new BWC_AuthorizationCallout.RecommendedStepUp('PASSCODE', uverseBillingAccount, null, null)
            };

            if (authorizationLevel == 'L1' || authorizationLevel == 'BYPASS') {
                authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();
                for (Billing_Account__c billingAccount : billingAccounts) {
                    authorizationContent.associatedAccounts.add(
                        new BWC_AuthorizationCallout.AssociatedAccount(
                            billingAccount,
                            authorizationLevel,
                            authenticationMethod
                        )
                    );
                }
            } else if (authorizationLevel == 'L0') {
                authorizationContent.associatedAccounts = new List<BWC_AuthorizationCallout.AssociatedAccount>();
                authorizationContent.associatedAccounts.add(
                    new BWC_AuthorizationCallout.AssociatedAccount(wirelessBillingAccount, 'L1', authenticationMethod)
                );
                authorizationContent.associatedAccounts.add(
                    new BWC_AuthorizationCallout.AssociatedAccount(uverseBillingAccount, 'L0', 'NONE')
                );
            }
        }

        // Authentication level
        String manualAuthenticationMethod;
        Map<String, String> manualAuthentications;
        if (authenticationMethod != null && authenticationMethod != 'NONE') {
            manualAuthenticationMethod = authenticationMethod;
            manualAuthentications = new Map<String, String>();
            manualAuthentications.put(wirelessBillingAccount.Id, authenticationMethod);
        }

        // Interaction
        Interaction__c interaction = new Interaction__c(
            RecordTypeId = Schema.Interaction__c.getSObjectType()
                .getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get(BWC_Interaction.RECORD_TYPE_INBOUND)
                .getRecordTypeId(),
            Customer__c = testAccount.Id,
            Billing_Account__c = wirelessBillingAccount.Id,
            Is_Manual_Search__c = true,
            CTI_Call_Identifier__c = ctiCallId,
            Manual_Authentication_Method__c = manualAuthenticationMethod,
            Manual_Authentication_Json__c = manualAuthentications != null
                ? JSON.serialize(manualAuthentications)
                : null,
            Is_Authorized__c = authorizationLevel == 'L1' || authorizationLevel == 'BYPASS',
            Authorization_Json__c = authorizationContent != null ? JSON.serialize(authorizationContent, true) : null
        );

        insert interaction;

        interaction.Customer__r = testAccount;

        return interaction;
    }
    public static Billing_Account__c createUniqueBillingAccount(
        String recordTypeName,
        Account acct,
        String externalId,
        String Language
    ) {
        Date mydate = System.Today();
        Billing_Account__c billAcctObj = new Billing_Account__c();
        billAcctObj.Account_Status__c = 'S';
        billAcctObj.Account_Type__c = recordTypeName;
        billAcctObj.Billing_Account_Number__c = '423432423';
        billAcctObj.Billing_Address_Line_1__c = '123 Test Dr';
        billAcctObj.Billing_Address_Line_2__c = '123 Test Dr';
        billAcctObj.Billing_City__c = 'Dallas';
        billAcctObj.Billing_State__c = 'TX';
        billAcctObj.Billing_Zipcode__c = '75462';
        billAcctObj.Service_Address_Line_1__c = '123 Test Dr';
        billAcctObj.Service_Address_Line_2__c = '123 Test Dr';
        billAcctObj.Service_City__c = 'Dallas';
        billAcctObj.Service_State__c = 'TX';
        billAcctObj.Service_Zipcode__c = '75462';
        billAcctObj.BMG_Contract_Type__c = '';
        billAcctObj.Contact_Number__c = '(555) 111 222 3333';
        billAcctObj.CPNI_Preference__c = '';
        billAcctObj.CustomerID__c = '123';
        billAcctObj.Customer_Liability__c = 'Value 1';
        billAcctObj.Customer_Since__c = mydate.addYears(-5);
        billAcctObj.Device_Protection_Plan__c = 'No';
        billAcctObj.DigitalLife__c = false;
        billAcctObj.Email__c = 'test@somewhere.com';
        billAcctObj.Enrolled_in_Large_Print__c = false;
        billAcctObj.FAN_Category__c = '3423';
        billAcctObj.Fan_Name__c = '';
        billAcctObj.FAN_Number__c = '1234567';
        billAcctObj.FAN_Sub_Category_2__c = '242214';
        billAcctObj.FAN_Sub_Category_3__c = '242214';
        billAcctObj.FAN_Sub_Category_4__c = '242214';
        billAcctObj.First_Name__c = 'Natasha';
        billAcctObj.Fixed_Wireless_Internet__c = false;
        billAcctObj.Is_Employee__c = false;
        billAcctObj.Language_Preference__c = Language;
        billAcctObj.Last_Name__c = 'Romanov';
        billAcctObj.Retail_Serviceable__c = false;
        billAcctObj.Security_Level__c = '';
        billAcctObj.Security_Question__c = '';
        billAcctObj.Service_Start_Date__c = mydate.addYears(-5);
        billAcctObj.UserID__c = 'johnatt@slid.dum';
        billAcctObj.Visually_Impaired__c = false;
        billAcctObj.External_Id__c = externalId;

        insert billAcctObj;
        return billAcctObj;
    }
    public static Case createEscalatedCase(Account acc, Billing_Account__c billingAccount, String contactId) {
        string escalatedRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Escalation')
            .getRecordTypeId();
        case caseObj = new case();
        caseObj.Status = 'New';
        caseObj.AccountId = acc.id;
        caseObj.Billing_Account__c = billingAccount.Id;
        caseObj.RecordTypeId = escalatedRecTypeId;
        caseObj.ContactId = contactId;
        return caseObj;
    }
    public static Communication_Template_Mapping__c customTemplateMapping(
        string caseAction,
        string commType,
        String resolution,
        String resolution2,
        string lang
    ) {
        Communication_Template_Mapping__c templateMapping2 = new Communication_Template_Mapping__c();
        templateMapping2.Case_Action__c = caseAction;
        templateMapping2.Communication_Type__c = commType;
        templateMapping2.Resolution__c = resolution;
        templateMapping2.Resolution_2__c = resolution2;
        templateMapping2.Language_Preference__c = lang;
        templateMapping2.Status__c = 'Active';
        return templateMapping2;
    }
    public static User createUser(string profileId) {
        //Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0, 8);
        User u = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uid + '@att.com'
        );
        u.ATTUID__c = 'md809k';
        u.StoreLocationId__c = 'DMDR';
        insert u;
        return u;
    }
    public static SOA_Level__c createSOA(String Org, String channel,String subchannel,String authLevel, String LOB, Decimal AuthAmount){
        SOA_Level__c soaLevel = new SOA_Level__c();
        soaLevel.Organization__c = Org;
        soaLevel.Channel__c = channel;
        soaLevel.Sub_Channel__c = subchannel;
        soaLevel.Authorization_Level__c = authLevel;
        soaLevel.Line_of_Business__c = LOB;
        soaLevel.Authorization_Amount__c = AuthAmount ;
        return soaLevel;
    }
    public static Employee__c createEmployeeWithSOA(SOA_Level__c soaLevel, String employeeId, String userId){
        Employee__c emp = new Employee__c();
        emp.User__c = userId;
        emp.EmployeeId__c = employeeId;
        emp.SOA_Level__c = soaLevel.Id;
        return emp;
    }
     public static EmailTemplate customEmailTemplate(
        string developerName,
        string TemplateType,
        String Name,
        Boolean isActive,
        string FolderId,
        String Subject
    ) {
        EmailTemplate template = new EmailTemplate();
        template.developerName = developerName;
        template.TemplateType = TemplateType;
        template.Name = Name;
        template.isActive = isActive;
        template.FolderId = folderId;
        template.Subject = subject;
        return template;
    }

    public static Employee__c createAuthorizedRetailEmployee(Id userId){
        Employee__c emp = new Employee__c();
        emp.Name = 'John Doe';
        emp.Organization__c = 'Retail';
        emp.Channel__c = 'Retail';
        emp.Channel1__c = 'Retail';
        emp.Sub_Channel__c = 'Authorized Retail';
        emp.EmployeeId__c = 'jdoe1234';
        emp.User__c = userId;

        insert emp;

        return emp;
    }
}
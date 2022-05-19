/*
 *  Class responsible for initial post message.
 */
public with sharing class BWC_LIC_OpusMsgController
{

    // TODO: this looks like a dupe of what is in BWC_LIC_OpusBgUtilController, maybe move this to the constants class?
    private static final String OPUS_ROW = 'OPUS_LIC';
    private static final String OPT_Y = 'Y';
    private static final String OPT_N = 'N';
    private static final String REP_DETAILS_FORMAT = '{0}|{1}';
    private static final String TRACKING_ID_FORMAT = '{0}-{1}-{2}-{3}';
    private static final String AVERTACK_ID_FORMAT = '{0}-{1}';
    private static final String URL_FORMAT = '{0}{1}';
    private static final String CUSTOMER_TYPE_CONSUMER = 'Consumer';
    private static final String LOB_WLS = 'WLS';
    public static List<String> topics = new List<String>{
        BWC_Constants.LIC_OPUS_TOPIC
    };

    // cache the opus config in a map by the developer name
    private static Map<String, BWC_OpusLIC__mdt> cacheOpusConfig = new Map<String, BWC_OpusLIC__mdt>();

    // method that does not require parameters and assumes the default 'OPUS_LIC'
    public static BWC_OpusLIC__mdt getOpusConfig()
    {
        return getOpusConfig(OPUS_ROW);
    }

    // retrieve the OPUS config, using cache if possible
    public static BWC_OpusLIC__mdt getOpusConfig(String opusConfigName)
    {
        // build the key
        String mdtOpusConfigName = (String.isBlank(opusConfigName) ? OPUS_ROW : opusConfigName);

        // check cache
        if (!cacheOpusConfig.containsKey(mdtOpusConfigName))
        {
            // Query for the OPUS config from custom metadata
            List<BWC_OpusLIC__mdt> opusConfigList = [
                SELECT CLIENT_REQUEST__c, Enabled__c, HardCode_CustomerType__c, IDEN_FORMAT__c, KeepAlive__c,
                    NoOfAttempt__c, OPUS_URL__c, OPUS_URL_EXT__c, RetryOPUS__c, SYSTEM_ID__c, TOKEN_FORMAT__c,
                    WindowName__c, XsecWaiting__c, Redirected_URL__c
                FROM BWC_OpusLIC__mdt
                WHERE DeveloperName = :mdtOpusConfigName
                LIMIT 1
            ];
            // empty check
            if (opusConfigList.isEmpty())
            {
                List<Object> params = new List<Object>{'OPUS',  opusConfigName, 'OPUS_LIC Configuration is not set in BWC_OpusLIC Custom Metadata'};
                LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
                Logger.error(logMessage).setRecordId(opusConfigName).setTopics(BWC_Constants.LIC_TOPICS);
                Logger.saveLog();
                throw new BWC_Exception('OPUS_LIC Configuration is not set in BWC_OpusLIC Custom Metadata!');
            }

            // cache the config
            cacheOpusConfig.put(mdtOpusConfigName, opusConfigList[0]);
        }

        // return from cache
        return cacheOpusConfig.get(mdtOpusConfigName);
    }

    // cache the current user
    private static User cacheCurrentUser = null;

    public static User getCurrentUser()
    {
        if (cacheCurrentUser == null)
        {
            // query for the current user
            List<User> currentUser = [SELECT ATTUID__c, StoreLocationId__c FROM User WHERE Id = :UserInfo.getUserId()];

            // check if the user was found and if the ATTUID is populated
            if (currentUser.isEmpty() || String.isEmpty(currentUser[0].ATTUID__c))
            {
                List<Object> params = new List<Object>{'OPUS',  UserInfo.getUserId(), 'User does not have an ATTUID populated in user record!'};
                LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
                Logger.error(logMessage).setRecordId(UserInfo.getUserId()).setTopics(BWC_Constants.LIC_TOPICS);
                Logger.saveLog();
                throw new BWC_Exception('User does not have an ATTUID populated in user record!');
            }

            // cache the user
            cacheCurrentUser = currentUser[0];
        }

        // return cached user
        return cacheCurrentUser;
    }

    public static Interaction__c getInteraction(Id interactionId)
    {
        // query for the Interaction
        List<Interaction__c> interLst = [
            SELECT Authorization_Json__c, CompletedDate__c, Customer__c, Id, Is_Authorized__c, trackingIdent__c, User_Account_Number__c, User_Telephone_Number__c, RecordTypeId
            FROM Interaction__c
            WHERE Id = :interactionId
        ];
        // empty check
        if (interLst.isEmpty())
        {
            List<Object> params = new List<Object>{'OPUS',  interactionId, null};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.error(logMessage).setRecordId(interactionId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
            throw new BWC_Exception('Interaction record does not exist! Interaction Id: ' + interactionId);
        }

        // return the interaction
        return interLst[0];
    }

    public static Account getAccountWithBillingAccounts(Id accountId)
    {
        // query for the Interaction
        List<Account> accounts = [SELECT Id, Primary_Product__c, Primary_BAN__c, isFirstNet__c,
            (SELECT Id, Billing_Account__c FROM Customer_Account_Relation__r)
            FROM Account WHERE Id = :accountId
        ];
        // empty check
        if (accounts.isEmpty())
        {
            List<Object> params = new List<Object>{'OPUS',  accountId, null};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.error(logMessage).setRecordId(accountId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
            throw new BWC_Exception('Account record does not exist! Account Id: ' + accountId);
        }

        // return the interaction
        return accounts[0];
    }

    // perform the HTTP POST to OPUS
    public Pagereference postToOPUS()
    {
        // TODO: add comments explaining what these variables are used for
        BWC_LIC_OpusMsgRequest.OPUSInitRequest req = new BWC_LIC_OpusMsgRequest.OPUSInitRequest();
        List<Billing_Account__c> baLst = null;

        List<String> baIdLst = new List<String>();
        try
        {
            BWC_OpusLIC__mdt opusConfig = BWC_LIC_OpusMsgController.getOpusConfig();
            String recordId = ApexPages.currentPage().getParameters().get('id');
            // TODO: use String.isBlank() instead of checking for '' or null
            if (String.isBlank(recordId))
            {
                throw new BWC_Exception('Interaction record Id is null: ' + recordId);
            }

            // get the current user
            User currentUser = BWC_LIC_OpusMsgController.getCurrentUser();

            // get the interaction record
            Interaction__c interaction = BWC_LIC_OpusMsgController.getInteraction(recordId);

            // retrieve the Account and Billing Accounts for the Customer on the Interaction
            Account acct = BWC_LIC_OpusMsgController.getAccountWithBillingAccounts(interaction.Customer__c);

            // TODO: see comments from other class
            List<Customer_Account_Relation__c> csrList = acct.Customer_Account_Relation__r;
            for (Customer_Account_Relation__c car : csrList)
            {
                baIdLst.add(car.Billing_Account__c);
            }
            System.debug('baIdLst :' + baIdLst);
            System.debug('interaction.User_Account_Number__c :' + interaction.User_Account_Number__c);

            if (!baIdLst.isEmpty())
            {
                baLst = [
                    SELECT Id, Customer_Type__c,
                    LOB_Type__c, Billing_Account_Number__c
                    FROM Billing_Account__c
                    WHERE Id in :baIdLst
                    AND Billing_Account_Number__c =:interaction.User_Account_Number__c
                ];
            }
            if (baIdLst.isEmpty() || baLst.isEmpty())
            {
                List<Object> params = new List<Object>{'OPUS',  interaction.User_Account_Number__c, 'No matching Billing Account Found'};
                LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
                Logger.error(logMessage).setRecordId(interaction.Id).setTopics(BWC_Constants.LIC_TOPICS);
                Logger.saveLog();
                throw new BWC_Exception('No matching Billing Account Found!');
            }
            // TODO: see comments from other class about how to handle trackingIdent
            // TODO: looks like a lot of dupe code...
            // everything is good now lets process.
            Datetime dt = Datetime.now();
            String tokenDate = dt.formatGMT(opusConfig.TOKEN_FORMAT__c);
            String identDate = dt.formatGMT(opusConfig.IDEN_FORMAT__c);
            // create a random number string that is 6 characters long (with leading digits)
            Integer randNum = Integer.valueof((Math.random() * 1000000));
            String randNumStr = (('00000') + randNum).right(6);
            String attId = currentUser.ATTUID__c;
            // start populating the OPUS LIC object
            req.sysId = opusConfig.SYSTEM_ID__c;
            req.repDetails = String.format(REP_DETAILS_FORMAT, new Object[] {attId, tokenDate});
            req.storeLocationId = currentUser.StoreLocationId__c;

            // // We should be doing relaunch by passing in a BAN and checking to see if it is verified. This would be too much code churn right now, so we are just going to pass 'N' for relaunch all the time.
            // // TODO: Pass BAN and check if it is verified, if verified and relaunch URL param is 'Y', then set relaunch param in trigger 1 to 'Y'.
            String relaunchParam = ApexPages.currentPage().getParameters().get('relaunch');
            // req.relaunch = String.isBlank(relaunchParam) ? OPT_N : relaunchParam;
            req.relaunch = OPT_N;

            // build tracking identier string
            req.trackingIdent = String.format(TRACKING_ID_FORMAT, new Object[] {opusConfig.SYSTEM_ID__c, attId.toUpperCase(), randNumStr, identDate});

            req.sfCustomerInfo = new List<BWC_LIC_OpusMsgRequest.SfCustomerInfo>();
            for (Billing_Account__c ba : baLst)
            {
                BWC_LIC_OpusMsgRequest.SfCustomerInfo custInfo = new BWC_LIC_OpusMsgRequest.SfCustomerInfo();
                custInfo.AccNumber = ba.Billing_Account_Number__c; // get from CTI/IVR
                // Hardcoding as told me to do so.
                if (opusConfig.HardCode_CustomerType__c)
                {
                    custInfo.customerType = CUSTOMER_TYPE_CONSUMER;
                }
                else
                {
                    custInfo.customerType = ba.Customer_Type__c;
                }
                custInfo.LOBType = ba.LOB_Type__c;
                // CTN will be populated only when LobType=WLS
                // if (LOB_WLS.equals(custInfo.LOBType))
                // {
                //     custInfo.CTN = interaction.User_Telephone_Number__c;
                // }

                // check authorization against primary ban on interaction
                custInfo.isVerified = OPT_N;
                if (interaction.Is_Authorized__c)
                {
                    BWC_AuthorizationCallout.AuthorizationStatusContent resp;
                    resp = (BWC_AuthorizationCallout.AuthorizationStatusContent) JSON.deserialize(
                        interaction.Authorization_Json__c, BWC_AuthorizationCallout.AuthorizationStatusContent.class);
                    if ((resp != null) && (resp.associatedAccounts != null))
                    {
                        for (BWC_AuthorizationCallout.AssociatedAccount assAct : resp.associatedAccounts)
                        {
                            if (
                                (custInfo.AccNumber.equals(assAct.accountBan)) &&
                                ((BWC_Constants.AUTHORIZATION_LEVEL_L1.equals(assAct.authorizationLevel)) ||
                                BWC_Constants.AUTHORIZATION_LEVEL_BYPASS.equals(assAct.authorizationLevel) )
                                )
                            {
                                custInfo.isVerified = OPT_Y;

                                // if the primary BAN is verified, then we can use the relaunch URL parameter
                                req.relaunch = (String.isBlank(relaunchParam) ? OPT_N : relaunchParam);
                            }
                        }
                    }
                }

                custInfo.primarySearchAccount = interaction.User_Account_Number__c;
                custInfo.cssIdForAvertack = String.format(AVERTACK_ID_FORMAT, new Object[] {interaction.Id, ba.Billing_Account_Number__c});
                req.sfCustomerInfo.add(custInfo);
            }
            // update interaction record.
            // TODO: why not assign this above and then we don't need to define trackIdent variable?
            interaction.trackingIdent__c = req.trackingIdent;


            // update the interaction to set the tracking identifier
            update interaction;

            String param = JSON.serialize(req, true);

            // APILoggings__c apilogin = new APILoggings__c();
            // apilogin.APIName__c = 'OPUS_LIC';
            // apilogin.Request_Headers__c = param;
            // apilogin.Datetime_Called__c = System.now();
            // insert apilogin;

            List<Object> params = new List<Object>{'OPUS',  recordId, param};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.info(logMessage).setRecordId(recordId).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();

            // TODO: explain why the 2nd param is 'true'
            // TODO: why do you need to put the +''+ in the middle?
            // System.debug('OPUS URL: ' + opusConfig.OPUS_URL__c +''+opusConfig.OPUS_URL_EXT__c);
            // System.debug('OPUS Params: ' + param);
            Pagereference pageRef = new Pagereference(String.format(URL_FORMAT, new Object[] {opusConfig.OPUS_URL__c, opusConfig.OPUS_URL_EXT__c}));
            pageRef.setRedirect(false); // set the redirect to use POST instead of GET
            pageRef.getParameters().put(opusConfig.CLIENT_REQUEST__c, param); // add the JSON to the POST data
            return (pageRef);
        }
        catch (System.Exception e)
        {
            System.debug('Exception :' + e.getStackTraceString());
            List<Object> params = new List<Object>{'OPUS',  null, JSON.serialize(e)};
            LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
            Logger.error(logMessage).setTopics(BWC_Constants.LIC_TOPICS);
            Logger.saveLog();
            // BWC_ExceptionUtils.handleException(e, 'BWC_OpusLICMsgController: ', null);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
                                                       e.getMessage() + ':::' + e.getStackTraceString()));
            return (null);
        }
    }
}
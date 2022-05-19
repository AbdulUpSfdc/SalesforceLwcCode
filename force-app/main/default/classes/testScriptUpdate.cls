public with sharing class testScriptUpdate {

    public static String ASSOCIATED_BANS_SEPARATOR = ':';
    public static String PROCESSED_STATUS = 'Processed';
    public static void processCGData(List<CG_Data_Sync__c> dataSyncLst) {

        Map<String, DataSyncInfo> individualIdDataSyncInfoMap = new Map<String, DataSyncInfo>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<String> individualIdSet = new Set<String>();
        Set<String> allAssociatedBans = new Set<String>();
        for(CG_Data_Sync__c sync : dataSyncLst){

            System.debug('*** CG_Data_Sync__c'+sync);

            accountIdSet.add(sync.Customer__c);
            individualIdSet.add(sync.Individual_ID__c);

            if(String.isNotBlank(sync.Associated_BANS__c)){
                allAssociatedBans.addAll(sync.Associated_BANS__c.split(ASSOCIATED_BANS_SEPARATOR));
            }

            if(individualIdDataSyncInfoMap.containsKey(sync.Individual_ID__c)){

                // Store accountIds of duplicate accounts. For reparenting and deletion
                individualIdDataSyncInfoMap.get(sync.Individual_ID__c).otherAccountIds.add(sync.Customer__c);
                continue;
            }

            DataSyncInfo syncInfo = new DataSyncInfo();
            syncInfo.associatedBans = sync.Associated_BANS__c;
            syncInfo.associatedBansSet = new Set<String>(syncInfo.associatedBans.split(ASSOCIATED_BANS_SEPARATOR));
            syncInfo.accountId = sync.Customer__c;
            syncInfo.individualId = sync.Individual_ID__c;
            syncInfo.otherAccountIds = new Set<Id>();
            syncInfo.customerAccountExistenceMap = new Map<String, CustomerAccountExistence>();
            syncInfo.primaryBan = sync.Primary_BAN__c;
            syncInfo.firstName = sync.First_Name__c;
            syncInfo.lastName = sync.Last_Name__c;
            syncInfo.email = sync.Person_Email__c;
            syncInfo.phone = sync.Phone__c;


            System.debug('*** syncInfo wrapper: '+syncInfo);

            individualIdDataSyncInfoMap.put(sync.Individual_ID__c, syncInfo);
        }

        System.debug('*** individualIdDataSyncInfoMap : '+ JSON.serialize(individualIdDataSyncInfoMap));
        
        List<Account> allAccounts = [SELECT Id, Individual_ID__c FROM Account WHERE Individual_ID__c IN :individualIdSet];
        for(Account acc : allAccounts){
            
            if(individualIdDataSyncInfoMap.containsKey(acc.Individual_ID__c)){
                String accountId = individualIdDataSyncInfoMap.get(acc.Individual_ID__c).accountId;
               	individualIdDataSyncInfoMap.get(acc.Individual_ID__c).otherAccountIds.add(accountId);
                individualIdDataSyncInfoMap.get(acc.Individual_ID__c).otherAccountIds.remove(acc.Id);
               	individualIdDataSyncInfoMap.get(acc.Individual_ID__c).accountId = acc.Id;
                accountIdSet.add(acc.Id);
            }
            
        }

        // Querying all the Customer Account Relation records and group them by accountId
        Map<Id, List<Customer_Account_Relation__c>> carsByAccountId = new Map<Id, List<Customer_Account_Relation__c>>();
        List<Customer_Account_Relation__c> allCars = [SELECT
                                                        Id,
                                                        Customer__c,
                                                        Customer__r.Primary_BAN__c,
                                                        Billing_Account__c,
                                                        Billing_Account__r.Billing_Account_Number__c
                                                    FROM Customer_Account_Relation__c
                                                    WHERE Customer__c IN :accountIdSet];

        for(Customer_Account_Relation__c car : allCars){

            if(!carsByAccountId.containsKey(car.Customer__c)){
                carsByAccountId.put(car.Customer__c, new List<Customer_Account_Relation__c>());
            }

            carsByAccountId.get(car.Customer__c).add(car);
        }

        System.debug('*** All Customer Account Relation: '+ JSON.serialize(carsByAccountId));

        //Query all the Billing account
        Map<String, Billing_Account__c> banBillingAccountMap = new Map<String, Billing_Account__c>();
        List<Billing_Account__c> billingAccounts = [SELECT
                                                        Id, Billing_Account_Number__c
                                                    FROM Billing_Account__c
                                                    WHERE Billing_Account_Number__c IN :allAssociatedBans];

        for(Billing_Account__c billAcc : billingAccounts){
            banBillingAccountMap.put(billAcc.Billing_Account_Number__c, billAcc);
        }

        System.debug('*** Billing Accounts: '+ JSON.serialize(banBillingAccountMap));

        // Query the related record for all of the accounts. Used to reparent the records in case of duplicate accounts
        Map<Id, List<Interaction__c>> interactionsByAccountId = new Map<Id, List<Interaction__c>>();
        List<Interaction__c> allInteractions = [SELECT
                                                        Id,
                                                        Customer__c
                                                    FROM Interaction__c
                                                    WHERE Customer__c IN :accountIdSet];
        for(Interaction__c interaction : allInteractions){

            if(!interactionsByAccountId.containsKey(interaction.Customer__c)){
                interactionsByAccountId.put(interaction.Customer__c, new List<Interaction__c>());
            }

            interactionsByAccountId.get(interaction.Customer__c).add(interaction);
        }

        System.debug('*** Interactions by Customer: '+JSON.serialize(interactionsByAccountId));

        Map<Id, List<Case>> casesByAccountId = new Map<Id, List<Case>>();
        List<Case> allCases = [SELECT
                                    Id,
                                    AccountId
                                FROM Case
                                WHERE AccountId IN :accountIdSet];

        for(Case cs : allCases){

            if(!casesByAccountId.containsKey(cs.AccountId)){
                casesByAccountId.put(cs.AccountId, new List<Case>());
            }

            casesByAccountId.get(cs.AccountId).add(cs);
        }

        System.debug('*** Cases by Customer: '+JSON.serialize(casesByAccountId));

        Map<Id, List<Asset>> assetsByAccountId = new Map<Id, List<Asset>>();
        List<Asset> allAssets = [SELECT
                                        Id,
                                        AccountId
                                    FROM Asset
                                    WHERE AccountId IN :accountIdSet];
        for(Asset asset : allAssets){

            if(!assetsByAccountId.containsKey(asset.AccountId)){
                assetsByAccountId.put(asset.AccountId, new List<Asset>());
            }

            assetsByAccountId.get(asset.AccountId).add(asset);
        }

        System.debug('*** Assets by Customer: '+JSON.serialize(assetsByAccountId));

        for(DataSyncInfo dataSync : individualIdDataSyncInfoMap.values()){

            // Existing Customer Account Relation records
            List<Customer_Account_Relation__c> cars = carsByAccountId.get(dataSync.accountId);
            System.debug('*** CARS for customer: '+cars);

            Set<Customer_Account_Relation__c> carsToDelete = new Set<Customer_Account_Relation__c>();
            Set<Customer_Account_Relation__c> carsToInsert = new Set<Customer_Account_Relation__c>();

            if(cars != null){
               	// Get junction object that are not needed. Keep track of the existing junction records
                for(Customer_Account_Relation__c car : cars){
    
                    //If value not found in associatedBansSet, delete
                    if(!dataSync.associatedBansSet.contains(car.Billing_Account__r.Billing_Account_Number__c)){
                        carsToDelete.add(car);
                        continue;
                    }
    
                    // To track that we already have a junction object for the current billing account
                    CustomerAccountExistence carExistence = new CustomerAccountExistence();
                    carExistence.ban = car.Billing_Account__r.Billing_Account_Number__c;
                    carExistence.billingAccountId = car.Billing_Account__c;
    
                    dataSync.customerAccountExistenceMap.put(car.Billing_Account__r.Billing_Account_Number__c, carExistence);
    
                } 
            }
            
            System.debug('*** CARS to delete: '+carsToDelete);

            // Create missing junction records
            for(String ban : dataSync.associatedBansSet){

                CustomerAccountExistence carExistence = dataSync.customerAccountExistenceMap.get(ban);

                // If an associatedBan is found in the map, that means there's an existing junction record
                if(carExistence!=null){
                    continue;
                }

                // If carExistence is not in the map, that means we need to create a new junction record
                Billing_Account__c billAcc = banBillingAccountMap.get(ban);
                
                if(billAcc == null){
                    System.debug('Billing Account does not exist: '+ban);
                    continue;
                }
                
                String externalId = dataSync.accountId +''+ billAcc.Id;
                carsToInsert.add(new Customer_Account_Relation__c(
                    Billing_Account__c = billAcc.Id,
                    Customer__c = dataSync.accountId,
                    External_Id__c = externalId,
                    Role__c = BWC_Constants.ACCOUNT_RELATIONSHIP)
                );
            }
            System.debug('*** CARS to insert: '+carsToInsert);

            if(!carsToInsert.isEmpty()){
                insert new List<Customer_Account_Relation__c>(carsToInsert);
            }

            System.debug('*** otherAccountIds: '+JSON.serialize(dataSync.otherAccountIds));
            // No other accounts were found, go to the next iteration
            if(dataSync.otherAccountIds.isEmpty()){
                continue;
            }

            // Other accounts were found, retrieve Interaction, Assets & Cases associated with them
            // and update the Account Lookup
            Set<Interaction__c> otherInteractions = new Set<Interaction__c>();
            Set<Case> otherCases = new Set<Case>();
            Set<Asset> otherAssets = new Set<Asset>();

            System.debug('*** About to get related records from other accounts: '+JSON.serialize(dataSync.otherAccountIds));
            for(Id otherAccountId : dataSync.otherAccountIds){

                List<Interaction__c> interactions = interactionsByAccountId.get(otherAccountId);
                List<Case> cases = casesByAccountId.get(otherAccountId);
                List<Asset> assets = assetsByAccountId.get(otherAccountId);
                List<Customer_Account_Relation__c> currentCars = carsByAccountId.get(otherAccountId);

                System.debug('*** interactions: '+interactions);
                System.debug('*** cases: '+cases);
                System.debug('*** assets: '+assets);
                System.debug('*** currentCars: '+currentCars);

                if(interactions != null){
                    otherInteractions.addAll(interactions);
                }

                if(cases != null){
                    otherCases.addAll(cases);
                }

                if(assets != null){
                    otherAssets.addAll(assets);
                }

                if(currentCars != null){
                    carsToDelete.addAll(currentCars);
                }
            }

            System.debug('*** otherInteractions: '+JSON.serialize(otherInteractions));
            System.debug('*** otherCases: '+JSON.serialize(otherCases));
            System.debug('*** otherAssets: '+JSON.serialize(otherAssets));
            System.debug('*** otherCars: '+JSON.serialize(carsToDelete));


            // Reparenting Interactions
            for(Interaction__c interaction : otherInteractions){
                interaction.Customer__c = dataSync.accountId;
            }

            // Reparenting Cases
            for(Case cs : otherCases){
                cs.AccountId = dataSync.accountId;
            }

            // Reparenting Cases
            for(Asset asst : otherAssets){
                asst.AccountId = dataSync.accountId;
            }

            if(!otherInteractions.isEmpty()){
                update new List<Interaction__c>(otherInteractions);
            }


            if(!otherCases.isEmpty()){
                update new List<Case>(otherCases);
            }

            if(!otherAssets.isEmpty()){
                update new List<Asset>(otherAssets);
            }

            // Delete Junction record associated with duplicate PErson Account.
            // When the person account is different
            if(!carsToDelete.isEmpty()){
                delete new List<Customer_Account_Relation__c>(carsToDelete);
            }

            // Creating duplicate Account instances
            List<Account> toDeleteAccounts = new List<Account>();
            for(Id accId : dataSync.otherAccountIds){
                toDeleteAccounts.add(new Account(Id=accId, Ownership=null));
            }

            System.debug('*** Accounts to delete: '+JSON.serialize(toDeleteAccounts));


            // Delete Person Account. TODO: do we need to delete the other accounts?
            List<Database.SaveResult > results = Database.update(toDeleteAccounts, false);

            for(Database.SaveResult res : results){

                for(Database.Error err : res.errors){
                    System.debug(err.getMessage()+'-'+err.getFields());
                }
            }

        }

        List<Account> accs = new List<Account>();
        for(DataSyncInfo dataSync : individualIdDataSyncInfoMap.values()){
            accs.add(new Account(Id=dataSync.accountId,
                Individual_ID__c = dataSync.individualId,
                FirstName = dataSync.firstName,
                LastName = dataSync.lastName,
                PersonEmail = dataSync.email,
                Phone = dataSync.phone
            ));
        }
        System.debug('*** Accounts to update: '+JSON.serialize(accs));

        List<Database.SaveResult> results = Database.update(accs, false);
        for(Database.SaveResult res : results){

            for(Database.Error err : res.errors){
                System.debug(err.getMessage()+'-'+err.getFields());
            }
        }

        for(CG_Data_Sync__c sync : dataSyncLst){
            sync.Status__c = PROCESSED_STATUS;
        }

        System.debug('*** CG_Data_Sync__c to update: '+JSON.serialize(dataSyncLst));

        update dataSyncLst;

    }

    public class DataSyncInfo {
        public String associatedBans;
        public Set<String> associatedBansSet;
        public Id accountId;
        public String individualId;
        public Map<Id, Billing_Account__c> billingAccountMap;
        public Set<Id> otherAccountIds; //Store other accountIds that have the same individualId in the cg data sync object
        public Map<String, CustomerAccountExistence> customerAccountExistenceMap;
        public String primaryBan;
        public String firstName;
        public String lastName;
        public String phone;
        public String email;
    }

    public class CustomerAccountExistence {
        public String ban;
        public Id billingAccountId;
    }
}
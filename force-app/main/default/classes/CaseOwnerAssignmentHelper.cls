/***********************************************************************************************************************************************
 *  @Author     :wkhan
 *  @File Name  : CaseOwnerAssignmentHelper
 *  @Version    : V0.0
 *  @Description: This Class contains Case related logic
 *  @TestClass  : CaseOwnerAssignmentHelperTest
 *  @History
 * ----------------------------------------------------------------------------------------------------------------------------------------------
 *
 ***********************************************************************************************************************************************/
global with sharing class CaseOwnerAssignmentHelper
{
    public static final String CASE_MERGED_STATUS = CaseConstants.CASE_STATUS_MERGED;
    public static final String CASE_STATUS_CANCELLED = CaseConstants.CASE_STATUS_CANCELLED;
    public static final List<String> BUSINESS_WIRELINES = CaseConstants.BUSINESS_WIRELINES;
    public static final List<String> CONSUMER_WIRELINES = CaseConstants.CONSUMER_WIRELINES;

    //Method use by aura component
    @AuraEnabled
    public static void reassignOOPQueue(String caseId){

        Boolean hasAllFieldsUpdateOwner = validateUpdateOwner(caseId);

        if(!hasAllFieldsUpdateOwner){
            throw new AuraHandledException(Label.BWC_OOP_Update_Owner_Error);
        }
        Boolean hasRelatedCases = checkHasRelatedCases(caseId);

        if(hasRelatedCases){
            throw new AuraHandledException(Label.BWC_OOP_Related_Cases_Error);
        }

        try{
            List<Id> caseIdList = new List<Id>();
            caseIdList.add(caseId);
            //assignOOPQueue(caseIdList);
            initiateOOPCaseOwnerProcess(caseIdList,true);
        }catch(Exception ex){
            AuraHandledException genericException=new AuraHandledException(ex.getDmlMessage(0)+'');
            genericException.setMessage(ex.getDmlMessage(0)+'');
            throw genericException;
        }

    }

    public static boolean checkHasRelatedCases(String caseId){
        Id csId = Id.valueOf(caseId);

        List<Id> caseIds = new List<Id>{csId};
        Case cs = BWC_Case_Selector.getCasesById(caseIds)[0];
        Integer result = DaysToClose.countOpenCasesForSameCustomer(cs.Account.Name, caseId, cs.Billing_Account__c);

        return result > 0;
    }


    //Method use by Process builder only at the time of OOP creation
    @InvocableMethod
    public static void assignOOPQueue(List<Id> caseIdList){

       /*  List<Case> caseList = [Select Id, Owner.Name, OwnersRole__c,Status,Routing_Override__c,Priority,SubmissionSourceCode__c,Billing_Account__c,Product__c,OwnerId,Origin,
                                        description,ServicePhone__c,ServiceEmail__c,ServiceCustFirstName__c,ServiceCustLastName__c,StreetName__c,City__c,ZipPostalCode__c,
                                        Cust_Type__c from Case where Id IN :caseIdList];

       List<Case> caseListtoUpdate = caseOwnerAssignment(caseList, null);
        update caseListtoUpdate; */

       initiateOOPCaseOwnerProcess(caseIdList,false);

    }

    //initial method
    public static void initiateOOPCaseOwnerProcess(List<Id> caseIdList, Boolean eligibleByPass){
        List<Case> caselst = getOOPCases(caseIdList);
        if(caselst.size()>0){
            oopCaseOwnerAssignment(caselst,eligibleByPass);
        }
    }

    //OOP Case owner Assignment
    public static void oopCaseOwnerAssignment(List<Case> cases, Boolean eligibleByPass)
    {
        System.debug('@@@@@@@@@@@@MK + IN MAIN ASSIGNMent');
        List<Case> caseListforOwnerAssignment = new List<Case>();

        for (Case caseRec: cases){
            System.debug('@@@@@@@@@@@@ case id + IN MAIN ASSIGNMent'+caseRec.Id);

            if(!eligibleByPass){
                if(CheckEligibilityforAssignment(caseRec)){

                    if(( (caseRec.OwnersRole__c==CaseConstants.ROLE_INTAKE_AGENT || caseRec.OwnersRole__c==CaseConstants.ROLE_INTAKE_ADMIN  )
                              && (caseRec.Status==CaseConstants.NEW_STATUS  ||caseRec.Status==CaseConstants.IN_PROGRESS_STATUS  ))

                        ||(caseRec.Routing_Override__c!=CaseConstants.CASE_ROUTING_OVERRIDE_INTAKE  && (string.isBlank(caseRec.OwnersRole__c) || caseRec.OwnersRole__c== 'OOP Admin') &&string.isNotBlank(caseRec.Priority))
                     ){
                        caseListforOwnerAssignment.add(caseRec);
                    }
                }
                else if( (caseRec.Routing_Override__c==CaseConstants.CASE_ROUTING_OVERRIDE_INTAKE || caseRec.SubmissionSourceCode__c==CaseConstants.R_FCC_REBUTTAL ||caseRec.SubmissionSourceCode__c==CaseConstants.BR_BBB_REBUTTAL)|| (string.isBlank(caseRec.SubmissionSourceCode__c) || string.isBlank(caseRec.Cust_Type__c) || String.isBlank(caseRec.Billing_Account__c) || string.isBlank(caseRec.Origin ) ||string.isBlank(caseRec.Description))){
                    caseListforOwnerAssignment.add(caseRec);
                }
            }
            else{
                caseListforOwnerAssignment.add(caseRec);
            }
        }

        if(!caseListforOwnerAssignment.isEmpty()){
            processCaseOwner(caseListforOwnerAssignment);
        }

    }


    //Process case owner
    public static void processCaseOwner(List<Case> cases){
        List<Case> updateCaselst = new List<Case>();
        Set<Id> billingAccountIds = new Set<Id>();
        Map<Id,Billing_Account__c> caseRelatedBillingAcct = new Map<Id,Billing_Account__c>();

        for(Case c : cases){
            if(String.isNotBlank(c.Billing_Account__c)){
                System.debug('+++++++^^^^^'+c.Billing_Account__c);
                billingAccountIds.add(c.Billing_Account__c);
            }
        }


        if(billingAccountIds.size()>0){
            caseRelatedBillingAcct = retrieveBillingAccts(billingAccountIds);
        }

        Map<Id, List<Case>> billAcctCasesMap = billingAccountIds.isEmpty()? new Map<Id, List<Case>>():getbillingAccountsCaseMap(billingAccountIds);

        List<OOP_Case_Owner_Queue_Assignment__mdt> metaDataReclIst = [SELECT Matching_Criteria__c, Order__c, Products__c, Queue__c FROM OOP_Case_Owner_Queue_Assignment__mdt];

        Map<string, Group> queueNameWithIdMap = retrieveQueueNameWithIdMap();

        for (case caseRec: cases){
            boolean isEligible = CheckEligibilityforAssignment(caseRec);
           // string queueName = CaseConstants.OOP_QUEUE_DTVLOW;
            string queueName = CaseConstants.INTAKEQUEUE;

            // Product matching with meta data
            set<String> caseProducts = string.isBlank(caseRec.Product__c)?new Set<string>():new set<String>(caseRec.Product__c.split(';'));
            System.debug('---------CaseProducts='+caseProducts );
            string productMatchingQueueName;

            //Products check with happen only if products is filled in on case -isEligible
            if(caseProducts.size()>0){
                productMatchingQueueName = getProductMatchingQueueName(caseProducts, metaDataReclIst);
            }

            /* LOGIC for DTV
               1) CHECKING products First and if products are related to video
               2) CHECKING - are there any additional cases related to billing account
            */

            if(string.isNotBlank(productMatchingQueueName ))
            {
                System.debug('inside Product matching---');
                //If source code is 4R-FCC Rebuttal OR 7BR-BBB Rebuttal ,Then assign it to DTVIntakeReassignment queue
                if(caseRec.SubmissionSourceCode__c!=null && (caseRec.SubmissionSourceCode__c==CaseConstants.R_FCC_REBUTTAL || caseRec.SubmissionSourceCode__c==CaseConstants.BR_BBB_REBUTTAL)){
                    queueName = CaseConstants.OOP_QUEUE_DTVINTAKEREASSIGNMENT;
                }

                //If there are additional cases with same billing account then assigns to DTV Intake Queue
                else if(!billAcctCasesMap.isempty() && (billAcctCasesMap.containsKey(caseRec.Billing_Account__c) &&  billAcctCasesMap.get(caseRec.Billing_Account__c).Size() >1)){
                    queueName = CaseConstants.OOP_QUEUE_DTVINTAKE; // Should assign to OOP_DTVINTAKE queue only not an reassignment
                }

                /*
                if the below fields are blank then it should assign to DTVINTAKE
                description
                ServicePhone__c
                ServiceEmail__c
                ServiceCustFirstName__c
                ServiceCustLastName__c
                StreetName__c
                City__c
                ZipPostalCode__c
                SubmissionSourceCode__c
                Cust_Type__c -- coming from Billing Account Customer Type and its formula
                Origin
                State__c
                */
                else if (!isEligible || String.isBlank(caseRec.Description) || caseRec.Send_to_Intake_Queue__c) {
                    queueName = productMatchingQueueName;
                }
                //if case priority is VIP then Assign to DTV VIP Queue
                else if (caseRec.Priority.contains(CaseConstants.CASE_PRIORITY_VIP)) {
                    queueName = CaseConstants.OOP_QUEUE_DTVVIP ;
                }
                //if case priority is HIGH Assign to DTV High queue
                else if (caseRec.Priority.contains(CaseConstants.CASE_PRIORITY_HIGH) ||caseRec.Priority.contains(CaseConstants.CASE_PRIORITY_OUT_OF_SRV)){
                    queueName = CaseConstants.OOP_QUEUE_DTVHIGH ;
                }
                else if(caseRec.SubmissionSourceCode__c!=null && (caseRec.SubmissionSourceCode__c==CaseConstants.SS_4D_FCC_Disability_Rights || caseRec.SubmissionSourceCode__c==CaseConstants.SS_4_FCCs || 
                        caseRec.SubmissionSourceCode__c==CaseConstants.SS_2L_Legal || caseRec.SubmissionSourceCode__c==CaseConstants.SS_3A_Agency_not_a_Commission || caseRec.SubmissionSourceCode__c==CaseConstants.SS_3C_State_Commission || 
                        caseRec.SubmissionSourceCode__c==CaseConstants.SS_3G_Attorney_General || caseRec.SubmissionSourceCode__c==CaseConstants.SS_5A_Board_of_Director)){
                    queueName = CaseConstants.OOP_QUEUE_DTVREGULATORY;
                }
                //if case priority is MEDIUM OR LOW then Assign to DTV High queue
                else{
                    queueName = CaseConstants.OOP_QUEUE_DTVLOW;
                }
                caseRec.Product_Type_OOP__c = CaseConstants.CASE_VIDEO_TYPE_OF_OOP;
                System.debug('!!!!!!!!!!!QueueName='+queueName);
            }
            //If source code is 4R-FCC Rebuttal OR 7BR-BBB Rebuttal ,Then assign it to IntakeReassignedQueue queue
            else if(caseRec.SubmissionSourceCode__c!=null && (caseRec.SubmissionSourceCode__c==CaseConstants.R_FCC_REBUTTAL || caseRec.SubmissionSourceCode__c==CaseConstants.BR_BBB_REBUTTAL)){
                queueName = CaseConstants.OOP_QUEUE_INTAKEREASSIGNEDQUEUE;
            }

            // Billing account has more than 1 cases
            else if(isEligible && (!billAcctCasesMap.isempty() && billAcctCasesMap.containsKey(caseRec.Billing_Account__c) &&  billAcctCasesMap.get(caseRec.Billing_Account__c).Size()>1)){
                queueName = CaseConstants.INTAKEQUEUE; // Should assign to OOP_INTAKE queue only not an reassignment
                System.debug('!!!!!!!!!!!Account does have othere cases='+queueName);

            }
            else if ( isEligible && (billAcctCasesMap.isempty() ||( billAcctCasesMap.containsKey(caseRec.Billing_Account__c) &&  billAcctCasesMap.get(caseRec.Billing_Account__c).Size() <2))){
                System.debug('!!!!!!!!!!!Account does not have othere cases='+queueName);
                // VIP - if priority is VIP and no billing account / billing account had one case related
                if (caseRec.Priority ==CaseConstants.CASE_PRIORITY_VIP ){
                    queueName =CaseConstants.OOPVIP;
                }
                // OOP HighPriority
                else if (caseRec.Priority ==CaseConstants.CASE_PRIORITY_HIGH){
                    queueName =CaseConstants.OOP_HIGH_PRIORITY;
                }
                // language is spanish
                else if (caseRec.Language == CaseConstants.SPANISH_CODE){
                    queueName = CaseConstants.OOP_SPANISH;
                }
                // Others
                else{
                    if(String.isBlank(caseRec.Product__c)){
                        queueName =CaseConstants.OOPLOWPRIORITY ;
                    }
                    //String billAccountCustomerType;

                    /*if(!caseRelatedBillingAcct.isempty() && String.isNotBlank(caseRec.Billing_Account__c) && (caseRelatedBillingAcct.containsKey(caseRec.Billing_Account__c) )){
                        billAccountCustomerType = caseRelatedBillingAcct.get(caseRec.Billing_Account__c).Customer_Type__c;
                    }*/

                        //caseRec.Cust_Type__c == CaseConstants.CONSUMER
                        //BUSINESS_WIRELINES.contains(caseRec.Cust_Type__c)
                        //&& String.isBlank(CaseRec.Fan__c) --- US # 4224 is commented
                        if (checkForNonWirelessProduct(caseProducts) && (String.isNotBlank(caseRec.Cust_Type__c) && caseRec.Cust_Type__c == CaseConstants.CONSUMER && String.isBlank(caseRec.FAN__c))){
                            queueName =CaseConstants.OOP_CONSUMER_WIRELESS;
                            System.debug('checking 1');

                        }else if (checkForNonWirelessProduct(caseProducts) && (String.isNotBlank(caseRec.Cust_Type__c) && caseRec.Cust_Type__c == CaseConstants.CONSUMER && !String.isBlank(caseRec.FAN__c))){

                            queueName = CaseConstants.OOP_BUSINESS_MOBILITY ;
                            System.debug('checking 2: '+queueName);
                        }
                        else if (BUSINESS_WIRELINES.contains(caseRec.Cust_Type__c)){
                            queueName = CaseConstants.OOP_BUSINESS_WIRE_LINE ;
                            System.debug('checking 3');
                        }
                        else{
                           queueName =CaseConstants.OOPLOWPRIORITY ;
                           System.debug('checking 4');

                        }
                    }

                 System.debug('!!!!!!!!!!!QueueName='+queueName);
            }
            else{

               queueName = CaseConstants.INTAKEQUEUE;
                System.debug('!!!!!!!!!!!intake queue='+queueName);

            }
            //System.debug('!!!!!!!!!!!QueueName='+queueName);
            System.debug('!!!!!!!!!!!Queue Map='+queueNameWithIdMap.containsKey(queueName));
            System.debug('!!!!!!!!!!!QueueName='+queueName);

            if (queueName!=null && queueNameWithIdMap.containsKey(queueName) && (caseRec.Ownerid != queueNameWithIdMap.get(queueName).Id))
            {
                System.debug('@@@@@@@@@@@@MK + Before Owner Assignment'+caseRec.Ownerid);

                caseRec.Ownerid = queueNameWithIdMap.get(queueName).Id;
                caseRec.Workgroup__c = queueNameWithIdMap.get(queueName).Name;
                system.debug(queueNameWithIdMap.values());
                system.debug(queueName);
                system.debug(queueNameWithIdMap.get(queueName));
                System.debug('@@@@@@@@@@@@MK + After Owner Assignment'+caseRec.Ownerid);
                updateCaselst .add(caseRec);
                System.debug('@@@@@@@@@@@@MK + IN MAIN ASSIGNMent'+updateCaselst );
            }
        }
        system.debug('before update');
        if(updateCaselst.size()>0){
            update updateCaselst;
        }

    }
// if product list contains a non wireless product it is considered not to be a
    public static Boolean checkForNonWirelessProduct(set<string> productList){
            Boolean containsNonWirelessProduct = false;
            for(string product : productList ){

                if(CONSUMER_WIRELINES.contains(product)){
                    containsNonWirelessProduct=true;
                }
                else if(!CONSUMER_WIRELINES.contains(product)){
                    containsNonWirelessProduct = false;
                    break;
                }
            }
            return containsNonWirelessProduct;
    }




    //Retrieve all OOP cases
    public static List<Case> getOOPCases(List<Id> caseIds){
        List<Case> caseList = [Select Id, Owner.Name, OwnersRole__c,Status,Routing_Override__c,Priority,SubmissionSourceCode__c,Billing_Account__c,Product__c,OwnerId,Origin,
                                description,ServicePhone__c,ServiceEmail__c,ServiceCustFirstName__c,ServiceCustLastName__c,StreetName__c,State__c,City__c,ZipPostalCode__c,
                                Cust_Type__c,Send_to_Intake_Queue__c,Product_Type_OOP__c,Language,Fan__c,Workgroup__c from Case where Id IN :caseIds];

        return caseList;
    }

    //Logic to check eligibility
    private static boolean CheckEligibilityforAssignment(Case caseRec){

        boolean eligible = false;
        if(string.isNotBlank(caseRec.ServiceCustFirstName__c )&&
                        string.isNotBlank(caseRec.ServiceCustLastName__c )&&
                        string.isNotBlank(caseRec.StreetName__c )&&
                        string.isNotBlank(caseRec.City__c )&&
                        string.isNotBlank(caseRec.State__c )
                        /*US-7820 string.isNotBlank(caseRec.ServiceEmail__c )&&
                        string.isNotBlank(caseRec.ServicePhone__c )*/){

               eligible=true;
           }

        return eligible;
    }



    /*
    * Method to get Case product matching queuename from meta data
    * @author               - wkhan
    * @param caseProducts   - set of Case product names
    * @param metaDataProductRolesList- Metadata info product with matching queue
    * @return matchingProductQueueName- string queue name
    */

    public static string getProductMatchingQueueName(set<String> caseProducts,
                                                     List<OOP_Case_Owner_Queue_Assignment__mdt> metaDataProductRolesList)
    {
        String matchingProductQueueName = '';
        for (OOP_Case_Owner_Queue_Assignment__mdt metaDataRec : metaDataProductRolesList)
        {
            set<String> metadataProducts = new set<String>(metaDataRec.Products__c.Split(';'));
            system.debug('-----MetaData Products='+metadataProducts );
            system.debug('-----caseProducts--='+caseProducts);
            if ((metaDataRec.Matching_Criteria__c == CaseConstants.ALL_OR_ANY) &&
                metadataProducts.containsAll(caseProducts))
            {
                matchingProductQueueName = metaDataRec.Queue__c;
            }
        }
        System.debug('!!!matchingProductQueueName--'+matchingProductQueueName);
        return matchingProductQueueName;
    }


    /*
    * Method to get retrieve Queue Id based on queue API name
    * @author                - wkhan
    * @param                 - n/a
    * @return queueNameIdMap - map of queue name with  Id
    */


    // retrieve Queue Id based on queue API name
    public static Map<string, Group> retrieveQueueNameWithIdMap()
    {
        Map<string, Group> queueNameIdMap = new Map<String, Group>();
        for (Group grp : [SELECT Id, Name,DeveloperName FROM Group WHERE Group.Type = 'Queue'])
        {

            queueNameIdMap.put(grp.DeveloperName, grp);
        }
        return (queueNameIdMap);
    }
    /*
    * Method to get billing account related cases
    * @author                   - wkhan
    * @param  billingAccountIds - set of billing account ids from Case
    * @return billAcctCasesMap  - map of account with list of case
    */

    public static map<id, List<Case>> getbillingAccountsCaseMap(set<id> billingAccountIds)
    {

        Map<Id, List<Case>> billAcctCasesMap = new Map<Id, List<Case>>();
        Date closeDate = Date.today().addDays(-Integer.valueOf(System.Label.Opp_Case_Days_to_Close.trim()));
        for (Case casRec : [SELECT Id, Billing_Account__c, Billing_Account__r.Customer_Type__c,CaseNumber, ParentId, ClosedDate, Status FROM Case
                            WHERE ParentId = NULL
                                AND(ClosedDate = NULL OR ClosedDate >= : closeDate)
                                AND(Status != : CASE_STATUS_CANCELLED AND Status != : CASE_MERGED_STATUS)
                                AND RecordType.Name = : CaseConstants.OOP_RECORD_TYPE
                                AND Billing_Account__c = : billingAccountIds])
        {

           if(String.isNotBlank(casRec.Billing_Account__c)){
                if (!billAcctCasesMap.containsKey(casRec.Billing_Account__c) )
                {
                    billAcctCasesMap.put(casRec.Billing_Account__c, new List<Case> { casRec });
                }
                else
                {
                    billAcctCasesMap.get(casRec.Billing_Account__c).add(casRec);
                }
           }
        }
         //system.debug('------------billAcctCasesMap'+billAcctCasesMap);
        return billAcctCasesMap;
    }

    //retrieve billing accounts based on Billing accoutn Ids
    public static Map<Id, Billing_Account__c> retrieveBillingAccts(Set<id> billingAccountIds){

        Map<Id,Billing_Account__c> billingAcctMap = new Map<Id,Billing_Account__c>([Select Id, Customer_Type__c
                                                                                        FROM Billing_Account__c
                                                                                        WHERE Id IN :billingAccountIds]);

        return billingAcctMap;
    }
    //US-7820 validating update owner button required fields check.
    public static boolean validateUpdateOwner(String caseId){

        boolean result = false;
        List<Case> caselst = [select ServiceCustFirstName__c,ServiceCustLastName__c,StreetName__c,City__c,State__c, ZipPostalCode__c from case where id=:caseId limit 1];
        if(caselst.size()>0){
            for(Case caseInfo : caselst)
            {
                if(string.isNotBlank(caseInfo.ServiceCustFirstName__c )&&
                   string.isNotBlank(caseInfo.ServiceCustLastName__c )&&
                   string.isNotBlank(caseInfo.StreetName__c )&&
                   string.isNotBlank(caseInfo.City__c )&&
                   string.isNotBlank(caseInfo.State__c )&&
                   string.isNotBlank(caseInfo.ZipPostalCode__c ))
                {

                    result = true;
                }
            }
        }
        return result;
    }



}
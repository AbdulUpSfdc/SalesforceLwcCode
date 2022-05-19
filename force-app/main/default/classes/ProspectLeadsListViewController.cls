/**
 * This class contains all the functionality for the Prospect Leads tab
 */
public without sharing class ProspectLeadsListViewController {
    /**
     * This method is ussed to get the various campaigns supported by Prospct Leads
     * @Return -> List<String> -> List of Campaigns to display on Prospect Leads Page
     */
    @AuraEnabled
    public static List<String> getLeadListPickListValues(){
        Schema.DescribeFieldResult fieldResult = Lead.LeadListName__c.getDescribe();

        System.debug('**** fieldResult *** '+fieldResult);
        List<Schema.PicklistEntry> lstPicklistValues = fieldResult.getPicklistValues();

        System.debug('**** lstPicklistValues *** '+lstPicklistValues);
        List<String> lstLeadListNames = new List<String>();
        for(Schema.PicklistEntry pe : lstPicklistValues){
            lstLeadListNames.add(pe.getValue());
        }
        System.debug('**** lstLeadListNames *** '+lstLeadListNames);
        return lstLeadListNames;
    }

    /**
     * This method is used to fetch the default values for filters stored in custom metadata
    */
    @AuraEnabled
    public static map<String,String> getDefaultValues(){
        Map<String,String> mapDefaultValues = new Map<String,String>();
        List<Prospect_Leads_Filter_Default__mdt> defaultFilters = [SELECT Id, FieldName__c, FieldOperator__c, fieldType__c, FieldValue__c FROM Prospect_Leads_Filter_Default__mdt];
        String strDefaultValue ='';
        Map<String, Prospect_Leads_Filter_Default__mdt> defaultFiltersMap = new Map<String, Prospect_Leads_Filter_Default__mdt>();
        for(Prospect_Leads_Filter_Default__mdt defaultFilter: defaultFilters){
            if(defaultFilter.FieldValue__c == NULL)
                mapDefaultValues.put(defaultFilter.FieldName__c,strDefaultValue);
            else
                mapDefaultValues.put(defaultFilter.FieldName__c, defaultFilter.FieldValue__c);
        }
        System.debug('*******mapDefaultValues *******'+ mapDefaultValues);
        return mapDefaultValues;
    }

    @AuraEnabled
    public static Map<String,List<String>> getOtherPickListValues(List<String> lstStrFieldNames){
        List<String> lstLeadType = new List<String>{'Business','Consumer'};
        Map<String,List<String>> mapFieldNameVSLstValues = new Map<String,List<String>>();
        mapFieldNameVSLstValues.put('LeadType__c',lstLeadType);
        return mapFieldNameVSLstValues;
        
    }

    /**
     * This method is used to fetch the initial filters for Prospects
    */
    @AuraEnabled
    public static ProspectLeadsListViewController.dataWrap getInitValues(List<String> lstStrFieldNames){
        ProspectLeadsListViewController.dataWrap dataWrap = new ProspectLeadsListViewController.dataWrap();
        dataWrap.mapDefaultValues = getDefaultValues();
        dataWrap.mapFieldNameVSLstValues = getOtherPickListValues(lstStrFieldNames);
        return dataWrap;
    }

    /**
     * This method fetches the Prospect Leads based on various filters selcted
     * @Parameter -> String strListFilterOptions -> Various filters for SOQL
     * @Return -> LeadWrapper -> A wrappeed that contains List of Prospects to be displayed in front end and the count
    */    
    @AuraEnabled
    public static LeadWrapper getLeadsByFilterNew(String strListFilterOptions){
        List<Lead> lstLead= new List<Lead>();
        LeadWrapper leadWrap = new LeadWrapper();
        
        String leadQuerySelect =  ProspectLeadsUtil.leadQuerySelect ;
        String leadQueryCount = ProspectLeadsUtil.leadQueryCount ;
        String queryWhereClause = ProspectLeadsUtil.getPropsectWhereClause(50, 0, string.escapeSingleQuotes(strListFilterOptions));
        
        System.debug('lead query is-->>'+leadQuerySelect);
        System.debug('queryWhereClause is-->>'+queryWhereClause);
        System.debug('leadOrderBy is-->>'+ProspectLeadsUtil.leadOrderBy);
        System.debug('leadLimitClause is-->>'+ProspectLeadsUtil.leadLimitClause);
        System.debug('leadOffsetClause is-->>'+ProspectLeadsUtil.leadOffsetClause);

        leadQuerySelect += ' '+queryWhereClause+' '+ProspectLeadsUtil.leadOrderBy + ' '
                              +ProspectLeadsUtil.leadLimitClause+' 50 '+ProspectLeadsUtil.leadOffsetClause+' 0';
        leadQueryCount += ' '+queryWhereClause ;

        System.debug('lead count query is-->>'+leadQueryCount);

        lstLead = database.query(leadQuerySelect);
        leadWrap.lstLead = lstLead;
        AggregateResult[] results = database.query(leadQueryCount);
        if(results != null && results.size() > 0) {
            leadWrap.totalRecords = Integer.valueOf(results[0].get('cnt'));
        }
        return leadWrap;
    }

    /**
     * This method is used to return additional records when load more is clicked
     * @Parameters -> Integer rowLimit -> Maximum number of rows to be returned, 
     *                Integer rowOffset -> Identifies the numebr of times load more is clicked, 
     *                String strListFilterOptions -> Various filters for SOQL
     * @Return -> List<Lead> -> List of Prospects to be displayed in front end
    */
    @AuraEnabled
    public static List<Lead> lazyLoadLeads(Integer rowLimit, Integer rowOffset, String strListFilterOptions) {
        List<Lead> lstLead= new List<Lead>();
        String leadQuerySelect =  ProspectLeadsUtil.leadQuerySelect ;
        String queryWhereClause = ProspectLeadsUtil.getPropsectWhereClause(50, 0, string.escapeSingleQuotes(strListFilterOptions));
        
        leadQuerySelect += ' '+queryWhereClause+' '+ProspectLeadsUtil.leadOrderBy + ' '
                              +ProspectLeadsUtil.leadLimitClause+' '+rowLimit+' '+ProspectLeadsUtil.leadOffsetClause+' '+rowOffset;

        System.debug('lead query is:'+leadQuerySelect);

        lstLead = database.query(leadQuerySelect);
        return lstLead;    
    }

    /**
     * This method returns a boolean value to evaluate if the Employee Location filter needs to be displayed
     * This filter has to be enableed for s subset of profiles 
     * @Return -> Boolean -> To identify if the Employee Location filter needs to be displayed
    */
    @AuraEnabled
    public static Boolean isProfileForStoreSelect(){
        Boolean isStoreSelect = false;
        Set<String> lstStrProfile = new Set<String>{'System Administrator','Bellwether User','Retail ARSM'};
        User userProfile = [SELECT Id,Name,Profile.Name FROM  User WHERE id=:UserInfo.getUserId()];
        if(lstStrProfile.contains(userProfile.Profile.Name)){
            system.debug('********* isprof'+userProfile.Profile.Name );
            isStoreSelect = true;
        }
        system.debug('******* isStoreSelect ******'+isStoreSelect);
        return isStoreSelect;
    }
    
    /**
     * This method gets the Store__c record based  on the id passed in parameter
     * @Parameter -> String strStoreId -> Id of the Store to be fetched
     * @Return -> Store__c -> Store record fetched
    */
    @AuraEnabled
    public static Store__c getStore(String strStoreId){ 
        if(String.isNotBlank(strStoreId)){
            List<Store__c>  lstStore = new List<Store__c>();
            lstStore = [SELECT id,Name FROM Store__c 
                        WHERE id=:strStoreId WITH SECURITY_ENFORCED];
            if(!lstStore.isEmpty() && lstStore.size() > 0){
                return lstStore[0];
            }
        }
        return null;
    }

    /**
     * This method is used to get the Maximum possible Proximity filter
     * The Value is stored in custom setting to ease the limit when requiredin Production
     * @Return -> Integer -> MAximum Proximity to be allowed
    */
    @AuraEnabled
    public static Integer getMaxProximity(){ 
        if(RetailConstants.MAX_PROXIMITY != null)  {
            try {
                return Integer.valueOf(RetailConstants.MAX_PROXIMITY);
            } catch(Exception e) {
                return 50;
            }        
        } else {
            return 50;
        }
    }

    // Wrapper classes
    
    /* Wrapper to return lead initial result along with count */
    public class LeadWrapper {
        @AuraEnabled
        public Integer totalRecords = 0;
        @AuraEnabled
        public List<Lead> lstLead = new List<Lead>();
        public LeadWrapper(){

        }
    }

    /* Wrapper to return Default Lead Values */
    public class dataWrap {
        @AuraEnabled
        public Map<String,String> mapDefaultValues = new Map<String,String>();
        @AuraEnabled
        public Map<String,List<String>> mapFieldNameVSLstValues = new Map<String,List<String>>();
        public dataWrap(){

        }
    }
}
/**
 * @description       : Model class to help with Duplicate matching on leads
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-15-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   01-07-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
public without sharing class DuplicateMatcher {

 private Map <Integer,Lead> leadMap;                                              // It is a map containing the Trigger.New ArrayIndex as key & Lead as value
 private Id digitalrecTypeId;                                                     // Record type id for Digital leads
 private Set<ID> newLeadsIdSet = new Set<ID>();                                   // It is a set of LeadsIds being processed
 private Boolean isUpdate;                                                        // Boolean to know its an update or insert operation
 
 private Map<Integer,Integer> phoneHashMap = new Map<Integer,Integer>();          // It is a map containing the Trigger.New ArrayIndex as key & HashCode as value
 private Map<Integer,Integer> mobileHashMap = new Map<Integer,Integer>();         // It is a map containing the Trigger.New ArrayIndex as key & HashCode as value
 private Set<Integer> phoneHashForCompare = new Set<Integer>();                   //It is a set containing the matched HashCode for Phone Number field
 private Set<Integer> mobileHashForCompare = new Set<Integer>();                  //It is a map containing the matched HashCode for Mobile Phone Number field
                           
 
 private Set<String> phones = new Set<String>();                                  // It is a set of all phone numbers for Non DCI Leads
 private Set<String> mobiles = new Set<String>();                                 // It is a set of all Mobilephone numbers for Non DCI Leads
 private Set<String> phones_dci = new Set<String>();                              // It is a set of all phone numbers for DCI Leads
 private Set<String> mobiles_dci = new Set<String>();                             // It is a set of all Mobile phone numbers for DCI Leads

 public Set<Integer> errorIndexes;                                                // It is a set containing all array indexes(Tirgger.New) for duplicate leads
 
 /**
  * It is a set containing all the success hash values. 
  * This allows us to check for duplicates inside a batch chunk itself. 
  * If 2 leads are submitted with the same phone number, only 1 is saved.              
  */
 public Set<Integer> successHash; 
    
    /**
     * @description:    Constructor method. 
     *                  Checks if Lead.Status!=Closed for passed SobjectMap and initializes,fills leadMap
     */
    public DuplicateMatcher(Map <Integer,Lead> passedLeadMap, Id digitalrecTypeId, Set<ID> newLeadsIds, Boolean isUpdate) {
        this.digitalrecTypeId = digitalrecTypeId;
        this.leadMap = passedLeadMap;
        this.newLeadsIdSet = newLeadsIds;
        this.isUpdate = isUpdate;
    }
    
    /**
     * @description:    Calls the different functions to do the actual searching, flagging duplicates
     */
    public void doMatching(){

        fillUpInitialSetsAndMaps();
        runQueryAndFillUpCompareMaps();
        getErrorRecords();

    }
    
    /**
     * @description:    Fills up all the Initial sets and HashMaps.
     */
    public void fillUpInitialSetsAndMaps(){
        String hashPhone;      //String to hold the hashvalue for phone
        String hashMobile;     //String to hold the hashvalue for mobile
        
        /**
         * String to differentiate DCI and NON DCI leads. We add it to hash map to aid comparisons
         * Example 12345DCI and 12345NonDCI will yield in different hashcodes and hence they will not match as potential dupes
         * All the Non DCI record types are clubbed into NonDCI, so they will match against each other although they are from different record types
         */
        String recordName;           
        
        if(leadMap.size()>0){
            for (Integer i: leadMap.keySet()){
                Lead lead = leadMap.get(i);
                //Fill up different sets for digital record types and non digital recordd types
                System.debug('Lead Record Type Id:'+lead.recordTypeId+'Digital Record Type Id'+digitalrecTypeId);
                if(lead.recordTypeId==digitalrecTypeId){
                    //Fill up sets for use in query later
                    recordName = 'DCI';
                    if(lead.Phone!=null) {
                        phones_dci.add(lead.Phone);
                        //Fill up HashMap. This will be used for comparisions later.
                        //We add Record Type here so it always matches
                        hashPhone=lead.Phone + recordName;
                        phoneHashMap.put(i,hashPhone.hashCode());
                    }
                    if(lead.MobilePhone!=null){
                        mobiles_dci.add(lead.MobilePhone);
                        hashMobile=lead.MobilePhone + recordName;
                        mobileHashMap.put(i,hashMobile.hashCode());
                    } 
                }else{
                    //Fill up sets for use in query later
                    recordName = 'NonDCI';
                    if(lead.Phone!=null) {
                        phones.add(lead.Phone);
                        hashPhone=lead.Phone + recordName;
                        phoneHashMap.put(i,hashPhone.hashCode());
                    }    
                    if(lead.MobilePhone!=null){
                        mobiles.add(lead.MobilePhone);
                        hashMobile=lead.MobilePhone + recordName;
                        mobileHashMap.put(i,hashMobile.hashCode());
                    } 
                }
            }          
        }
        else{
            System.debug('Lead Map is null');
        }

        System.debug('Phone Hash Map is:'+phoneHashMap);
        System.debug('Mobile Hash Map is:'+mobileHashMap);
        System.debug('phones is:'+phones);
        System.debug('mobiles is:'+mobiles);
        System.debug('phones dci is:'+phones_dci);
        System.debug('mobile dci is:'+mobiles_dci);
        //Run cleanUpAllSets to remove nulls from all the sets.
        // cleanUpAllSets();
    }

    /**
     * @description:    Searches the database for potential matches and fills up relevant compare Maps
     */
    public void runQueryAndFillUpCompareMaps(){
        List<Lead> leads;

        //First work with Non DCI Leads
        if((phones.size()==0)&&(mobiles.size()==0)){
            System.debug('Phone and Mobile is missing. Nothing to check for consumer leads');
        }else{
            System.debug('Inside Query -->Consumer');
            //Get Potential duplicates by running query against database
            leads = getPotentialDuplicates(phones,mobiles,false,digitalrecTypeId,leadMap.keySet());
            //Fill up relevant compare maps
            fillUpCompareMaps(leads, false);
        }
          
        //Now work with DCI leads only
        if((phones_dci.size()==0)&&(mobiles_dci.size()==0)){
            System.debug('Phone and Mobile is missing. Nothing to check for digital leads');
        }else{
            System.debug('Inside Query DCI');
            //Get Potential duplicates by running query against database
            leads = getPotentialDuplicates(phones_dci,mobiles_dci,true,digitalrecTypeId,leadMap.keySet());
            //Fill up relevant compare maps
            fillUpCompareMaps(leads, true);
        }
    }

    /**
     * @description:    Forms the query for search, runs the query and returns list of potential lead matches
     *                  The potential lead matches will be checked again in fillUpCompareMaps to associate them with duplicate leads
     */
    public List<Lead>  getPotentialDuplicates(Set<String> phones,Set<String> mobiles, Boolean isDigital, Id digitalrecTypeId, Set<Integer> leadSet){    
        String query ='Select Id,Phone,MobilePhone,Store__c,CreatedDate from Lead where ';
        
        //Get Array size in integer variables so that we can use them in multiple comparisons.
        Integer phones_size = phones.size();
        Integer mobiles_size = mobiles.size();
        
        
        if((phones_size>0)&&(mobiles_size==0)){
            query+=' Phone IN: phones';
        }else if((phones_size==0)&&(mobiles_size>0)){
            query+=' MobilePhone IN: mobiles';
        }else{
            query+=' (Phone IN: phones OR MobilePhone IN: mobiles )';
        }

        //Add appropriate record types in filter criteria
        if(!isDigital){
            query+=' AND RecordTypeId !=\''+digitalrecTypeId+'\'';
        }else{
            query+=' AND RecordTypeId =\''+digitalrecTypeId+'\'';
        }
        
        //Only Leads with Status!=Closed are checked
        query+=' AND Status!=\'Closed\'';

        //Ignore the LeadIds of current Batch for update operation only
        if(newLeadsIdSet.size()>0 && isUpdate){
            query+=' AND ID Not IN :newLeadsIdSet';
        }
        System.debug('query is:'+query);
        
        //Initialize List of Leads for return
        List<Lead> leads = new List<Lead>();
        
        //Run the Query to fetch potential lead matches
        try {
            leads = Database.query(query);
        }
        catch (Exception e) {
            System.debug(e);
            //Send exception to Exception__c custom object for further handling
            //BWC_ExceptionUtils.handleException(e, true);
        }

        System.debug('Leads is'+leads);
        return leads;
    }

    /**
     * @description:    Fill up Compare maps with Has Value for comparison later.
     */
    public void fillUpCompareMaps(List<Lead> leads, Boolean isDigital){
        String recordName;   //Suffix for hashcode based on record type
        String concatPhone;  //String to hold concatenated value or phone and recordName before hashing
        String concatMobile; //String to hold concatenated value or mobile and recordName before hashing

        //If the method is called from digital part of the comparison logic, add suffix DCI to Hashcode else add NonDCI
        if(isDigital){
            recordName = 'DCI';
        }else{
            recordName = 'NonDCI';
        }

        //Loop through leads and fill up comparemaps with hash values
        for(Lead lead:leads){
            if(lead.Phone!=null){
                //Concat phone and Record Name. Record Name values are DCI and NonDCI
                concatPhone = lead.Phone + recordName;
                phoneHashForCompare.add(concatPhone.hashCode());
            }
            if(lead.MobilePhone!=null){
                concatMobile = lead.MobilePhone + recordName;
                mobileHashForCompare.add(concatMobile.hashCode());
            }   
        }
    }

    /**
     * @description:    Compare lead records with Compare hash and get error ids
     */
    public void getErrorRecords(){
        errorIndexes = new Set<Integer>();
        successHash  = new Set<Integer>(); 

        
            Integer phoneHashCurrent;  //Contains PhoneHash of current lead
            Integer mobileHashCurrent; //Contains MobileHash of current lead
            
            for(Integer arrayIndex : leadMap.keySet()){
                phoneHashCurrent=phoneHashMap.get(arrayIndex);
                mobileHashCurrent=mobileHashMap.get(arrayIndex);

                //System.debug(successHash);
                if((phoneHashForCompare.contains(phoneHashCurrent))|| 
                   (mobileHashForCompare.contains(mobileHashCurrent)) || 
                   (successHash.contains(phoneHashCurrent))||
                   (successHash.contains(mobileHashCurrent))
                  ){ 
                 //If current hash value is found in compareHash Sets or successHash Sets, it is a duplicate   
                    errorIndexes.add(arrayIndex);    
                }
                else{
                    System.debug('Inside writing Success Hash. Phone Hash Current is:'+phoneHashCurrent+'MobileHashCurrent is:'+mobileHashCurrent);
                    //If Duplicate is not found, write the Hash map to successHash for future validations
                    //This helps us prevent duplicates inside of a bulk chunk
                    if(phoneHashCurrent!=null){
                        successHash.add(phoneHashCurrent);
                    }
                    if(mobileHashCurrent!=null){
                        successHash.add(mobileHashCurrent);
                    }        
                }

                
                System.debug(phoneHashCurrent);
                System.debug(mobileHashCurrent);
                System.debug(phoneHashForCompare);
                System.debug(mobileHashForCompare);

            }
        

        System.debug('Error Ids is:'+errorIndexes);
    }

}
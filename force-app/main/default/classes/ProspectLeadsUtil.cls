/**
 * This classs contains the various utility methods for Prospect functionality
 * @Author: Reshma Jewrani
 */
public with sharing class ProspectLeadsUtil {
    //Static variables to form SOQL that don't change
    public static final String leadQuerySelect = 'SELECT  Name,  MobilePhone, LeadStrength__c, ProductsDiscussed__c, CustomerType__c, LeadSource, OtherNotes__c, Proximity__c, Company, Street, City, Country, State, PostalCode, ExpiryDate__c, PreferredMethodofContact__c, Store__r.Name, Store__c FROM Lead ';
    public static final String leadQueryCount = 'SELECT count(id) cnt FROM Lead ';
    public static final String leadOrderBy = ' ORDER BY Proximity__c ASC ';
    public static final String leadLimitClause = ' LIMIT ';
    public static final String leadOffsetClause = ' OFFSET ';
    /**
     * This is a wrapper class created to process the filters coming from the front ends
    */
    public class filterOptions {
        public String name;
        public String value;
    }

    /**
     * This method forms the WHERE clause of the SOQL to be used for quering thr prospect Leads
     * @Parameters - Integer rowLimit -> the maximum numebr of records to be returned,
     *               Integer rowOffset -> Offset to retrieve data absed onhow many times sthe load more has been clicked, 
     *               String strListfilterOptions -> Various filter options selected inf ront end
     * @Return - String -> WHERE clause of the SOQL
    */
    public static String getPropsectWhereClause(Integer rowLimit, Integer rowOffset, String strListfilterOptions) {
        String strStoreId; String queueId = ''; String queryWhereClause = '';  
        Integer proximity; Double storeLat; Double storeLong;
        Group unassignedProspectsQueue ;
        UserCurrentLocation__c userLocationSettting;
        
        userLocationSettting = UserCurrentLocation__c.getInstance(); 
        

        queryWhereClause = ' WHERE RecordTypeId = \''+ RetailConstants.PROSPECT_RECORDTYPEID +'\'';
        
        unassignedProspectsQueue = [SELECT Id, Type FROM Group WHERE Type = 'Queue' AND Name = :RetailConstants.PROSPECT_QUEUE LIMIT 1];
        if(unassignedProspectsQueue != null){
            queueId = unassignedProspectsQueue.Id;
            if(String.isNotBlank(queueId)){
                queryWhereClause += ' AND OwnerId = \''+ queueId  +'\' ';
            }
        }

        queryWhereClause +=  ' AND Status != \''+RetailConstants.CLOSED+'\' AND LeadSource =  \'' +RetailConstants.LEAD_SOURCE_BUSINESS +'\' ';

        if(String.isNotBlank(strListfilterOptions)) {
            System.debug('***** strListfilterOptions  '+strListfilterOptions);
            
            List<Prospect_Leads_Filter_Default__mdt> defaultFilters = [SELECT Id, FieldName__c, FieldOperator__c, fieldType__c, FieldValue__c FROM Prospect_Leads_Filter_Default__mdt];

            Map<String, Prospect_Leads_Filter_Default__mdt> defaultFiltersMap = new Map<String, Prospect_Leads_Filter_Default__mdt>();
            for(Prospect_Leads_Filter_Default__mdt defaultFilter: defaultFilters) {
                defaultFiltersMap.put(defaultFilter.FieldName__c, defaultFilter);
            }
            
            List<filterOptions> filOps = (List<filterOptions>)JSON.deserialize(strListfilterOptions, List<filterOptions>.class);
            System.debug('filters:'+JSON.serialize(filOps));
            
            for(filterOptions filter: filOps) {
                if(String.isNotBlank(filter.name)) {
                    String fieldValue = filter.value;
                    //Set Store from user's selection
                    if(filter.name == 'Store__c') {
                       strStoreId = fieldValue;
                       fieldValue = '';
                    }
                    if(String.isNotBlank(fieldValue)){
                        String multiSelectValues = '';
                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Picklist (Multi-Select)'){
                            multiSelectValues = '(';
                            if(fieldValue.contains(',')){
                                for(String value : fieldValue.split(',')){
                                    multiSelectValues = multiSelectValues + '\'' + value + '\',';
                                }
                                multiSelectValues = multiSelectValues.removeEnd(',');
                            }else {
                                multiSelectValues = multiSelectValues + '\'' + fieldValue + '\'';
                            }
                            multiSelectValues = multiSelectValues + ')';
                            
                            System.debug('picklist field Value'+ multiSelectValues);
                        }
                        
                        System.debug('field Value'+ fieldValue);
                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Text' && filter.name != 'MobilePhone'){
                            queryWhereClause += ' AND ' + filter.name + ' ' + defaultFiltersMap.get(filter.name).FieldOperator__c + ' ';
                            queryWhereClause += '\''  + String.escapeSingleQuotes(fieldValue) + '\'';
                        }

                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Double'){
                            queryWhereClause += ' AND ' + filter.name + ' ' + defaultFiltersMap.get(filter.name).FieldOperator__c + ' ';
                            queryWhereClause += Double.valueOf(fieldValue);
                        }

                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Integer'){
                            queryWhereClause += ' AND ' + filter.name + ' ' + defaultFiltersMap.get(filter.name).FieldOperator__c + ' ';
                            queryWhereClause += Integer.valueOf(fieldValue);
                        }
                        
                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Text' && filter.name == 'MobilePhone'){
                            fieldValue = fieldValue.replaceAll('[^a-zA-Z0-9\\s+]', '');
                            fieldValue = fieldValue.replaceAll( '\\s+', '');
							System.debug('Mobile Phone  ======> '+fieldValue);
                            queryWhereClause += ' AND ' + filter.name + ' ' + defaultFiltersMap.get(filter.name).FieldOperator__c + ' ';
                            queryWhereClause += '\''  + String.escapeSingleQuotes(fieldValue) + '\'';
                        }

                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Search Text'){
                            queryWhereClause += ' AND ' + filter.name + ' ' + defaultFiltersMap.get(filter.name).FieldOperator__c + '\'%';
                            queryWhereClause += String.escapeSingleQuotes(fieldValue);
                            queryWhereClause += '%\' ';
                        }

                        if(defaultFiltersMap.containsKey(filter.name) && defaultFiltersMap.get(filter.name).fieldType__c == 'Picklist (Multi-Select)' && String.isNotBlank(multiSelectValues)){
                            queryWhereClause += ' AND ' + filter.name + ' ' + defaultFiltersMap.get(filter.name).FieldOperator__c + ' ' + multiSelectValues;
                        }

                        if(filter.name.equalsIgnoreCase('Proximity__c')) {
                            proximity = Integer.valueOf(fieldValue);
                        }
                    }
                }
            }
        }
        if(strStoreId != null) { 
            userLocationSettting = putUserLocationInCustomSetting(strStoreId);
        }
        if(proximity != null) {
            storeLat = userLocationSettting.Latitude__c ;
            storeLong = userLocationSettting.Longitude__c;
            if(storeLat != null &&  storeLong != null) {
                map<String, Double> proximityMap = getProximityBoundary(storeLat, storeLong, proximity);
                if(proximityMap != null) {
                    queryWhereClause += ' AND latitude >= ' +proximityMap.get('minLat') +
                                            ' AND latitude <= ' +proximityMap.get('maxLat') +
                                            ' AND longitude >= ' +proximityMap.get('minLon') +
                                            ' AND longitude <= ' +proximityMap.get('maxLon') + ' ';
                }
            } else {
                throw new RetailError.ClientSideException(System.Label.ProspectStoreError);
            }
        }
        System.debug('lead query wher clause is:'+queryWhereClause);
        
        return queryWhereClause;
    }

    /*
     * This method puts the lat, long value of store in the custom setting to calculate Proximity for logged in user
    */
    public static UserCurrentLocation__c putUserLocationInCustomSetting(String strStoreId){
        UserCurrentLocation__c userCurrLoc = UserCurrentLocation__c.getInstance(UserInfo.getUserId());
        if(String.isNotBlank(strStoreId)){
            List<Store__c>  lstStore = new List<Store__c>();
            lstStore = [SELECT GeoLocation__c FROM Store__c 
                        WHERE id=:strStoreId WITH SECURITY_ENFORCED];
            if(!lstStore.isEmpty() && lstStore.size() > 0){
                userCurrLoc.Store__c  = lstStore[0].id;
                if(lstStore[0].GeoLocation__c <> NULL){
                    Location gLoc = lstStore[0].GeoLocation__c;
                    System.debug('**** userCurrLoc '+userCurrLoc);
                    userCurrLoc.Latitude__c = gLoc.Latitude;
                    userCurrLoc.Longitude__c = gLoc.Longitude;
                    System.debug('**** userCurrLoc '+userCurrLoc);
                    if(userCurrLoc.id != NULL) {
                        update userCurrLoc;
                    } else {
                        insert userCurrLoc;
                    }
                }
            }
        }
        return userCurrLoc;
    }

    /**
     * This method utilises the Spherical laws of Cosine to get the minimum, maximum latitude and longitude for given radius
     * These min, max values are used to add additional filters to the SOQL to further optimise the results
     * @Parameters -> Double lat -> latitude to calculate min, max values
     *                Double lon -> longitude to calculate min, max values
     *                Integer radius -> radius to calculate min, max values
     * @ Return -> map<String, Double> -> various minimum and maximum latitude longitude values added in the map
    */
    public static map<String, Double> getProximityBoundary(Double lat, Double lon, Integer radius) {
        map<String, Double> boundaryMap = new map<String, Double>();
        if(lat != null && lon != null && radius != null) {
            Double maxLat = lat + (RetailUtil.radianToDegree(radius/RetailConstants.EARTH_RADIUS));
            Double minLat = lat - (RetailUtil.radianToDegree(radius/RetailConstants.EARTH_RADIUS));
            Double cosOfLat = 1;
            if(lat != 90)
                cosOfLat =(MATH.cos(RetailUtil.degreeToRadian(lat)));
            Double maxLon = lon + (RetailUtil.radianToDegree((MATH.asin(radius/RetailConstants.EARTH_RADIUS)) / cosOfLat));
            Double minLon = lon - (RetailUtil.radianToDegree((MATH.asin(radius/RetailConstants.EARTH_RADIUS)) / cosOfLat));
            boundaryMap.put('minLat',minLat);
            boundaryMap.put('maxLat',maxLat);
            boundaryMap.put('minLon',minLon);
            boundaryMap.put('maxLon',maxLon);
            
            system.debug('minLat-->'+minLat);
            system.debug('maxLat--->'+maxLat );
            system.debug('minLon-->'+minLon);
            system.debug('maxLon--->'+maxLon );
        }

        return boundaryMap;
    }
}
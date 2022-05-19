/*-----------------------------------------------------------------------------
This class takes a List of Asset. Break it based on Group_ID__c field then 
sort each group based on Phone_Number__c field. It also check for primary record in 
the list. it will put the group with primary record on the top of the list. 

Assumption
Only one record in the list should have isprimary=true. If more then fail.
All the record should have groupby field populated. Blank field will be treated 
as another group.
All Phone number field should be string integer. Without formated.

History
<Date>       <Authors Name>     <Brief Description of Change>

-----------------------------------------------------------------------------*/
public with sharing class BWC_EquipmentGroupSortUtil {
    public BWC_EquipmentGroupSortUtil() {

    }

    /*-------------------------------------------------------------------------
    This method responsible to break it based on Group_ID__c field then 
    sort each group based on Phone_Number__c field. It also check for primary record in 
    the list. it will put the group with primary record on the top of the list. Also
    as required by UI after each group in the List there will an empty row.

    @param List<Asset>
    @return List<Asset> sorted list based on Phone_Number__c.
    // Equipment are now stored in Asset object, so get list of Assets and sort it.
    ------------------------------------------------------------*/
    public static List<Asset> groupSort(List<Asset> assets) {
        List<Asset> groupSortedAssets = new List<Asset>();
        List<Asset> tmpAssets;

        Set<String> groupIdSet = new Set<String>(); //store all  group ids
        String primaryGroupId; //store the primary group id

        // Lets find 1) how many groups 2) primary group id.
        // Keep track of primary asset so that we can add it to the top of Asset (Devices) list
        // displayed on the Person Account
        Asset primaryAsset = null;
        for (Asset asset : assets) {
            groupIdSet.add(asset.Group_ID__c);
            if (asset.Is_Primary__c) {
                primaryAsset = asset;
                primaryGroupId = asset.Group_ID__c;
            }
        }

        //Lets process the primary group first
        tmpAssets =  new List<Asset>();
        
        for (Asset asset : assets) {
            // Add the primary group assets but ignore primary asset as we will add primary asset at top.
            if (asset.Group_ID__c == primaryGroupId && (primaryAsset == null || primaryAsset.Id != asset.Id)) {
                tmpAssets.add(asset);
            }
        }
        //Sort the primary group list tmpAssets = Sort(tmpAssets);
        tmpAssets = sortAssets(tmpAssets);

        // Add the primaryAsset first to display it  on top and then add remaining  Asset (Devices) 
        if (primaryAsset != null) {
            groupSortedAssets.add(primaryAsset);
        }
        groupSortedAssets.addAll(tmpAssets);
        
        // Remove the primary group id as its already processed
        groupIdSet.remove(primaryGroupId);

        for (String groupId : groupIdSet) {

            tmpAssets =  new List<Asset>();
            for (Asset asset : assets) {
                if (asset.Group_ID__c == groupId) {
                    tmpAssets.add(asset);
                }
            }

            //sort the group list tmpAssets = Sort(tmpAssets);
            tmpAssets = sortAssets(tmpAssets);
            groupSortedAssets.addAll(tmpAssets);
        }

        return groupSortedAssets;
    }

    /*-------------------------------------------------------------------------
    This method act as a transformer. As we need to sort a SObject based on field
    We have written a Wrapper class by impliment Comparable. But we have to sort 
    the Original List. So in this method we pass the original list. its responsible
    to transform to Wrapper, sort it and transform back to original list.

    @param List<Asset>
    @return List<Asset> sorted list based on Phone_Number__c.
    ------------------------------------------------------------*/
    private static List<Asset> sortAssets(List<Asset> assets) {

        List<AssetWrapper> assetWrappers = new List<AssetWrapper>();
        for (Asset asset : assets) {
            assetWrappers.add(new AssetWrapper(asset));
        }
        assetWrappers.sort();
        
        List<Asset> groupSortedAssets = new List<Asset>();
        for (AssetWrapper assetWrapper : assetWrappers) {
            groupSortedAssets.add(assetWrapper.asset);
        }

        return groupSortedAssets;
    }

    /*To implement a custom sort order for sObjects in lists, create a wrapper
     class for the sObject and implement the Comparable interface. The wrapper
     class contains the sObject in question and implements the compareTo method,
     in which you specify the sort logic
    */
    // Wrapper class to hold Asset record and implement compareTo method.
    public  class AssetWrapper implements Comparable {
        public Asset asset;

        //Constructor
        public AssetWrapper(Asset asset) {
            this.asset = asset;
        }

         // Compare Asset based on the Asset Phone_Number__c.
        public  Integer compareTo(Object compareTo) {
            // Cast argument to AssetWrapper
            AssetWrapper compareToAsset = (AssetWrapper)compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (asset.Phone_Number__c != null && compareToAsset.asset.Phone_Number__c != null) {
                if (Long.valueOf(asset.Phone_Number__c) > Long.valueOf(compareToAsset.asset.Phone_Number__c)) {
                    // Set return value to a positive value.
                    returnValue = 1;
                } else if (Long.valueOf(asset.Phone_Number__c) < Long.valueOf(compareToAsset.asset.Phone_Number__c)) {
                    // Set return value to a negative value.
                    returnValue = -1;
                } 
            } else {
                if ((asset.Phone_Number__c == null) && (compareToAsset.asset.Phone_Number__c != null)) {
                    // nulls-first implementation
                    returnValue = 1;
                } else if ((asset.Phone_Number__c != null) && (compareToAsset.asset.Phone_Number__c == null)) {
                    // nulls-first implementation
                    returnValue = -1;
                } 
            }   
            return returnValue; 
        }
    }//End of AssetWrapper
}
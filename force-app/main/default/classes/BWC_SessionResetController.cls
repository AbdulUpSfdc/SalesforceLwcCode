/*
    Determines which console tabs should be forced closed upon a refresh login.
*/
public with sharing class BWC_SessionResetController {

    /*
        Inspects tab information from the console and determines which tabs should be automatically closed due to new session login.
    */
    @AuraEnabled
    public static String getTabsToClose(String tabInfosJson) {

        List<TabInfo> tabsToClose = new List<TabInfo>();

        // Custom permission prevents auto-close
        if (!FeatureManagement.checkPermission('Disable_Console_Session_Reset')) {

            List<TabInfo> tabInfos = (List<TabInfo>)JSON.deserialize(tabInfosJson, List<TabInfo>.class);

            // Find interaction tabs
            for (TabInfo tabInfo : tabInfos) {

                if (tabInfo.pageReference != null &&
                    tabInfo.pageReference.type == 'standard__recordPage' && 
                    tabInfo.pageReference.attributes.objectApiName == 'Interaction__c') {

                    tabsToClose.add(tabInfo);

                }

            }


        }
        return JSON.serialize(tabsToClose, true);

    }

    /*
        These classes allow deserialize of a subset of console TabInfo.
    */

    public class TabInfo {
        public String tabId;
        public PageReference pageReference;
    }

    public class PageReference {
        public String type;
        public PageReferenceAttributes attributes;
    }

    public class PageReferenceAttributes {
        public String objectApiName;
        public String recordId;
        public String actionName;
    }

}
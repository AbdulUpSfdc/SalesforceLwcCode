public without sharing class leadFollowupFieldUpdateBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        string query = 'Select  ProductsDiscussed__c, ProductsDiscussedInternet__c, ProductsDiscussedVideo__c,  ProductsDiscussedWireless__c from Lead ';
        query = query + ' where ProductsDiscussed__c != null AND ' ;
        query = query + ' ProductsDiscussed__c != \'\' AND Status!= \'Closed\'';
        query = query + '  AND (ProductsDiscussedWireless__c= null or ProductsDiscussedWireless__c= \'\')';
        query = query + '   AND (ProductsDiscussedVideo__c= null or ProductsDiscussedVideo__c= \'\')';
        query = query + ' AND (ProductsDiscussedInternet__c= null or ProductsDiscussedInternet__c= \'\') AND RecordType.Name!=\'Digital Check IN\'';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Lead> lstLead = (List<Lead>)scope;
        List<Lead> lstLeadUpdating = new List<Lead>();
        for(Lead l : lstLead){
            Boolean shouldUpdate = false;
            Boolean isWireless = false;
            Boolean isVideo = false;
            Boolean isInternet = false;
            l.ProductsDiscussedWireless__c = '';
            l.ProductsDiscussedInternet__c = '';
            l.ProductsDiscussedVideo__c = '';
            string strProductDiscussedNew=l.ProductsDiscussed__c;
            //l.ATT_Products__c = '';
            if(l.ProductsDiscussed__c.contains('Prepaid') 
               && !l.ProductsDiscussedWireless__c.containsignorecase('Prepaid;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'Prepaid;';
               }
            if(l.ProductsDiscussed__c.contains('Postpaid') 
               && !l.ProductsDiscussedWireless__c.containsignorecase('Postpaid;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'Postpaid;';
                   
               }
            if(l.ProductsDiscussed__c.contains('Post Paid Add A Line')
               && !l.ProductsDiscussedWireless__c.containsignorecase('Postpaid;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'Postpaid;';
               }
            if(l.ProductsDiscussed__c.contains('Accessories')
               && !l.ProductsDiscussedWireless__c.containsignorecase('Accessories;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'Accessories;';
               }
            if(l.ProductsDiscussed__c.contains('FirstNet')
               && !l.ProductsDiscussedWireless__c.containsignorecase('FirstNet;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'FirstNet;';
                   
               }
            if(l.ProductsDiscussed__c.contains('Protection')
               && !l.ProductsDiscussedWireless__c.containsignorecase('FirstNet;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'FirstNet;';
               }
            if(l.ProductsDiscussed__c.contains('FleetComplete')
               && !l.ProductsDiscussedWireless__c.containsignorecase('FirstNet;')){
                   isWireless = true;
                   l.ProductsDiscussedWireless__c = l.ProductsDiscussedWireless__c + 'FirstNet;';
               }
            if(l.ProductsDiscussed__c.contains('AT&T Internet')
               && !l.ProductsDiscussedInternet__c.containsignorecase('AT&T Broadband;')){
                   isInternet = true;
                   l.ProductsDiscussedInternet__c = l.ProductsDiscussedInternet__c + 'AT&T Broadband;';
               }
            if(l.ProductsDiscussed__c.contains('AT&T Broadband')
               && !l.ProductsDiscussedInternet__c.containsignorecase('AT&T Broadband;')){
                   isInternet = true;
                   l.ProductsDiscussedInternet__c = l.ProductsDiscussedInternet__c + 'AT&T Broadband;';
               }
            if(l.ProductsDiscussed__c.contains('AT&T Fiber')
               && !l.ProductsDiscussedInternet__c.containsignorecase('AT&T Fiber;')){
                   isInternet = true;
                   l.ProductsDiscussedInternet__c = l.ProductsDiscussedInternet__c + 'AT&T Fiber;';
               }
            
            if(l.ProductsDiscussed__c.contains('AT&T TV')
               && !l.ProductsDiscussedVideo__c.containsignorecase('AT&T TV;')){
                   isVideo= true;
                   l.ProductsDiscussedVideo__c = l.ProductsDiscussedVideo__c + 'AT&T TV;';
               }
            if(l.ProductsDiscussed__c.contains('DIRECTV')
               && !l.ProductsDiscussedVideo__c.containsignorecase('DIRECTV;')){
                   isVideo= true;
                   l.ProductsDiscussedVideo__c = l.ProductsDiscussedVideo__c + 'DIRECTV;';
               }
            if(l.ProductsDiscussed__c.contains('HBO Max')
               && !l.ProductsDiscussedVideo__c.containsignorecase('HBO Max;')){
                   isVideo= true;
                   l.ProductsDiscussedVideo__c = l.ProductsDiscussedVideo__c + 'HBO Max;';
               }
            if(l.ProductsDiscussed__c.contains('DTVNOW')
               && !l.ProductsDiscussedVideo__c.containsignorecase('DIRECTV;')){
                   isVideo= true;
                   l.ProductsDiscussedVideo__c = l.ProductsDiscussedVideo__c + 'DIRECTV;';
               }
            
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('FirstNet;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('FirstNet', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('FleetComplete;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('FleetComplete', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Protection;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Protection', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Accessories;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Accessories', '');
            
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T TV;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T TV', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T Fiber;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T Fiber', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T Broadband;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T Broadband', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T Internet;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('AT&T Internet', '');
            
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('DIRECTV;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('DIRECTV', '');
            
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('HBO Max;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('HBO Max', '');
            
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('DTVNOW;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('DTVNOW', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Prepaid;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Prepaid', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Postpaid;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Postpaid', '');
            
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Post Paid Add A Line;', '');
            strProductDiscussedNew = strProductDiscussedNew.replaceAll('Post Paid Add A Line', '');
            
            
            if(strProductDiscussedNew != '' && strProductDiscussedNew.endsWith(';')){
                l.ProductsDiscussed__c= strProductDiscussedNew;
            }
            else if(strProductDiscussedNew != '' && !strProductDiscussedNew.endsWith(';')){
                l.ProductsDiscussed__c= strProductDiscussedNew+';';
            }
            else{
                l.ProductsDiscussed__c= strProductDiscussedNew;
            }
            
            if(isWireless == true){
                shouldUpdate = true;
                l.ProductsDiscussed__c= l.ProductsDiscussed__c+'Wireless;';
            }
            if(isInternet == true){
                shouldUpdate = true;
                l.ProductsDiscussed__c = l.ProductsDiscussed__c+'Internet;';
            }
            if(isVideo == true){
                shouldUpdate= true;
                l.ProductsDiscussed__c = l.ProductsDiscussed__c+'Video;';
            }
            if(shouldUpdate == true){
                lstLeadUpdating.add(l);
            }
        }
        system.debug(lstLeadUpdating);
        update lstLeadUpdating;
        
    }
    public void finish(Database.BatchableContext BC){
    }
    
    
    
    
    
}
global without sharing class CustomLabelTranslatorController {

    private final static String GUEST_USER = 'GUEST';

    global List<String> labels { get; private set; }
    global String labelsCsv { get; set; }
    global String trgLang { get; set; }

    global CustomLabelTranslatorController() {   
        trgLang = ApexPages.currentPage().getParameters().get( 'LANG');
        if ( String.isBlank( trgLang ) ) {
            trgLang = 'en-US';
        }
        labelsCsv = Apexpages.currentPage().getParameters().get('labelsCsv');
        translateLabels();
    }

    @testVisible
    private static String getHost() {
        return URL.getCurrentRequestUrl().getHost();
    }

    global void translateLabels() {
        labels = new List<String>();
        if ( !String.isBlank( labelsCsv ) ) {
            for ( String lbl : labelsCsv.split( ',' ) ) {
                String l = lbl.trim();
                if ( !String.isBlank( l ) ) {
                    labels.add( lbl );
                }
            }
        }
    } 

    global String getLexOrigin() {
        if ( GUEST_USER == UserInfo.getUserType() ) {
            return 'https://' + getHost();
        }
        return URL.getOrgDomainUrl().toExternalForm().split('.my.')[0]+'.lightning.force.com';
    }

    @AuraEnabled(cacheable=true)
    global static string userType(){
        return UserInfo.getUserType().toUpperCase();
    }

    @AuraEnabled(cacheable=true)
    global static String visualforceOrigin(){
        if ( GUEST_USER == UserInfo.getUserType() ) {
            return 'https://' + getHost();
        }
        final String baseUrl = System.URL.getSalesforceBaseURL().toExternalForm();
        // base url - https://attone--ct360.my.salesforce.com
        // VF base: - https://attone--ct360--c.visualforce.com
        final String  vfBase = baseUrl.replaceAll( '\\..*$', '' ) + '--c.visualforce.com';
        return vfBase;
    }
}
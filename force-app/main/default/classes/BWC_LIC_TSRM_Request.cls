/* ================================================
* @class name: BWC_LIC_TSRM_Request
* @author: Salesforce Inc.
* @purpose: request class to supports TSRM client system integration
* @created date (mm/dd/yyyy) :  03/20/2021
================================================*/ 
public with sharing class BWC_LIC_TSRM_Request {

    public class TSRM_Request{
        string attuid;
        string alrtCallerVerifiedInd;
        //change to cti call id TO DO !!!!!!!
        string sfc_intrxn_objid;
        string siteName;
        string ctn;
        string alrtUserWorkgroup;
        string wban;
        //params ctn, interaction id, ban(billing account number), att user id
        public TSRM_Request(string ctn,string intid, string ban, string attuid) {
            Employee__c e = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
            Interaction__c i = BWC_Interaction_Selector.getInteraction(intid);
            this.ctn = ctn;
            this.attuid = attuid; 
            this.sfc_intrxn_objid = (i?.CTI_Call_Identifier__c == null)?null:i?.CTI_Call_Identifier__c.replace('_','');
            this.alrtCallerVerifiedInd = (i?.Wireless_Authorization_Level__c == 'L1')?'Yes':'No';
            this.alrtUserWorkgroup = e?.Sub_Channel__c;
            this.siteName = e?.Work_City__c + ' - '+e?.Sub_Channel__c;
            this.wban = ban;
        }
        //UnAuth request 
        public TSRM_Request(string intid, string attuid) {
            Employee__c e = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
            Interaction__c i = BWC_Interaction_Selector.getInteraction(intid);
            this.attuid = attuid;
            this.sfc_intrxn_objid = (i?.CTI_Call_Identifier__c == null)?null:i?.CTI_Call_Identifier__c.replace('_','');
            this.alrtCallerVerifiedInd = (i?.Wireless_Authorization_Level__c == 'L1')?'Yes':'No';
            this.alrtUserWorkgroup = e?.Sub_Channel__c;
            this.siteName = e?.Work_City__c + ' - '+e?.Sub_Channel__c;
        }
    }
}
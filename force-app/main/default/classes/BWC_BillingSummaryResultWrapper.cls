/* ================================================
* @author : Shoulat khan
* @date :   09/30/2020   
* @group : Billing Summary 
* @description : wrapper class to return result of Billing Summary Mulesoft call
================================================*/
public with sharing class BWC_BillingSummaryResultWrapper {

    public Boolean success {get; set;}
    public String message {get; set;}
    public BWC_BillingSummaryRespWrapper result {get; set;}

    public BWC_BillingSummaryResultWrapper() {

    }


}
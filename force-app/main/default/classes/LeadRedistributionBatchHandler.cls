/**
 * @description       : 
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-05-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   12-23-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
public with sharing class LeadRedistributionBatchHandler 
{
    private Map<Id,LeadRedistribution__c> employeeStoreChangeMap;     //Map to hold LR's created because of Employee Store Change scenario
    private Map<Id,LeadRedistribution__c> employeePromotionMap;       //Map to hold LR's created because of Employee Promotion scenario
    private Map<Id,LeadRedistribution__c> employeeOffboardMap;        //Map to hold LR's created because of Employee Offboard scenario
    private Map<Id,LeadRedistribution__c> employeeFloatingRemovedMap; //Map to hold LR's created because of Floating Employee removed scenario
    private Map<Id,LeadRedistribution__c> employeeDemotionMap;
    private Map<Id,LeadRedistribution__c> employeeCreatedMap;
    private List<LeadRedistribution__c> allLeadsList ;                //List of All Lead Redistribution Records
    private IEmployeeUpdateStrategy employeeStrategy;                 //Instance of Employee strategy used to run different strategies

    /**
     * @description:   Constructor method
     */
    public LeadRedistributionBatchHandler(List<LeadRedistribution__c> leadRedistributions){
        allLeadsList = leadRedistributions;
        employeeStoreChangeMap = new Map<Id,LeadRedistribution__c>();
        employeePromotionMap= new Map<Id,LeadRedistribution__c>();
        employeeOffboardMap= new Map<Id,LeadRedistribution__c>();
        employeeFloatingRemovedMap= new Map<Id,LeadRedistribution__c>();
        employeeDemotionMap= new Map<Id,LeadRedistribution__c>();
        employeeCreatedMap= new Map<Id,LeadRedistribution__c>();
    }

    /**
     *  @description:   Segregate all leads list into various maps based on scenarios
     */
    public void fillUpAllMaps(){
        for(LeadRedistribution__c lead_redistribution:allLeadsList){
            if(lead_redistribution.Reason__c=='Employee Home Store Change'){
                employeeStoreChangeMap.put(lead_redistribution.Id,lead_redistribution);
            }
            else if(lead_redistribution.Reason__c=='Employee Promotion'){
                employeePromotionMap.put(lead_redistribution.Id,lead_redistribution);
            }
            else if(lead_redistribution.Reason__c=='Employee Offboarded'){
                employeeOffboardMap.put(lead_redistribution.Id,lead_redistribution);
            }
            else if(lead_redistribution.Reason__c=='Floating Employee Removed'){
                employeeFloatingRemovedMap.put(lead_redistribution.Id,lead_redistribution);
            }
            else if(lead_redistribution.Reason__c=='Employee Demotion'){
                employeeDemotionMap.put(lead_redistribution.Id,lead_redistribution);
            }
            else if(lead_redistribution.Reason__c=='New Employee'){
                employeeCreatedMap.put(lead_redistribution.Id,lead_redistribution);
            }
            
        }
    }

    /**
     *  @description:   Run the 4 different strategies for the 4 different scenarios
     */
    public void runAllStrategies(){
        InitializeAndRunStrategy('Employee Home Store Change');
        InitializeAndRunStrategy('Employee Promotion');
        InitializeAndRunStrategy('Employee Offboarded');
        InitializeAndRunStrategy('Floating Employee Removed');
        InitializeAndRunStrategy('Employee Demotion');
        InitializeAndRunStrategy('New Employee');
    }

    /**
     *  @description:   Initialize and run a specific strategy based on strategy name passed. 
     *                  Everytime this method is called a new strategy instance is initiated and run.
     */
    public void InitializeAndRunStrategy(String strategyName){
        System.debug('Running Strategy'+strategyName);
        if(strategyName=='Employee Home Store Change'){
            if(employeeStoreChangeMap.size()>0){
                employeeStrategy = new EmployeeStoreChange(employeeStoreChangeMap);
                System.debug(employeeStrategy);
                employeeStrategy.runStrategy();
            }else{
                System.debug('No records to run for Employee Home Store Change');
                //No Records
            }   
        }       
        else if(strategyName=='Employee Promotion'){
            if(employeePromotionMap.size()>0){
                employeeStrategy = new EmployeePromotion(employeePromotionMap);
                System.debug(employeeStrategy);
                employeeStrategy.runStrategy();
            }else{
                System.debug('No records to run for Employee Promotion');
                //No Records
            } 
        }  
        else if(strategyName=='Employee Offboarded'){
            if(employeeOffboardMap.size()>0){
                employeeStrategy = new EmployeeOffboarded(employeeOffboardMap);
                System.debug(employeeStrategy);
                employeeStrategy.runStrategy();
            }else{
                System.debug('No records to run for Employee Offboard');
                //No Records
            } 
        }  
        else if(strategyName=='Floating Employee Removed'){
            if(employeeFloatingRemovedMap.size()>0){
                employeeStrategy = new EmployeeFloatingRemoved(employeeFloatingRemovedMap);
                System.debug(employeeStrategy);
                employeeStrategy.runStrategy();
            }else{
                System.debug('No records to run for Employee Store Expired');
                //No Records
            }
        }
        else if(strategyName=='Employee Demotion'){
            if(employeeDemotionMap.size()>0){
                employeeStrategy = new EmployeeDemotion(employeeDemotionMap);
                System.debug(employeeStrategy);
                employeeStrategy.runStrategy();
            }else{
                System.debug('No records to run for Employee Demotion');
                //No Records
            }
        }
        else if(strategyName=='New Employee'){
            if(employeeCreatedMap.size()>0){
                employeeStrategy = new EmployeeCreated(employeeCreatedMap);
                System.debug(employeeStrategy);
                employeeStrategy.runStrategy();
            }else{
                System.debug('No records to run for Employee Store Expired');
                //No Records
            }
        }
        else{
            System.debug('Unknown Strategy');
        }  
        
    }

}
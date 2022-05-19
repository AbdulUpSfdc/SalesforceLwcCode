/**
 * @description       : Interface class for the Employee Update Strategy Pattern
 * @author            : Erashad Kurawle ekurawle@salesforce.com
 * @group             : 
 * @last modified on  : 01-05-2021
 * @last modified by  : Erashad Kurawle ekurawle@salesforce.com
 * Modifications Log 
 * Ver   Date         Author                                    Modification
 * 1.0   12-23-2020   Erashad Kurawle ekurawle@salesforce.com   Initial Version
**/
public interface IEmployeeUpdateStrategy {   
    void runStrategy();   //Run the Actual strategy
    void findRecords();   //Find the lead records that need to be acted upon because of Employee update 
}
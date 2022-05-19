/***********************************************
 * Class - EmployeeJobDutyAssignHandler
 * Purpose - Assign job duty to employee record
 * 				- Always invoke this in after event trigger
 * *********************************************/
public with sharing class EmployeeJobDutyAssignHandler {
    
    Public static void ManageJobDutyByEmpId(set<Id> setEmpId) {
        // Identify employees by Id
        try {
            list<Employee__c> listEmp = new list<Employee__c>();
            list<string> listConcatStr = new list<string>();
            listEmp = [SELECT Id, Organization__c, Channel1__c, Sub_Channel__c, Is_Remote__c
                       , Assigned_Profile__c, MyProfileConcat__c, IsActive__c, User__c  FROM Employee__c 
                       WHERE Id IN :setEmpId AND IsActive__c = TRUE ];
            
            manageEmployeeJobDuty(listEmp);
        } catch (exception e) {
            system.debug(e.getStackTraceString());
            BWC_ExceptionUtils.handleException(e, true, null, null);
            if (Trigger.isExecuting) {
                Trigger.new[0].addError(e);
            }
        }
        
    }
    
    /*public static void ManageJobDutyByEmployeeList(list<Employee__c> listCurrEmpl) {
        try {
            list<Employee__c> listEmp = new list<Employee__c>();
            for (Employee__c iter : listCurrEmpl) {
                if (iter.IsActive__c) {
                    listEmp.add(iter);
                }
            }
            manageEmployeeJobDuty(listEmp);
        } catch (exception e) {
            BWC_ExceptionUtils.handleException(e, true, null, null);
            if (Trigger.isExecuting) {
                Trigger.new[0].addError(e);
            }
        }
        
    }*/
    
    /*public static void ManageJobDutyByActiveEmployeeList(list<Employee__c> listEmp) {
        try {
            manageEmployeeJobDuty(listEmp);
        } catch (exception e) {
            BWC_ExceptionUtils.handleException(e, true, null, null);
            if (Trigger.isExecuting) {
                Trigger.new[0].addError(e);
            }
        }
            
    }*/
    
    private static void manageEmployeeJobDuty (list<Employee__c> listEmp) {
        list<string> listConcatStr = new list<string>();
        list<Id> listempId = new list<Id>();
        list<Id> listUserId = new list<Id>();
        for (Employee__c iEmpl : listEmp) {
            if (iEmpl.IsActive__c) { // only consider active employees for processing
                listConcatStr.add(iEmpl.MyProfileConcat__c);
            	listempId.add(iEmpl.Id);
                if (iEmpl.User__c <> null) {
                    listUserId.add(iEmpl.User__c);
                }
            }
        }
        
        // Identify matching configuration & associated assignment mapping
        list<MyLogin_Profile_Jobduty__c> listJobDutyPerProfile = new list<MyLogin_Profile_Jobduty__c>();
        // MyProfileConcat__c field in the config object is concat of Organization, Channel, Subchannel and WFH parameters
        listJobDutyPerProfile = [SELECT Id, Employee_Jobduty_Reference__c, 
                                 Profile_Mapping__r.MyProfileConcat__c, Primary_Extended__c 
                                 FROM MyLogin_Profile_Jobduty__c 
                                 WHERE Profile_Mapping__r.MyProfileConcat__c IN :listConcatStr];
        // Find existing assignments of active employees 
        list<Employee_Jobduty_Assignment__c> listCurrJobDuty = new list<Employee_Jobduty_Assignment__c>();
        listCurrJobDuty = [SELECT Employee__c, Employee_Jobduty_Reference__c, IsActive__c, Primary_Or_Extended__c 
                           FROM Employee_Jobduty_Assignment__c 
                           WHERE Employee__c IN :listempId];
        map<Id, List<Employee_Jobduty_Assignment__c>> mapCurrJobdutyByEmpl = new map<Id, List<Employee_Jobduty_Assignment__c>>();
        map<Id, map<Id, Employee_Jobduty_Assignment__c>> mapDupJobDutyByEmpl = new map<Id, map<Id, Employee_Jobduty_Assignment__c>>();
        if (listCurrJobDuty.size() > 0) {
            list<Employee_Jobduty_Assignment__c> listCurrEmplJAByRef;
            for (Employee_Jobduty_Assignment__c unitEmplJA : listCurrJobDuty) {
                if (mapCurrJobdutyByEmpl.get(unitEmplJA.Employee__c) == null) {
                    listCurrEmplJAByRef = new list<Employee_Jobduty_Assignment__c>();
                    listCurrEmplJAByRef.add(unitEmplJA);
                    mapCurrJobdutyByEmpl.put(unitEmplJA.Employee__c, listCurrEmplJAByRef);
                } else {
                    mapCurrJobdutyByEmpl.get(unitEmplJA.Employee__c).add(unitEmplJA);
                }
                
                if (mapDupJobDutyByEmpl.get(unitEmplJA.Employee__c) <> null ) {
                    mapDupJobDutyByEmpl.get(unitEmplJA.Employee__c).put(unitEmplJA.Employee_Jobduty_Reference__c, unitEmplJA);
                } else {
                    map<Id, Employee_Jobduty_Assignment__c> mapExistJA = new map<Id, Employee_Jobduty_Assignment__c>();
                    mapExistJA.put(unitEmplJA.Employee_Jobduty_Reference__c, unitEmplJA);
                    mapDupJobDutyByEmpl.put(unitEmplJA.Employee__c, mapExistJA);
                }
            }
        }
        
        // Create assignment mapping for employee record
        list<Employee_Jobduty_Assignment__c> listEmpJobdutyAssign = new list< Employee_Jobduty_Assignment__c>();
        map<Id, map<Id, Employee_Jobduty_Assignment__c>> mapNewJAByRefAssign = new map<Id, map<Id, Employee_Jobduty_Assignment__c>>();
        system.debug(listJobDutyPerProfile);
        for (MyLogin_Profile_Jobduty__c iDuty : listJobDutyPerProfile) {
            for (Employee__c iEmployee : listEmp) {
                if (iEmployee.MyProfileConcat__c == iDuty.Profile_Mapping__r.MyProfileConcat__c) {
                    Employee_Jobduty_Assignment__c unitEmpJobDuty = new Employee_Jobduty_Assignment__c();
                    unitEmpJobDuty.Employee__c = iEmployee.Id;
                    unitEmpJobDuty.Employee_Jobduty_Reference__c = iDuty.Employee_Jobduty_Reference__c;
                    unitEmpJobDuty.IsActive__c = TRUE;
                    unitEmpJobDuty.Primary_Or_Extended__c = iDuty.Primary_Extended__c;
                    listEmpJobdutyAssign.add(unitEmpJobDuty);
                    
                    map <Id, Employee_Jobduty_Assignment__c> mapJAByRefForEmpl = new map<Id, Employee_Jobduty_Assignment__c>();
                    mapJAByRefForEmpl.put(iDuty.Employee_Jobduty_Reference__c, unitEmpJobDuty);
                    if (mapNewJAByRefAssign.get(iEmployee.Id) <> null) {
                        mapNewJAByRefAssign.get(iEmployee.Id).put(iDuty.Employee_Jobduty_Reference__c, unitEmpJobDuty);
                    } else {
                        map<Id, Employee_Jobduty_Assignment__c> mapNewJAByRefPerEmpl = new map<Id, Employee_Jobduty_Assignment__c>();
                        mapNewJAByRefPerEmpl.put(iDuty.Employee_Jobduty_Reference__c, unitEmpJobDuty);
                        mapNewJAByRefAssign.put(iEmployee.Id, mapNewJAByRefPerEmpl);
                    }
                }
            }
            system.debug(mapNewJAByRefAssign);
            system.debug(listEmpJobdutyAssign);
        }
        
        // Compare current computed and existing assignments
        list<Employee_Jobduty_Assignment__c> listFinalAssignments = new list<Employee_Jobduty_Assignment__c>();
        for (Employee__c iterEmpl : listEmp) {
            list<Employee_Jobduty_Assignment__c> listExistAssignPerEmpl = new list<Employee_Jobduty_Assignment__c>();
            listExistAssignPerEmpl = mapCurrJobdutyByEmpl.get(iterEmpl.Id);
            map<Id, Employee_Jobduty_Assignment__c> mapExistingJAPerEmpl = mapDupJobDutyByEmpl.get(iterEmpl.Id);
            map<Id, Employee_Jobduty_Assignment__c> mapNewJAPerEmpl = new map<Id, Employee_Jobduty_Assignment__c>();
            system.debug(mapNewJAByRefAssign);
            mapNewJAPerEmpl = mapNewJAByRefAssign.get(iterEmpl.Id);
            if (listExistAssignPerEmpl <> null && listExistAssignPerEmpl.size() > 0) { // Compare existing and new computed JA
                for (Employee_Jobduty_Assignment__c unitExistJA : listExistAssignPerEmpl) {
                    Employee_Jobduty_Assignment__c unitNewJA = mapNewJAPerEmpl <> null ? mapNewJAPerEmpl.get(unitExistJA.Employee_Jobduty_Reference__c) : null;
                    if (unitNewJA <> null) { // Same JA exist for employee
                        // check if all attributes same
                        if (unitNewJA.IsActive__c == unitExistJA.IsActive__c 
                            && unitNewJA.Primary_Or_Extended__c == unitExistJA.Primary_Or_Extended__c) {
                                // Nothing to be done
                            } else { // Assignment configuration reactivated
                                unitExistJA.IsActive__c = unitNewJA.IsActive__c;
                                unitExistJA.Primary_Or_Extended__c = unitNewJA.Primary_Or_Extended__c;
                                listFinalAssignments.add(unitExistJA);
                            }
                    } else { // Assignment configuration has been removed; Deactivate existing JA
                        unitExistJA.IsActive__c = false;
                        listFinalAssignments.add(unitExistJA);
                    }
                }
                // New JA configurations added in Job Duty
                if (mapNewJAPerEmpl <> null) {
                    for (Id unitNewDutyRef : mapNewJAPerEmpl.keyset()) {
                        if (mapExistingJAPerEmpl <> null && mapExistingJAPerEmpl.get(unitNewDutyRef) == null) {
                            listFinalAssignments.add(mapNewJAPerEmpl.get(unitNewDutyRef));
                        }
                    }
                }
                
                
            } else { // New employee job duty getting added
                if (mapNewJAByRefAssign.get(iterEmpl.Id) <> null 
                    && mapNewJAByRefAssign.get(iterEmpl.Id).values() <> null 
                    && mapNewJAByRefAssign.get(iterEmpl.Id).values().size() > 0) {
                    listFinalAssignments.addAll(mapNewJAByRefAssign.get(iterEmpl.Id).values());
                }
                	
            }
            
        }
        
        // DML to refresh all JA for list of employees
        if (listFinalAssignments.size() > 0) {
            system.debug(listFinalAssignments);
            UPSERT listFinalAssignments;
        }
    }

}
/* ================================================
* @author : Mike McKinley
* @date :   08/24/2020   
* @group : Case 
* @description : Generates test data for Task
================================================*/

@isTest
public class TestData_Task {
    public static void generateTasksForWhatId(Id associatedId, Integer taskCount) {
        //User oppAdministratorUser = [Select ID From User Where LastName='lastName_oopAdmin'];
       // system.runAs(oppAdministratorUser) {
            Account a = new Account();
            a.Name = 'Mandarin Enterprises';
            insert a;
            
            Contact c = new Contact();
            c.FirstName = 'Test';
            c.LastName = 'Contact';
            c.AccountId = a.Id;
            insert c;
            
            List<Task> tasks = new List<Task>();
            for(Integer i = 0; i < taskCount; i++) {
            	Task aTask = new Task();
                aTask.WhatId = associatedId;
                aTask.ActivityDate = System.today() - i;
                aTask.Subject = 'Other';
                aTask.Status = 'Not Started';
                aTask.Priority = 'High';
                aTask.WhoId = c.Id;
                tasks.add(aTask);
            }
            
            insert tasks;
        //}
    }
}
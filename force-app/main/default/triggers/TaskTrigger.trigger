/* ================================================* 
* @date :   4/20/2021   
* @group : Task
* @description : Task Trigger
================================================*/

trigger TaskTrigger on Task (before insert, before update, after insert, after update) {
    TaskTriggerHandler.delegateProcessing();
}
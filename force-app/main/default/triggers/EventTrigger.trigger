/* ================================================* 
* @date :   4/20/2021   
* @group : Event
* @description : Event Trigger
================================================*/

trigger EventTrigger on Event (after insert, after update) {
    EventTriggerHandler.delegateProcessing();
}
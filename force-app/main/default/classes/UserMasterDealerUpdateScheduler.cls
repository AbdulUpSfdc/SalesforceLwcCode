/*
* Author : Anand Tiwari
* Purpose: This scheduler class will be executed the batch UserMasterDealerUpdateBatch
* 
*
* Modifications Log 
* Ver   Date         Author
* 1.0   07-01-2021   Anand 
*/

global class UserMasterDealerUpdateScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      UserMasterDealerUpdateBatch userUpdateBatch = new UserMasterDealerUpdateBatch(); 
      database.executebatch(userUpdateBatch);
   }
}
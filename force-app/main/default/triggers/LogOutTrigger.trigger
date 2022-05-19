trigger LogOutTrigger on LogoutEventStream (after insert) { 
    new LogOutTriggerHandler().run();
     
  }
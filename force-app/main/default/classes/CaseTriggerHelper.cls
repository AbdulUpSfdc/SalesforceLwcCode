public with sharing  class CaseTriggerHelper {    
    public static Datetime addDays(Id businessHrsId, Datetime startDate, Integer days){
        system.debug(businessHrsId);
        system.debug(startDate);
        system.debug(days);
        startDate = BusinessHours.nextStartDate(businessHrsId, startDate);
        for (Integer elapsed = 0; elapsed < days; elapsed++){
            startDate = startDate.addDays(1);
            if (!BusinessHours.isWithin(businessHrsId, startDate)){
                startDate = BusinessHours.nextStartDate(businessHrsId, startDate);
            }
        }
        system.debug( 'expected close date'+startDate);
        
        return startDate;
    }
}
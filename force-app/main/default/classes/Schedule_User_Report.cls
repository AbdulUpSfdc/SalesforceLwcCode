public class Schedule_User_Report implements Schedulable{
   
    public void execute(SchedulableContext ctx) {
        Profile_Perm_User_Report rep = new Profile_Perm_User_Report();
		rep.getReport();
    }


}
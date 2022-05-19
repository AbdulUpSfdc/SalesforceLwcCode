/***********
    Name         : kt_flowURLNameTest
    Description  : This is the Test class for the kt_flowURLName.
********/

@isTest
Private class kt_flowURLNameTest{
  
    static testmethod void replacehashtag() { 
        list<string> testList = new list<string>();
        testList.Add ('!$*Test123#');
        testList.Add ('Test123@');
        list<string> responseList = kt_flowURLName.convertCharacters(testList);
        datetime rightnow = datetime.now();
        System.assertEquals('Test123-'+'-'+rightnow.hour()+rightnow.minute()+rightnow.second(),responseList[0]);
        System.assertEquals('Test123-'+'-'+rightnow.hour()+rightnow.minute()+rightnow.second(),responseList[1]);
    } 
}
@isTest
public with sharing class ChildCaseHelperTest {

    @isTest
    public static void testUpdateRejectedParents(){

        list<ID> idList = new List<ID>();
        Case c = new Case();
        insert c;
        idList.add(c.Id);
        ChildCaseHelper.updateRejectedParents(idList);
    }
    @isTest
    public static void testShouldRejectParent(){
        Case c = new Case();
        ChildCaseHelper.shouldRejectParent(c);
    }
    @isTest
    public static void testHasMobilityProduct(){
        ChildCaseHelper.hasMobilityProduct('I, Am, working, around');
    }
}
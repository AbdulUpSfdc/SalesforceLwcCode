/* ================================================
* @author : Mike McKinley
* @date :   08/24/2020   
* @group : Case 
* @description : Generates test data for Queue
================================================*/

@isTest
public class TestData_Queue {

        // create a queue 
	public static Group generateQueue(String queueType, String queueName) {
        Group queueGroup;
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queueGroup = new Group(Type='Queue', Name=queueName, DeveloperName=queueName.deleteWhitespace());
            insert queueGroup;
            
            QueueSObject queue = new QueueSObject(SobjectType=queueType, QueueId=queueGroup.Id);
            insert queue;
        }
        
        return queueGroup;
    }
    
        // add users to queue
    public static void addUsersToQueue(List<User> users, String queueName) {
        // retrieve the queue
        List<Group> queueGroups = [SELECT Id FROM Group WHERE Name=:queueName AND TYPE='Queue'];
        if(queueGroups != NULL && queueGroups.size() > 0) {
            Group queueGroup = queueGroups[0];
            
            // add each user as a member
            List<GroupMember> members = new List<GroupMember>();
            for(User user: users) {
                GroupMember member = new GroupMember();
                member.UserOrGroupId = user.Id;
                member.GroupId = queueGroup.Id;
                members.add(member);
            }
                
            insert members;
        }
    }

}
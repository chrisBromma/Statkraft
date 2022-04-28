public inherited sharing class UserSelector extends fflib_SObjectSelector{

    public static User pixOSUser;

    public SObjectType getSObjectType(){
        return User.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            User.Id,
            User.Name,
            User.Email,
            User.ContactId
        };
    }

    public Map<Id, String> getUsersEmail(Set<Id> userIds){
		List<User> users = selectSObjectsById(userIds);	
		Map<Id, String> emailsById = new Map<Id, String>();
		for(User user : users)
			emailsById.put(user.Id, user.Email);
		return emailsById;	
	}

    public static User getPixOSUser(){
        if(pixOSUser == null){
            fflib_QueryFactory queryFact =  new UserSelector().newQueryFactory().setCondition(' FirstName = \'Pixos\' AND LastName = \'Service\'').setLimit(1);
            pixOSUser = (User) Database.query(queryFact.toSOQL());
        }
        return pixOSUser;
    }
}
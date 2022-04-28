/****************************************************************************************************
* Class msCreateCommunityUser
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   08.08.2018
*   Description	:	This class offers an invocable method to create a Portal User if certain conditions
*                   for a Contract and Contract Role arise.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            08.08.2018          Init version.
*   + Christian Gottlieb (mindsquare GmbH)      23.03.2019          Updated to reactivate Users
*****************************************************************************************************/
public without sharing class msCreateCommunityUser {
    public static final String USERNAME_SUFIX = Label.msPortalUsernameSufix;

    @InvocableMethod(Label = 'Create community user' Description= 'This method will create a community user if certain conditions for a Contract and Contract Role arise')
    public static void createUser(List<Contract_Role__c> contractRoleList) {
        List<Id> usersToReactivate = new List<Id>();
        if (!contractRoleList.isEmpty()) {
            List<Id> roleIds = new List<Id>();
            List<Id> contactIds = new List<Id>();


            for (Contract_Role__c role : contractRoleList) {
                roleIds.add(role.Id);
            }
            Map<Id, Contract_Role__c> roleMap = new Map<Id, Contract_Role__c>([
                    SELECT Id, Name, Contract__c, Contact__c
                    FROM Contract_Role__c
                    WHERE Id IN :roleIds
            ]);
            for (Id key : roleMap.keySet()) {
                contactIds.add(roleMap.get(key).Contact__c);
            }
            List <User> existingUsers = [SELECT Id, ContactId, IsActive, Profile.Name FROM User WHERE ContactId IN :contactIds];
            for (User currentUser : existingUsers) {
                contactIds.remove(contactIds.indexOf(currentUser.ContactId));
                if (!currentUser.IsActive) {
                    usersToReactivate.add(currentUser.Id);
                }
            }
            reactivateUsers(usersToReactivate);


            createUsers(contactIds);
        }
    }
    public static void createUsers(List<String> contactIds) {
        List<Contact> contactsToUpdate = new List<Contact>([
                SELECT Id, Name, FirstName, LastName, Email, MailingCountry
                FROM Contact
                WHERE Id IN :contactIds
        ]);
        Profile profile = [SELECT Id FROM Profile WHERE Profile.Name = 'Global Customer Community User' LIMIT 1];
        List<User> newUsers = new List<User>();

        for (Contact con : contactsToUpdate) {
            newUsers.add(generateUser(con, profile, null));
        }
        insert newUsers;
    }
    public static User generateUser(Contact con, Profile profile, String username) {
        User newUser = new User();
        newUser.ContactId = con.Id;
        newUser.Username = con.Email+USERNAME_SUFIX;
        if(username!=null){
            newUser.Username = username;
        }

        newUser.Email = con.Email;
        newUser.FirstName = con.FirstName;
        newUser.LastName = con.LastName;
        newUser.ProfileId = profile.Id;
        if (con.FirstName != null) {
            newUser.Alias = con.FirstName.substring(0, 1) + con.LastName.substring(0, 3);
        } else {
            newUser.Alias = con.LastName.substring(0, 5);
        }
        newUser.CommunityNickname = (String.valueOfGmt(Datetime.now()) + con.FirstName + con.LastName).abbreviate(40);
        newUser.TimeZoneSidKey = 'Europe/Berlin';
        newUser.EmailEncodingKey = 'ISO-8859-1';
        switch on con.MailingCountry {
            when 'Germany' {
                newUser.LanguageLocaleKey = 'de';
                newUser.LocaleSidKey = 'de_DE_EURO';
            }
            when 'France' {
                newUser.LanguageLocaleKey = 'fr';
                newUser.LocaleSidKey = 'fr_FR_EURO';
            }
            when 'United Kingdom' {
                newUser.LanguageLocaleKey = 'en_US';
                newUser.LocaleSidKey = 'en_GB';
            }
            when else {
                newUser.LanguageLocaleKey = 'en_US';
                newUser.LocaleSidKey = 'de_DE_EURO';
            }
        }

        return newUser;
    }
    @Future
    private static void reactivateUsers(List<Id> userList) {
        List<User> usersToUpdate = [SELECT Id, IsActive FROM User WHERE Id IN :userList];
        for (User userItem : usersToUpdate) {
            if (!userItem.IsActive) {
                userItem.IsActive = true;
            }
        }
        List<Database.SaveResult> result = Database.update(usersToUpdate);
    }
}
public with sharing class msCreateCommunityUsersBatch implements Database.Batchable<Contact>, Database.Stateful{

    public static final String DEFAULT_SUFFIX = '.statkraftportal';
    private static final String COMMUNITY_PROFILE_ID = [
            SELECT Id
            FROM Profile
            WHERE Profile.Name = 'Global Customer Community User' LIMIT 1
    ].Id;
    private Set<Id> contactIds;
    private Integer counter;

    public msCreateCommunityUsersBatch(Set<Id> contactIds) {
        this.contactIds = contactIds;
        if(Test.isRunningTest()) {
            this.counter = 10000;
        } else {
            this.counter = 0;
        }
    }

    public List<Contact> start(Database.BatchableContext ctx) {
        return [
                SELECT Id, FirstName, LastName, Email
                FROM Contact
                WHERE Id IN :contactIds
        ];
    }

    public void execute(Database.BatchableContext ctx, List<Contact> scope) {
        List<User> users = new List<User>();
        for(Contact con : scope) {
            users.add(createUserFrom(con));
            counter++;
        }
        insert users;
    }

    public void finish(Database.BatchableContext ctx) {}

    private User createUserFrom(Contact con) {
        User user = new User();
        user.Username = con.Email + DEFAULT_SUFFIX;
        user.FirstName = con.FirstName;
        user.LastName = con.LastName;
        user.ContactId = con.Id;
        user.Email = con.Email;
        user.ProfileId = COMMUNITY_PROFILE_ID;
        user.CommunityNickname = 'statkraftPortal' + counter;
        user.Alias = 'test';
        user.TimeZoneSidKey = 'Europe/Berlin';
        user.LocaleSidKey = 'de_DE';
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'de';
        user.IsActive = false;
        return user;
    }
}
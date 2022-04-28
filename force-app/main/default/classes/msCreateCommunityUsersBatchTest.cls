@IsTest
private class msCreateCommunityUsersBatchTest {

    private static final Integer BULK_SIZE = 100;
    private static final String ADMIN_PROFILE_ID = [
            SELECT Id
            FROM Profile
            WHERE Profile.Name = 'System Administrator' LIMIT 1
    ].Id;
    private static final Id ACC_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Account').getRecordTypeId();
    private static final Id CONTRACT_RECORD_TYPE = Schema.SObjectType.Contract__c.getRecordTypeInfosByName()
            .get('Contract PPA').getRecordTypeId();
    private static final Id CONTRACT_ROLE_RECORD_TYPE = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByName()
            .get('Contract Role Contact').getRecordTypeId();
    private static final String COMMERCIAL_CONTACT = 'Commercial Contact';
    private static final String TEST_USER_EMAIL = 'testrunasuser@email.statkraftportal';

    @IsTest
    private static void testCreateUsersForContactsWithContactRoles() {
        SetupData setupData = new SetupData();
        setupData.queryUsers();
        setupData.createContactsWithRoles();
        setupData.createTestContactIds();

        Test.startTest();
            Database.executeBatch(new msCreateCommunityUsersBatch(setupData.testContactIds));
        Test.stopTest();

        setupData.queryUsers();

        Integer expectedUserCount = setupData.originalUserCount + BULK_SIZE;
        System.assertEquals(expectedUserCount, setupData.testUsers.size());
    }

    private class SetupData {
        private User testAdminUser;
        private Integer originalUserCount;
        private Account testAccount;
        private List<User> testUsers;
        private List<Contact> testContacts;
        private List<Contract__c> testContracts;
        private List<Contract_Role__c> testContractRoles;
        private Set<Id> testContactIds;

        private SetupData() {
            List<User> users = [SELECT Id FROM User];
            originalUserCount = users.size();
        }

        private void createContactsWithRoles() {
            createTestAccount();
            createTestContacts();

        }

        private void createTestContactIds() {
            testContactIds = new Set<Id>();
            List<Contact> contacts = [SELECT Id FROM Contact];
            for(Contact con : contacts) {
                testContactIds.add(con.Id);
            }
        }

        private void createTestAccount() {
            Id recordTypeId =
                    Schema.SObjectType.Account.getRecordTypeInfosByName()
                            .get('Account').getRecordTypeId();
            testAccount = new Account();
            testAccount.Name = 'Test Account';
            testAccount.Customer_Type__c ='not yet identified';
            testAccount.RecordTypeId = ACC_RECORD_TYPE;
            insert testAccount;
            List<Account> accounts = [SELECT Id, Owner.Name FROM Account];
            for(Account acc : accounts) {
                System.debug(acc.Owner.Name);
            }
        }

        private void createTestContacts() {
            testContacts = new List<Contact>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                testContacts.add(createContact(i));
            }
            insert testContacts;
        }

        private Contact createContact(Integer index) {
            Contact contact = new Contact();
            contact.LastName = 'Test ' + index;
            contact.Email = 'test' + index + '@mail.com';
            contact.AccountId = testAccount.Id;
            return contact;
        }

        private void createTestContracts() {
            testContracts = new List<Contract__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                testContracts.add(createContract(i));
            }
            insert testContracts;
        }

        private Contract__c createContract(Integer index) {
            Contract__c contract = new Contract__c();
            contract.RED_Contract_ID__c = 'TestContract' + index;
            contract.Approved__c = true;
            contract.Start_Date__c = Date.today().addDays(-10);
            contract.End_Date__c = Date.today().addDays(10);
            contract.Status__c = 'Active';
            contract.RecordTypeId = CONTRACT_RECORD_TYPE;
            return contract;
        }

        private void createTestContractRoles(String role) {
            testContractRoles = new List<Contract_Role__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                testContractRoles.add(createContractRole(i, role));
            }
            insert testContractRoles;
        }

        private Contract_Role__c createContractRole(Integer index, String role) {
            Contract_Role__c contractRole = new Contract_Role__c();
            contractRole.RecordTypeId = CONTRACT_ROLE_RECORD_TYPE;
            contractRole.Contract__c = testContracts[index].Id;
            contractRole.Contact__c = testContacts[index].Id;
            contractRole.Start_Date__c = Date.today().addDays(-10);
            contractRole.Role__c = role;
            return contractRole;
        }

        private void queryUsers() {
            testUsers = [SELECT Id FROM User];
        }
    }
}
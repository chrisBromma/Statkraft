@IsTest
public without sharing class msKAMrequestControllerTest {
    static Date DEADLINE = Date.today() + 1;
    static List<User> testUsers = new List<User>();
    static Boolean notSubmitted = false;
    static Boolean submitted = true;


    @TestSetup
    public static void createTestData() {

        // Setup test data
        // Create a unique UserName
        for (Integer i = 0; i < 6; i++) {
            String uniqueUserName = 'standarduser' + i + DateTime.now().getTime() + '@testorg.com';
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
            User u = new User(
                    Alias = 'stand' + i,
                    Email = 'standarduser' + i + '@testorg.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'Testing' + i,
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles',
                    Username = uniqueUserName
            );
            testUsers.add(u);
        }

        insert testUsers;

        KAM_Request_Dashboard_Settings__c setting = new KAM_Request_Dashboard_Settings__c(
                Deadline__c = DEADLINE,
                Query_Date__c = DEADLINE,
                VP_Type__c = 'DAT',
                Countries_with_Flags__c = 'DE;FR',
                SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert setting;

        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 30; i++) {
            Account testAccount = new Account(
                    name = 'TestAcc ' + i,
                    Customer_Segment_industry__c = 'Tech companies',
                    Customer_Type__c = 'B - Single country, multiple product owners',
                    BillingCountry = 'Germany',
                    KAM_Approval_Step__c = '',
                    KAM_request_sent__c = Date.today() - 7,
                    KAM_relevant__c = true,
                    KAM_pending__c = true
            );
            if (i >= 10 && i < 20) {
                testAccount.KAM_approved__c = Datetime.now() - 7;
            }
            if (i >= 20 && i < 30) {
                testAccount.KAM_allocation_conflict__c = true;
            }
            testAccounts.add(testAccount);
        }
        // testAccounts[0] is for Allocation Requests
        // testAccounts[1] is for Change Requests:
        testAccounts[10].KAM_approved__c = Datetime.now() - 7;
        // testAccounts[2] is for In Conflict Requests:
        testAccounts[20].KAM_allocation_conflict__c = true;

        insert testAccounts;

        List<KAM_request__c> testRequests = new List<KAM_request__c>();
        for (Integer i = 0; i < 10; i++) {
            KAM_request__c testAllocationRequest = new KAM_request__c(
                    Key_account__c = testAccounts[i].Id
            );
            testRequests.add(testAllocationRequest);
        }
        for (Integer i = 10; i < 20; i++) {
            KAM_request__c testChangeRequest = new KAM_request__c(
                    Key_account__c = testAccounts[i].Id
            );
            testRequests.add(testChangeRequest);
        }
        for (Integer i = 20; i < 30; i++) {
            KAM_request__c testInConflictRequest = new KAM_request__c(
                    Key_account__c = testAccounts[i].Id,
                    VP_MCO_approved_KAM__c = false,
                    VP_MCO_locked__c = true

            );
            testRequests.add(testInConflictRequest);
        }


        for (KAM_request__c request : testRequests) {
            request.KAM_request_sent__c = Date.today() - 7;
            //request.Deadline__c = Date.today() + 7;
            request.Request_Batch_Date__c = Date.today() - 1;
            request.isActive__c = true;

        }
        insert testRequests;

        List<msKAMrequestController.PicklistEntryWrapper> delegateMarkets = msKAMrequestController.getMarketPicklistValues();

        List<Delegation__c> delegationsToInsert = new List<Delegation__c>();
        for (Integer i = 0; i < testUsers.size(); i++) {
            delegationsToInsert.add(new Delegation__c(
                    Delegate__c = testUsers[i].Id,
                    Delegate_for_Market__c = delegateMarkets[i].picklistValue,
                    Valid_From__c = Date.today() - 1,
                    Valid_To__c = Date.today() + 1
            ));
        }
        insert delegationsToInsert;
    }
    @IsTest
    public static void testGetAllRequestsDelegate() {
        testUsers = [SELECT Id FROM User WHERE Email LIKE 'standarduser%'];

        Test.startTest();
        for (User testUser : testUsers) {
            System.runAs(testUser) {
                Map<String, List<Object>> allRequests = msKAMrequestController.getAllRequests();
                System.assertEquals(10, allRequests.get('AllocationRequests').size());
                System.assertEquals(10, allRequests.get('ChangeRequests').size());
                System.assertEquals(10, allRequests.get('InConflictRequests').size());
            }
        }
        Test.stopTest();
    }

    @IsTest
    public static void testGetAllRequestsAMC() {
        User amcUser = [SELECT Id FROM User WHERE Profile.Name = 'KAM AMC' LIMIT 1];
        System.runAs(amcUser) {
            Map<String, List<Object>> allRequests = msKAMrequestController.getAllRequests();
            System.assertEquals(10, allRequests.get('AllocationRequests').size());
            System.assertEquals(10, allRequests.get('ChangeRequests').size());
            System.assertEquals(10, allRequests.get('InConflictRequests').size());
            msKAMrequestController.RequestWrapper vpDefinition = (msKAMrequestController.RequestWrapper)allRequests.get('VPDefinition')[0];
            System.assertEquals(true, vpDefinition.AMCUser);
        }
    }

    @IsTest
    public static void testSaveData() {
        Map<String, List<Object>> allRequests = msKAMrequestController.getAllRequests();
        List<msKAMrequestController.RequestWrapper> requests = (List<msKAMrequestController.RequestWrapper>)allRequests.get('AllocationRequests');
        requests.addAll((List<msKAMrequestController.RequestWrapper>)allRequests.get('ChangeRequests'));

        List<Delegation__c> delegation = [SELECT Delegate__c, Valid_From__c, Valid_To__c FROM Delegation__c WHERE Delegate_for_Market__c = 'MCU'];
        List<User> mcuDelegates = [SELECT Id, Username FROM User WHERE Id = :delegation[0].Delegate__c];
        User mcuDelegate = mcuDelegates[0];

        List<Id> requestIdsToWorkWith = new List<Id>();
        for (msKAMrequestController.RequestWrapper requestWrapper : requests) {
            requestIdsToWorkWith.add(requestWrapper.RequestId);
        }

        //Approved but not submitted: The Requests should be approved = true but locked = false
        System.runAs(mcuDelegate) {
            for (msKAMrequestController.RequestWrapper requestWrapper : requests) {
                requestWrapper.VPComment = 'TestComment';
                requestWrapper.Approval = true;
            }
            msKAMrequestController.saveData(JSON.serialize(requests), notSubmitted);
        }
        List<KAM_request__c> mcuRequestsApprovedNotSubmitted = [SELECT VP_MCU_approved_KAM__c, VP_MCU_comment__c, VP_MCU_locked__c FROM KAM_request__c WHERE Id IN :requestIdsToWorkWith];
        for (KAM_request__c request : mcuRequestsApprovedNotSubmitted) {
            System.assertEquals(true, request.VP_MCU_approved_KAM__c);
            System.assertEquals('TestComment', request.VP_MCU_comment__c);
            System.assertEquals(false, request.VP_MCU_locked__c);
        }
        //Declined not submitted: The requests should be approved = false but locked = false
        System.runAs(mcuDelegate) {
            for (msKAMrequestController.RequestWrapper requestWrapper : requests) {
                requestWrapper.Approval = false;
            }
            msKAMrequestController.saveData(JSON.serialize(requests), notSubmitted);
        }
        List<KAM_request__c> mcuRequestsDeclinedNotSubmitted = [SELECT VP_MCU_approved_KAM__c, VP_MCU_comment__c, VP_MCU_locked__c FROM KAM_request__c WHERE Id IN :requestIdsToWorkWith];
        for (KAM_request__c request : mcuRequestsDeclinedNotSubmitted) {
            System.assertEquals(false, request.VP_MCU_approved_KAM__c);
            System.assertEquals('TestComment', request.VP_MCU_comment__c);
            System.assertEquals(false, request.VP_MCU_locked__c);
        }
        // Declined and submitted: The requests should be approved = false and locked = true
        System.runAs(mcuDelegate) {
            for (msKAMrequestController.RequestWrapper requestWrapper : requests) {
                requestWrapper.Approval = false;
            }
            msKAMrequestController.saveData(JSON.serialize(requests), submitted);
        }
        List<KAM_request__c> mcuRequestsDeclinedAndSubmitted = [SELECT VP_MCU_approved_KAM__c, VP_MCU_comment__c, VP_MCU_locked__c FROM KAM_request__c WHERE Id IN :requestIdsToWorkWith];
        for (KAM_request__c request : mcuRequestsDeclinedAndSubmitted) {
            System.assertEquals(false, request.VP_MCU_approved_KAM__c);
            System.assertEquals('TestComment', request.VP_MCU_comment__c);
            System.assertEquals(true, request.VP_MCU_locked__c);
        }
    }
    @IsTest
    public static void testSaveDataAMC() {
        User amcUser = [SELECT Id FROM User WHERE Profile.Name = 'KAM AMC' LIMIT 1];
        String amcComment = 'Test AMC Comment';

        Map<String, List<Object>> allRequests = msKAMrequestController.getAllRequests();
        List<msKAMrequestController.RequestWrapper> requests = (List<msKAMrequestController.RequestWrapper>)allRequests.get('AllocationRequests');
        requests.addAll((List<msKAMrequestController.RequestWrapper>)allRequests.get('ChangeRequests'));

        List<Id> idsOfEditedAccounts = new List<Id>();

        System.runAs(amcUser) {
            for (msKAMrequestController.RequestWrapper requestWrapper : requests) {
                requestWrapper.VPComment = amcComment;
                idsOfEditedAccounts.add(requestWrapper.AccountId);
            }
            msKAMrequestController.saveData(JSON.serialize(requests), notSubmitted);
        }

        List<Account> editedAccounts = [SELECT Id, Comments_from_AMC__c FROM Account WHERE Id IN :idsOfEditedAccounts];
        for (Account editedAccount : editedAccounts) {
            System.assertEquals(amcComment, editedAccount.Comments_from_AMC__c);
        }
    }
    @IsTest
    public static void testSaveQueryDate() {
        Date newQueryDate = Date.today();

        Test.startTest();
        msKAMrequestController.saveQueryDate(newQueryDate);
        Test.stopTest();

        KAM_Request_Dashboard_Settings__c updatedOrgDefaults = KAM_Request_Dashboard_Settings__c.getOrgDefaults();
        System.assertEquals(newQueryDate, updatedOrgDefaults.Query_Date__c);
    }
    @IsTest
    public static void testSendEmailReminder() {
        User amcUser = [SELECT Id FROM User WHERE Profile.Name = 'KAM AMC' LIMIT 1];

        Date deadline = Date.today() + 1;

        Test.startTest();
        System.runAs(amcUser){
			msKAMrequestController.sendEmailReminder(deadline);
        }
        Test.stopTest();

        System.assertEquals(KAM_Request_Dashboard_Settings__c.getOrgDefaults().Deadline__c, deadline);
        List<KAM_request__c> activeRequests = [
                SELECT Deadline__c
                FROM KAM_request__c
                WHERE (Key_Account__r.KAM_Approval_Step__c = ''
                AND KAM_request_sent__c <= :KAM_Request_Dashboard_Settings__c.getOrgDefaults().Query_Date__c
                AND isActive__c = TRUE)
        ];
        for (KAM_request__c activeRequest : activeRequests) {
            System.assertEquals(deadline, activeRequest.Deadline__c);
        }
    }
    @IsTest
    public static void testGetCurrentDelegations() {
        List<msKAMrequestController.PicklistEntryWrapper> delegateMarkets = msKAMrequestController.getMarketPicklistValues();
        Map<String, List<msKAMrequestController.DelegationWrapper>> delegationWrappersByMarkets =
                new Map<String, List<msKAMrequestController.DelegationWrapper>>();

        testUsers = [SELECT Id FROM User WHERE Email LIKE 'standarduser%'];

        Test.startTest();
        System.runAs(testUsers[0]) {
            for (msKAMrequestController.PicklistEntryWrapper delegateMarket : delegateMarkets) {
                delegationWrappersByMarkets.put(delegateMarket.picklistValue, msKAMrequestController.getCurrentDelegations(delegateMarket.picklistValue));
            }
        }
        Test.stopTest();

        for (List<msKAMrequestController.DelegationWrapper> delegationWrappers : delegationWrappersByMarkets.values()) {
            System.assertEquals(1, delegationWrappers.size());
        }
    }
    @IsTest
    public static void testGetCurrentDelegateIds(){
        List<Id> currentDelegateIds = new List<Id>();

        Test.startTest();
        currentDelegateIds = msKAMrequestController.getCurrentDelegateIds();
        Test.stopTest();

        List<Delegation__c> currentDelegations = [
                SELECT Id FROM Delegation__c
                WHERE (Valid_From__c <= TODAY AND Valid_To__c >= TODAY)
        ];
        System.assertEquals(currentDelegations.size(), currentDelegateIds.size());
    }

    @IsTest
    public static void testSaveDelegate() {

        List<msKAMrequestController.PicklistEntryWrapper> delegateMarkets = msKAMrequestController.getMarketPicklistValues();

        List<msKAMrequestController.DelegationWrapper> delegationsToCreate = new List<msKAMrequestController.DelegationWrapper>();

        for (msKAMrequestController.PicklistEntryWrapper delegateMarket : delegateMarkets) {
            msKAMrequestController.DelegationWrapper delegationWrapper = new msKAMrequestController.DelegationWrapper();
            delegationWrapper.delegateId = UserInfo.getUserId();
            delegationWrapper.market = delegateMarket.picklistValue;
            delegationsToCreate.add(delegationWrapper);
        }

        Test.startTest();
        msKAMrequestController.saveNewDelegations(JSON.serialize(delegationsToCreate));
        Test.stopTest();

        List<Delegation__c> delegations = [
                SELECT Delegate__c, Delegate_for_Market__c, Valid_From__c, Valid_To__c
                FROM Delegation__c
                WHERE Delegate__c = :UserInfo.getUserId()
        ];

        System.assertEquals(delegateMarkets.size(), delegations.size());
        for (Delegation__c delegation : delegations) {
            System.assertEquals(UserInfo.getUserId(), delegation.Delegate__c);
            System.assertEquals(DEADLINE, delegation.Valid_To__c);
            System.assertEquals(Date.today(), delegation.Valid_From__c);
        }
    }
}
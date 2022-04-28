@isTest
public with sharing class msKAMsuggestionControllerTest {
    @TestSetup
    public static void createTestData(){
        Account allocatedAccount = new Account();
        allocatedAccount.Name = 'allocatedAccount';
        allocatedAccount.KAM_relevant__c = true;
        allocatedAccount.Last_KAM_submitter__c = UserInfo.getUserId();
        allocatedAccount.KAM_approved__c = Date.today();
        allocatedAccount.KAM_pending__c = true;
        allocatedAccount.Customer_Type__c = 'A - Multi-country';
        allocatedAccount.Customer_Segment_industry__c = 'Intermittent RES generators';
        allocatedAccount.BillingCountry = 'Germany';
        insert allocatedAccount;

        Account unallocatedAccount = new Account();
        unallocatedAccount.Name = 'unallocatedAccount';
        unallocatedAccount.KAM_relevant__c = true;
        unallocatedAccount.Customer_Type__c = 'A - Multi-country';
        unallocatedAccount.Customer_Segment_industry__c = 'Intermittent RES generators';
        unallocatedAccount.BillingCountry = 'France';
        insert unallocatedAccount;

        KAM_Request_Dashboard_Settings__c setting = new KAM_Request_Dashboard_Settings__c(Deadline__c=Date.today()+1, Query_Date__c=Date.today()+1, VP_Type__c='DAT', Countries_with_Flags__c = 'DE;FR');
        insert setting;
    }
    @isTest
    public static void testGetUnallocatedKeyAccounts() {
        List<msKAMsuggestionController.AccountWrapper> unallocatedAccounts =
                msKAMsuggestionController.getUnallocatedKeyAccounts();

        System.assert(unallocatedAccounts.size()==1);
        System.assertEquals('unallocatedAccount', unallocatedAccounts[0].Accountname);
    }
    @IsTest
    public static void testSaveComments(){
        List<msKAMsuggestionController.AccountWrapper>accountWrappers =
                msKAMsuggestionController.getUnallocatedKeyAccounts();

        accountWrappers[0].CommentsFromAMC = 'This is a test comment';

        msKAMsuggestionController.saveComments(JSON.serialize(accountWrappers));

        Account updatedAccount = [SELECT Comments_from_AMC__c FROM Account WHERE Id = :accountWrappers[0].AccountId];
        System.assertEquals('This is a test comment',updatedAccount.Comments_from_AMC__c);
    }
    @isTest
    public static void testGetUserName() {
        String Username = msKAMsuggestionController.getUserName(UserInfo.getUserId());
        System.assertEquals(UserInfo.getName(), Username);
    }
    @IsTest
    public static void testGetOtherRequestData() {
        Map<String, List<Object>> otherRequestData;

        User amcUser = [SELECT Id FROM User WHERE Profile.Name LIKE 'KAM%' LIMIT 1][0];
        System.runAs(amcUser){
            otherRequestData = msKAMsuggestionController.getOtherRequestData();
        }
        msKAMrequestController.RequestWrapper VPDefinition = (msKAMrequestController.RequestWrapper)otherRequestData.get('VPDefinition')[0];

        System.assertEquals(true, VPDefinition.AMCUser);
    }
    @IsTest
    public static void testCompareTo(){
        List<String> characters = new List<String>{'A','B','C','D'};
        Integer i = 1;
        List<msKAMsuggestionController.AccountWrapper> accountWrappers = new List<msKAMsuggestionController.AccountWrapper>();
        for (String character : characters){
            Account acc = new Account(BillingCountry = Math.mod(i, 2) == 0 ? 'B' : 'A', Name = character);
            msKAMsuggestionController.AccountWrapper accWrapper = new msKAMsuggestionController.AccountWrapper(acc);
            accountWrappers.add(accWrapper);
            i++;
        }
        // BillingCountry > compareTo.BillingCountry
        System.assertEquals(accountWrappers[3].compareTo(accountWrappers[2]), 1);
        // BillingCountry < compareTo.BillingCountry
        System.assertEquals(accountWrappers[0].compareTo(accountWrappers[1]), -1);

        // BillingCountry = compareTo.BillingCountry && AccountName > compareTo.AccountName
        System.assertEquals(accountWrappers[2].compareTo(accountWrappers[0]), 1);
        // BillingCountry = compareTo.BillingCountry && AccountName < compareTo.AccountName
        System.assertEquals(accountWrappers[1].compareTo(accountWrappers[3]), -1);




    }
}
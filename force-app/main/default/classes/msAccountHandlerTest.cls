/****************************************************************************************************
 * Class msAccountHandlerTest
 *
 *   Create By	:   Mandy Bebenroth (mindsquare GmbH)
 *   Create Date	:   15.05.2020
 *   Description	:	---
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Mandy Bebenroth (mindsquare GmbH)	15.-19.05.2020       Init version.
*****************************************************************************************************/

@IsTest
private without sharing class msAccountHandlerTest {
    private static final Id DE_ACC_RECORD_TYPE =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId();

    private static final Integer BULK_SIZE = 50; //needs to be multiple of 2

    @TestSetup
    private static void setUp() {
        List <Account> listGrandParents = new List<Account>();
        List <Account> listParents = new List<Account>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            listGrandParents.add(new Account(
                    Name = 'Grand Parent' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials',
                    Data_Migration_ID__c = 'Grand Parent' + i
            ));
            listParents.add(new Account(
                    Name = 'Middle Parent' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials',
                    Data_Migration_ID__c = 'Middle Parent' + i
            ));
        }
        List <Account> allParentAccountsToInsert = new List<Account>();
        allParentAccountsToInsert.addAll(listGrandParents);
        allParentAccountsToInsert.addAll(listParents);
        insert allParentAccountsToInsert;
    }

    @IsTest
    static void testExceptionHierarchyOnTop() {
        Account parent = new Account(
                Name = 'Parent',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert parent;
        Account child = new Account(
                Name = 'Child',
                Negotiating_Party__c = parent.Id,
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert child;
        Account grandParent = new Account(
                Name = 'Grand Parent',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert grandParent;

        Test.startTest();
        parent.Negotiating_Party__c = grandParent.Id;
        Boolean threwException = false;
        try {
            update parent;
        } catch (DmlException e) {
            threwException = true;
        } catch (Exception e) {
            System.assert(false, 'Exception should have been of type DML.');
        }
        Test.stopTest();
        System.assert(threwException, 'Should have thrown exception.');
    }

    @IsTest
    static void testExceptionHierarchyInMiddleUpdate() {
        Account child = new Account(
                Name = 'Child',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert child;
        Account grandParent = new Account(
                Name = 'Grand Parent',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert grandParent;
        Account parent = new Account(
                Name = 'Parent',
                Negotiating_Party__c = grandParent.Id,
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert parent;
        child.Negotiating_Party__c = parent.Id;
        Test.startTest();
        Boolean threwException = false;
        try {
            update child;
        } catch (DmlException e) {
            threwException = true;
        } catch (Exception e) {
            System.assert(false, 'Exception should have been of type DML.');
        }

        Test.stopTest();
        System.assert(threwException, 'Should have thrown exception.');
    }

    @IsTest
    static void testExceptionHierarchyInMiddleInsert() {
        Account grandParent = new Account(
                Name = 'Grand Parent',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert grandParent;
        Account parent = new Account(
                Name = 'Parent',
                Negotiating_Party__c = grandParent.Id,
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert parent;
        Account child = new Account(
                Name = 'Child',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                Negotiating_Party__c = parent.Id,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );

        Test.startTest();
        Boolean threwException = false;
        try {
            insert child;
        } catch (DmlException e) {
            threwException = true;
        } catch (Exception e) {
            System.assert(false, 'Exception should have been of type DML.');
        }

        Test.stopTest();
        System.assert(threwException, 'Should have thrown exception.');
    }

    @IsTest
    static void testExceptionHierarchyTopAndMiddleInsert() {
        List <Account> accounts = new List<Account>();
        Account grandParent = new Account(
                Name = 'Grand Parent',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert grandParent;
        Account parent = new Account(
                Name = 'Parent',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert parent;
        Account child = new Account(
                Name = 'Child',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert child;
        parent.Negotiating_Party__c = grandParent.Id;
        child.Negotiating_Party__c = parent.Id;
        accounts.add(parent);
        accounts.add(child);
        Test.startTest();
        Boolean threwException = false;
        try {
            update accounts;
        } catch (DmlException e) {
            threwException = true;
        } catch (Exception e) {
            System.assert(false, 'Exception should have been of type DML.');
        }
        Test.stopTest();
        System.assert(threwException, 'Should have thrown exception.');
    }

    @IsTest
    static void testDeleteAccount() {
        Account account = new Account(
                Name = 'Child',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert account;
        Test.startTest();
        delete account;
        Test.stopTest();
    }

    @IsTest
    public static void npo_insertTest() {
        Id notCurrentUserEEGId = [
                SELECT Id
                FROM User
                WHERE Id != :UserInfo.getUserId()
                AND Profile.Name = 'DE EEG'
                LIMIT 1
        ].Id;

        Account negParty = new Account(
                Name = 'Negotiating Party',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                OwnerId = notCurrentUserEEGId
        );
        insert negParty;

        Test.startTest();
        Account newAccount = new Account(
                Name = 'Child',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                Negotiating_Party__c = negParty.Id
        );
        insert newAccount;
        Test.stopTest();

        negParty = [SELECT OwnerId FROM Account WHERE Id = :negParty.Id];
        newAccount = [SELECT OwnerId, Negotiating_Party__c FROM Account WHERE Id = :newAccount.Id];
        System.assertEquals(negParty.Id, newAccount.Negotiating_Party__c, 'Negotiating Party was changed during insert');
        System.assertEquals(negParty.OwnerId, newAccount.OwnerId, 'The Owner should have been the one of the Negotiating Party');
    }

    @IsTest
    public static void npo_updateTest() {
        Id notCurrentUserEEGId = [
                SELECT Id
                FROM User
                WHERE Id != :UserInfo.getUserId()
                AND Profile.Name = 'DE EEG'
                LIMIT 1
        ].Id;

        Account negParty = new Account(
                Name = 'Negotiating Party',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                OwnerId = notCurrentUserEEGId
        );
        insert negParty;

        Account newAccount = new Account(
                Name = 'Child',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        insert newAccount;

        Test.startTest();
        newAccount.Negotiating_Party__c = negParty.Id;
        update newAccount;
        Test.stopTest();

        negParty = [SELECT OwnerId FROM Account WHERE Id = :negParty.Id];
        newAccount = [SELECT OwnerId, Negotiating_Party__c FROM Account WHERE Id = :newAccount.Id];
        System.assertEquals(negParty.Id, newAccount.Negotiating_Party__c, 'Negotiating Party was changed during insert');
        System.assertEquals(negParty.OwnerId, newAccount.OwnerId, 'The Owner should have been the one of the Negotiating Party');
    }

    @IsTest
    public static void npo_insertTest_bulk() {
        Integer bulk_size = 50;
        Id notCurrentUserEEGId = [
                SELECT Id
                FROM User
                WHERE Id != :UserInfo.getUserId()
                AND Profile.Name = 'DE EEG'
                LIMIT 1
        ].Id;
        List<Account> negParties = new List<Account>();
        for (Integer i = 0; i < bulk_size; i++) {
            negParties.add(new Account(
                    Name = 'Negotiating Party' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials',
                    OwnerId = notCurrentUserEEGId
            ));
        }
        insert negParties;

        Test.startTest();
        List<Account> newAccounts = new List<Account>();
        for (Integer i = 0; i < bulk_size; i++) {
            negParties.add(new Account(
                    Name = 'Child' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials',
                    Negotiating_Party__c = negParties[i].Id
            ));
        }
        insert newAccounts;
        Test.stopTest();

        Map<Id, Account> negPartiesMap = new Map<Id, Account>([SELECT OwnerId FROM Account WHERE Id IN :negParties]);
        newAccounts = [SELECT OwnerId, Negotiating_Party__c FROM Account WHERE Id IN :newAccounts];
        for (Account newAccount : newAccounts) {
            System.assert(negPartiesMap.containsKey(newAccount.Negotiating_Party__c), 'Negotiating Party was changed during insert');
            System.assertEquals(negPartiesMap.get(newAccount.Negotiating_Party__c).OwnerId, newAccount.OwnerId, 'The Owner should have been the one of the Negotiating Party');
        }
    }

    @IsTest
    public static void npo_updateTest_bulk() {
        Integer bulk_size = 50;
        Id notCurrentUserEEGId = [
                SELECT Id
                FROM User
                WHERE Id != :UserInfo.getUserId()
                AND Profile.Name = 'DE EEG'
                LIMIT 1
        ].Id;
        List<Account> negParties = new List<Account>();
        for (Integer i = 0; i < bulk_size; i++) {
            negParties.add(new Account(
                    Name = 'Negotiating Party' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials',
                    OwnerId = notCurrentUserEEGId
            ));
        }
        insert negParties;

        List<Account> newAccounts = new List<Account>();
        for (Integer i = 0; i < bulk_size; i++) {
            newAccounts.add(new Account(
                    Name = 'Child' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
            ));
        }
        insert newAccounts;

        Test.startTest();
        for (Integer i = 0; i < bulk_size; i++) {
            newAccounts[i].Negotiating_Party__c = negParties[i].Id;
        }
        update newAccounts;
        Test.stopTest();

        Map<Id, Account> negPartiesMap = new Map<Id, Account>([SELECT OwnerId FROM Account WHERE Id IN :negParties]);
        newAccounts = [SELECT OwnerId, Negotiating_Party__c FROM Account WHERE Id IN :newAccounts];
        for (Account newAccount : newAccounts) {
            System.assert(negPartiesMap.containsKey(newAccount.Negotiating_Party__c), 'Negotiating Party was changed during insert');
            System.assertEquals(negPartiesMap.get(newAccount.Negotiating_Party__c).OwnerId, newAccount.OwnerId, 'The Owner should have been the one of the Negotiating Party');
        }
    }


    @IsTest
    static void testExceptionHierarchyOnTopBulk() {
        List <Account> listGrandParents = [SELECT Id FROM Account WHERE Data_Migration_ID__c LIKE '%Grand Parent%'];
        List <Account> listParents = [SELECT Id FROM Account WHERE Data_Migration_ID__c LIKE '%Middle Parent%'];
        List <Account> listChildren = new List<Account>();

        for (Integer i = 0; i < BULK_SIZE; i++) {
            listChildren.add(new Account(
                    Name = 'Child',
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Negotiating_Party__c = listParents[i].Id,
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
            ));
            if (Math.mod(i, 2) == 0) {
                listParents[i].Negotiating_Party__c = listGrandParents[i].Id;
            }
        }
        insert listChildren;
        Test.startTest();
        List <Database.SaveResult> results = Database.update(listParents, false);
        Test.stopTest();
        Integer countSuccesses = 0;
        Integer countFailures = 0;
        for (Database.SaveResult saveResultItem : results) {
            if (saveResultItem.isSuccess()) {
                countSuccesses++;
            }
            if (!saveResultItem.isSuccess()) {
                countFailures++;
            }
        }
        System.assert(BULK_SIZE / 2 <= countSuccesses, 'Accounts should not have been updated because they would create a new hierarchy level.');
        System.assert(BULK_SIZE / 2 >= countFailures, 'Accounts should be updated successfully because they do not create a new hierarchy level.');
    }

    @IsTest
    static void testExceptionHierarchyInMiddleUpdateBulk() {
        List <Account> listGrandParents = [SELECT Id FROM Account WHERE Data_Migration_ID__c LIKE '%Grand Parent%'];
        List <Account> listParents = [SELECT Id FROM Account WHERE Data_Migration_ID__c LIKE '%Middle Parent%'];
        List <Account> listChildren = new List<Account>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            listChildren.add(new Account(
                    Name = 'Child' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
            ));
            if (Math.mod(i, 2) == 0) {
                listParents[i].Negotiating_Party__c = listGrandParents[i].Id;
            }
        }
        insert listChildren;
        update listParents;

        Test.startTest();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            listChildren[i].Negotiating_Party__c = listParents[i].Id;
        }
        List <Database.SaveResult> results = Database.update(listChildren, false);
        Test.stopTest();

        Integer countSuccesses = 0;
        Integer countFailures = 0;
        for (Database.SaveResult saveResultItem : results) {
            if (saveResultItem.isSuccess()) {
                countSuccesses++;
            }
            if (!saveResultItem.isSuccess()) {
                countFailures++;
            }
        }
        System.assert(BULK_SIZE / 2 >= countSuccesses, 'Accounts should not have been updated because they would create a new hierarchy level.');
        System.assert(BULK_SIZE / 2 <= countSuccesses, 'Accounts should be updated successfully because they do not create a new hierarchy level.');
    }


    @IsTest
    static void testExceptionHierarchyInMiddleInsertBulk() {
        List <Account> listGrandParents = [SELECT Id FROM Account WHERE Data_Migration_ID__c LIKE '%Grand Parent%'];
        List <Account> listParents = [SELECT Id FROM Account WHERE Data_Migration_ID__c LIKE '%Middle Parent%'];
        List <Account> listChildren = new List<Account>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            listChildren.add(new Account(
                    Name = 'Child' + i,
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Negotiating_Party__c = listParents[i].Id,
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
            ));
            if (Math.mod(i, 2) == 0) {
                listParents[i].Negotiating_Party__c = listGrandParents[i].Id;
            }
        }
        update listParents;

        Test.startTest();
        List <Database.SaveResult> results = Database.insert(listChildren, false);
        Test.stopTest();

        Integer countSuccesses = 0;
        Integer countFailures = 0;
        for (Database.SaveResult saveResultItem : results) {
            if (saveResultItem.isSuccess()) {
                countSuccesses++;
            }
            if (!saveResultItem.isSuccess()) {
                countFailures++;
            }
        }
        System.assert(BULK_SIZE / 2 >= countSuccesses, 'Accounts should not have been updated because they would create a new hierarchy level.');
        System.assert(BULK_SIZE / 2 <= countSuccesses, 'Accounts should be updated successfully because they do not create a new hierarchy level.');
    }


    @IsTest
    static void testDeleteAccountBulk() {
        List <Account> newAccounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            newAccounts.add(new Account(
                    Name = 'Child',
                    RecordTypeId = DE_ACC_RECORD_TYPE,
                    BillingCountry = 'Germany',
                    Customer_Type__c = 'not yet identified',
                    Customer_Segment_industry__c = 'Large industrials'
            ));
        }
        insert newAccounts;
        Test.startTest();
        delete newAccounts;
        Test.stopTest();
    }

    @IsTest
    public static void testCreateNewTasks() {
        Map<String, Account_KAM_Tasks_Configuration__mdt> templatesForTasks = fillMapWithTestCases();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        List<Task> existingTasks = new List<Task>{
                new Task(WhatId = testAccount.Id, Subject = 'Test Task', Description = 'Test'),
                new Task(WhatId = testAccount.Id, Subject = 'Test Task Notification', Description = 'Test Notification')
        };
        insert existingTasks;

        Test.startTest();
        msAccountHelper.createNewTasks(new List<Id>{
                testAccount.Id
        }, JSON.serialize(templatesForTasks));
        Test.stopTest();

        List<Task> createdTasks = [SELECT Id, Subject FROM Task WHERE AccountId = :testAccount.Id];
        System.assertEquals(templatesForTasks.values().size(), createdTasks.size());
    }

    @IsTest
    public static void testUpdateTaskOwner() {
        Map<String, Account_KAM_Tasks_Configuration__mdt> templatesForTasks = fillMapWithTestCases();
        Id currentUserId = UserInfo.getUserId();
        Id newKAMId = [SELECT Id FROM User WHERE ContactId = NULL AND Id <> :currentUserId AND Profile.UserLicense.Name = 'Salesforce' LIMIT 1].Id;
        List<Id> tasksToUpdate = new List<Id>();

        Account testAccount = new Account(Name = 'Test KAM Account', Customer_Type__c = 'not yet identified', OwnerId = newKAMId);
        insert testAccount;

        List<Task> existingTasks = new List<Task>();
        for (Account_KAM_Tasks_Configuration__mdt template : templatesForTasks.values()) {
            existingTasks.add(new Task(WhatId = testAccount.Id, Subject = template.Subject__c, Description = template.Description__c, OwnerId = currentUserId));
        }
        insert existingTasks;
        for (Task existingTask : existingTasks) {
            tasksToUpdate.add(existingTask.Id);
        }

        Test.startTest();
        msAccountHelper.updateTaskOwner(tasksToUpdate, JSON.serialize(templatesForTasks));
        Test.stopTest();

        List<Task>tasks = [SELECT OwnerId FROM Task WHERE AccountId = :testAccount.Id];
        System.assert(!tasks.isEmpty());
        for (Task task : tasks) {
            System.assertEquals(newKAMId, task.OwnerId);
        }
    }

    public static Map<String, Account_KAM_Tasks_Configuration__mdt> fillMapWithTestCases(){
        Map<String, Account_KAM_Tasks_Configuration__mdt> taskConfigByTaskSubjectMap = new Map<String, Account_KAM_Tasks_Configuration__mdt>();
        taskConfigByTaskSubjectMap.put('Test Task', new Account_KAM_Tasks_Configuration__mdt(
            Subject__c = 'Test Task', 
            Description__c = 'Test', 
            Deadline_in_days__c = 30, 
            Priority__c = 'High', 
            Send_Notification__c = false));
        taskConfigByTaskSubjectMap.put('Test Task Notification', new Account_KAM_Tasks_Configuration__mdt(
            Subject__c = 'Test Task Notification', 
            Description__c = 'Test', 
            Deadline_in_days__c = 30, 
            Priority__c = 'High', 
            Send_Notification__c = true));
        taskConfigByTaskSubjectMap.put('Test Task Creation', new Account_KAM_Tasks_Configuration__mdt(
            Subject__c = 'Test Task Creation', 
            Description__c = 'Test', 
            Deadline_in_days__c = 30, 
            Priority__c = 'High', 
            Send_Notification__c = false));
        taskConfigByTaskSubjectMap.put('Test Task Creation Notification', new Account_KAM_Tasks_Configuration__mdt(
            Subject__c = 'Test Task Creation Notification', 
            Description__c = 'Test', 
            Deadline_in_days__c = 30, 
            Priority__c = 'High', 
            Send_Notification__c = true));
            
        return taskConfigByTaskSubjectMap;
    }

    @IsTest
    public static void testLoad_KamTaskData(){
        Id currentUserId = UserInfo.getUserId();
        Id newKAMId = [SELECT Id FROM User WHERE ContactId = NULL AND Id <> :currentUserId AND Profile.UserLicense.Name = 'Salesforce' LIMIT 1].Id;
        Account testAccountOld = [SELECT Id FROM Account LIMIT 1];
        testAccountOld.Customer_Type__c = 'B - Single country, multiple product owners';
        testAccountOld.KAM_relevant__c = true;
        testAccountOld.KAM_Approval_Step__c = 'approved';
        testAccountOld.OwnerId = currentUserId;
        testAccountOld.KAM_proposal__c = 'something';
        testAccountOld.KAM_Proposed_User__c = newKAMId;
        testAccountOld.KAM_approved__c = null;
        update testAccountOld;

        Account testAccountNew = testAccountOld;
        testAccountNew.KAM_Approval_Step__c = 'approved';
        testAccountNew.OwnerId = newKAMId;
        testAccountNew.KAM_approved__c = Datetime.now();


        List<Task> existingTasks = new List<Task>{
            new Task(WhatId = testAccountOld.Id, Subject = 'Test Task', Description = 'Test', OwnerId = currentUserId),
            new Task(WhatId = testAccountOld.Id, Subject = 'Test Task Notification', Description = 'Test Notification', OwnerId = currentUserId)
        };
        insert existingTasks;

        msAccountHelper Helper = new msAccountHelper(
            new List<Account>{testAccountOld},
            new List<Account>{testAccountNew},
            new Map<Id, Account>{testAccountOld.Id => testAccountOld},
            new Map<Id, Account>{testAccountNew.Id => testAccountNew}
        );
        Helper.taskConfigByTaskSubjectMap = fillMapWithTestCases();

        Test.startTest();
        Helper.load_KamTaskData();
        Helper.defineKAMTasksToCreateOrReassign(testAccountNew);
        Test.stopTest();

        System.assert(Helper.taskConfigByTaskSubjectMap != null, 'The map should not be null.');
        System.assert(Helper.KAMTasksOfAccounts != null, 'The list should not be null.');
        System.assert(!Helper.taskIdsForOwnerUpdate.isEmpty(), 'The list should not be empty.');
        System.assert(!Helper.tasksByAccountId.isEmpty(), 'The map should not be empty.');
    }

    @IsTest
    static void testKAMApprovalProcesses() {
        Account testAccountApprove = new Account(Name = 'KAM Test',
                Customer_Type__c = 'A - Multi-country',
                KAM_pending__c = true,
                KAM_proposal__c = 'testuser@statkraft.mindsquare.user.dev'
        );
        Account testAccountReject = new Account(Name = 'KAM Test2',
                Customer_Type__c = 'A - Multi-country',
                KAM_pending__c = true,
                KAM_proposal__c = 'testuser@statkraft.mindsquare.user.dev'
        );

        Test.startTest();
        insert testAccountApprove;
        insert testAccountReject;
        testAccountApprove.KAM_Approval_Step__c = 'approved';
        testAccountReject.KAM_Approval_Step__c = 'rejected';
        update testAccountApprove;
        update testAccountReject;


        Test.stopTest();

        testAccountApprove = [
                SELECT Id, KAM_approved__c, KAM_pending__c,KAM_proposal__c
                FROM Account
                WHERE Id = :testAccountApprove.Id
        ];
        testAccountReject = [
                SELECT Id, KAM_approved__c, KAM_pending__c,KAM_proposal__c
                FROM Account
                WHERE Id = :testAccountReject.Id
        ];
        System.assert(testAccountApprove.KAM_approved__c != null);
        System.assert(testAccountApprove.KAM_pending__c == false);
        System.assert(testAccountApprove.KAM_proposal__c == null);

        System.assert(testAccountReject.KAM_approved__c == null);
        System.assert(testAccountReject.KAM_pending__c == false);
        System.assert(testAccountReject.KAM_proposal__c == null);
    }

    @IsTest
    static void testKAMRelevantProcesses() {
        Account testAccountRelevant = new Account(Name = 'KAM Test',
                Customer_Type__c = 'A - Multi-country',
                RecordTypeId = DE_ACC_RECORD_TYPE

        );

        Test.startTest();
        insert testAccountRelevant;
        update testAccountRelevant;

        //check that relevant was set, because Customer Type is kam relevant
        testAccountRelevant = [
                SELECT Id, KAM_relevant__c
                FROM Account
                WHERE Id = :testAccountRelevant.Id
        ];
        System.assert(testAccountRelevant.KAM_relevant__c == true);

        testAccountRelevant.KAM_relevant_approved__c = Datetime.now();
        testAccountRelevant.last_KAM_Submitter__c = UserInfo.getUserId();
        testAccountRelevant.KAM_proposal__c = 'testuser@statkraft.mindsquare.user.dev';
        testAccountRelevant.KAM_pending__c = true;
        testAccountRelevant.KAM_Proposal_Comment__c = 'hello world';
        testAccountRelevant.Customer_Type__c = 'not yet identified';
        update testAccountRelevant;

        testAccountRelevant = [
                SELECT Id, KAM_Approval_Step__c, KAM_Proposal_Comment__c, KAM_approved__c, KAM_pending__c, KAM_relevant__c,
                        KAM_relevant_approved__c, last_KAM_Submitter__c, KAM_proposal__c
                FROM Account
                WHERE Id = :testAccountRelevant.Id
        ];
        System.assert(testAccountRelevant.KAM_Approval_Step__c == null);
        System.assert(testAccountRelevant.KAM_Proposal_Comment__c == null);
        System.assert(testAccountRelevant.KAM_approved__c == null);
        System.assert(testAccountRelevant.KAM_pending__c == false);
        System.assert(testAccountRelevant.KAM_proposal__c == null);
        System.assert(testAccountRelevant.KAM_relevant__c == false);
        System.assert(testAccountRelevant.KAM_relevant_approved__c == null);
        System.assert(testAccountRelevant.last_KAM_Submitter__c == null);


        testAccountRelevant.Customer_Type__c = 'A - Multi-country';
        update testAccountRelevant;
        Test.stopTest();

        testAccountRelevant = [
                SELECT Id, KAM_Approval_Step__c, KAM_Proposal_Comment__c, KAM_approved__c, KAM_pending__c, KAM_relevant__c,
                        KAM_relevant_approved__c, last_KAM_Submitter__c, KAM_proposal__c
                FROM Account
                WHERE Id = :testAccountRelevant.Id
        ];
        System.assert(testAccountRelevant.KAM_relevant__c == true);
    }

    @IsTest
    static void testKAMNotRelevantRevertProcesses() {
        Account testAccountRelevant = new Account(Name = 'KAM Test',
                Customer_Type__c = 'not yet identified',
                KAM_proposal__c = 'testuser@statkraft.mindsquare.user.dev',
                KAM_relevant__c = false,
                not_KAM_relevant__c = true
        );

        Test.startTest();
        insert testAccountRelevant;

        testAccountRelevant.KAM_relevant__c = true;
        update testAccountRelevant;


        Test.stopTest();

        testAccountRelevant = [
                SELECT Id, not_KAM_relevant__c, KAM_relevant__c, KAM_relevant_approved__c
                FROM Account
                WHERE Id = :testAccountRelevant.Id
        ];
        System.assert(testAccountRelevant.not_KAM_relevant__c == false);
        System.assert(testAccountRelevant.KAM_relevant_approved__c != null);
    }

    @IsTest
    static void testKAMStartProposalProcesses() {
        Account testAccountRelevant = new Account(Name = 'KAM Test',
                Customer_Type__c = 'A - Multi-country',
                KAM_relevant__c = true,
                KAM_Approval_Step__c = 'approved',
                KAM_Proposal_Comment__c = 'hello world',
                KAM_approved__c = Datetime.now(),
                KAM_pending__c = false,
                KAM_relevant_approved__c = Datetime.now(),
                last_KAM_Submitter__c = UserInfo.getUserId()
        );

        Test.startTest();
        insert testAccountRelevant;

        testAccountRelevant = [
                SELECT Id, not_KAM_relevant__c, KAM_relevant__c, KAM_relevant_approved__c, KAM_Approval_Step__c,
                        KAM_pending__c, KAM_request_sent__c, KAM_proposal__c
                FROM Account
                WHERE Id = :testAccountRelevant.Id
        ];
        testAccountRelevant.KAM_proposal__c = 'testuser@statkraft.mindsquare.user.dev';

        update testAccountRelevant;


        Test.stopTest();

        testAccountRelevant = [
                SELECT Id, not_KAM_relevant__c, KAM_relevant__c, KAM_relevant_approved__c, KAM_Approval_Step__c,
                        KAM_pending__c, KAM_request_sent__c, KAM_proposal__c
                FROM Account
                WHERE Id = :testAccountRelevant.Id
        ];
        System.assert(testAccountRelevant.KAM_Approval_Step__c == null);
        System.assert(testAccountRelevant.KAM_pending__c == true);
        System.assert(testAccountRelevant.KAM_request_sent__c != null);
    }

    @IsTest
    public static void shouldCalculateNegotiatingPartyChildrenOnInsert() {
        Integer numberOfChildAccountsToInsert = 200;

        Account negotiatingParty = new Account(Name = 'Negotiating Party Account Name');
        insert negotiatingParty;

        List<Account> childAccounts = new List<Account>();
        for (Integer i = 0; i < numberOfChildAccountsToInsert; i++) {
            Account childAcc = new Account(Name = 'Child Account Name ' + i, Negotiating_Party__c = negotiatingParty.Id);
            childAccounts.add(childAcc);
        }

        Test.startTest();
        insert childAccounts;
        Test.stopTest();

        Account updatedNegotiatingParty = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        System.assertEquals(numberOfChildAccountsToInsert, updatedNegotiatingParty.Negotiating_for_X_Accounts__c);
    }

    @IsTest
    public static void shouldCalculateNegotiatingPartyChildrenOnUpdate() {
        Integer numberOfChildAccountsToInsert = 200;

        Account negotiatingParty = new Account(Name = 'Negotiating Party Account Name');
        insert negotiatingParty;

        List<Account> childAccounts = new List<Account>();
        for (Integer i = 0; i < numberOfChildAccountsToInsert; i++) {
            Account childAcc = new Account(Name = 'Child Account Name ' + i);
            childAccounts.add(childAcc);
        }
        insert childAccounts;

        Account negotiatingPartyBeforeUpdate = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        Test.startTest();
        for (Account acc : childAccounts) {
            acc.Negotiating_Party__c = negotiatingParty.Id;
        }
        update childAccounts;
        Test.stopTest();

        Account negotiatingPartyAfterUpdate = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        System.assertEquals(0, negotiatingPartyBeforeUpdate.Negotiating_for_X_Accounts__c);
        System.assertEquals(numberOfChildAccountsToInsert, negotiatingPartyAfterUpdate.Negotiating_for_X_Accounts__c);
    }

    @IsTest
    public static void shouldCalculateNegotiatingPartyChildrenOnDeletingReference() {
        Integer numberOfChildAccountsToInsert = 200;

        Account negotiatingParty = new Account(Name = 'Negotiating Party Account Name');
        insert negotiatingParty;

        List<Account> childAccounts = new List<Account>();
        for (Integer i = 0; i < numberOfChildAccountsToInsert; i++) {
            Account childAcc = new Account(Name = 'Child Account Name ' + i, Negotiating_Party__c = negotiatingParty.Id);
            childAccounts.add(childAcc);
        }
        insert childAccounts;

        Account negotiatingPartyBeforeUpdate = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        Test.startTest();
        for (Account acc : childAccounts) {
            acc.Negotiating_Party__c = null;
        }
        update childAccounts;
        Test.stopTest();

        Account negotiatingPartyAfterUpdate = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        System.assertEquals(numberOfChildAccountsToInsert, negotiatingPartyBeforeUpdate.Negotiating_for_X_Accounts__c);
        System.assertEquals(0, negotiatingPartyAfterUpdate.Negotiating_for_X_Accounts__c);
    }

    @IsTest
    public static void shouldCalculateNegotiatingPartyChildrenOnDelete() {
        Integer numberOfChildAccountsToInsert = 200;

        Account negotiatingParty = new Account(Name = 'Negotiating Party Account Name');
        insert negotiatingParty;

        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 0; i < numberOfChildAccountsToInsert; i++) {
            Account childAcc = new Account(Name = 'Child Account Name ' + i, Negotiating_Party__c = negotiatingParty.Id);
            accountsToInsert.add(childAcc);
        }
        insert accountsToInsert;

        Account negotiatingPartyBeforeDeletion = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        Test.startTest();
        delete accountsToInsert;
        Test.stopTest();

        Account negotiatingPartyAfterDeletion = [SELECT Negotiating_for_X_Accounts__c FROM Account WHERE Id = :negotiatingParty.Id];

        System.assertEquals(numberOfChildAccountsToInsert, negotiatingPartyBeforeDeletion.Negotiating_for_X_Accounts__c);
        System.assertEquals(0, negotiatingPartyAfterDeletion.Negotiating_for_X_Accounts__c);
    }

    @IsTest
    private static void ACERCodeChangeTest() {

        Account contractHolder = new Account (
                Name = 'Contract Holder',
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                RecordTypeId = DE_ACC_RECORD_TYPE,
                REMIT_Acer_Code__c = 'old ACER');
        insert contractHolder;

        Contract__c contract = new Contract__c(
                Start_Date__c = Date.today().addMonths(-6),
                End_Date__c = Date.today().addMonths(6),
                Status__c = 'Active',
                Approved__c = true,
                Contract_Holder__c = contractHolder.Id,
                Contracted_Capacity__c = 1000,
                Contracted_Annual_Production__c = 10000,
                Legal_Capacity__c = 1000,
                REMIT_Reporting_Relevant__c = true,
                Contract_Date__c = Date.today().addMonths(-6).addDays(-1),
                Contract_Type_New__c = 'Feed in Tariff PPA',
                Product_Type_New__c = 'Direct Marketing',
                Country__c = 'Germany',
                Name = 'test Contract ACER');
        insert contract;

        contract = [SELECT Id, (SELECT Id FROM Cases__r) FROM Contract__c WHERE Id = :contract.Id];
        Integer initialCaseAmount = contract.Cases__r.size();

        Test.startTest();
        contractHolder.REMIT_Acer_Code__c = 'new ACER';
        update contractHolder;
        Test.stopTest();

        contract = [SELECT Id, (SELECT Id FROM Cases__r) FROM Contract__c WHERE Id = :contract.Id];
        System.assert(initialCaseAmount < contract.Cases__r.size(), 'Remit Case was not Generated');
    }
    @IsTest
    public static void shouldCreateMarketPresenceRecordsOnInsert(){
        String markets = 'Germany;France;Italy';
        List<String> marketsList = markets.split(';');
        Account acc = new Account(Name = 'Test', Market_Presence__c = markets);
        
        Test.startTest();
        insert acc;
        Test.stopTest();

        List<Market_Presence__c> createdMarketPresenceRecords = [SELECT Id, Name FROM Market_Presence__c WHERE Account__c = :acc.Id];
        System.assertEquals(marketsList.size(), createdMarketPresenceRecords.size());
        for(Market_Presence__c marketPresence : createdMarketPresenceRecords){
            System.assert(marketsList.contains(marketPresence.Name));
            marketsList.remove(marketsList.indexOf(marketPresence.Name));
        }
    }
    @IsTest
    public static void shouldCreateMarketPresenceRecordsOnUpdate(){
        String markets = 'Germany;France';
        List<String> marketsList = markets.split(';');
        String marketsUpdated = 'Germany;France;Italy';
        List<String> marketsUpdatedList = marketsUpdated.split(';');
        Account acc = new Account(Name = 'Test', Market_Presence__c = markets);
        insert acc;
        
        List<Market_Presence__c> createdMarketPresenceRecordsBeforeUpdate = [SELECT Id, Name FROM Market_Presence__c WHERE Account__c = :acc.Id];
        
        Test.startTest();
        acc.Market_Presence__c = marketsUpdated;
        update acc;
        Test.stopTest();

        List<Market_Presence__c> createdMarketPresenceRecordsAfterUpdate = [SELECT Id, Name FROM Market_Presence__c WHERE Account__c = :acc.Id];
        System.assertEquals(marketsList.size(), createdMarketPresenceRecordsBeforeUpdate.size());
        System.assertEquals(marketsUpdatedList.size(), createdMarketPresenceRecordsAfterUpdate.size());
        for(Market_Presence__c marketPresence : createdMarketPresenceRecordsAfterUpdate){
            System.assert(marketsUpdatedList.contains(marketPresence.Name));
            marketsUpdatedList.remove(marketsUpdatedList.indexOf(marketPresence.Name));
        }
    }
    @IsTest
    public static void shouldDeleteMarketPresenceRecordsOnUpdate(){
        String markets = 'Germany;France;Italy';
        List<String> marketsList = markets.split(';');
        String marketsUpdated = 'Germany;France';
        List<String> marketsUpdatedList = marketsUpdated.split(';');
        Account acc = new Account(Name = 'Test', Market_Presence__c = markets);
        insert acc;
        
        List<Market_Presence__c> createdMarketPresenceRecordsBeforeUpdate = [SELECT Id, Name FROM Market_Presence__c WHERE Account__c = :acc.Id];
        
        Test.startTest();
        acc.Market_Presence__c = marketsUpdated;
        update acc;
        Test.stopTest();

        List<Market_Presence__c> createdMarketPresenceRecordsAfterUpdate = [SELECT Id, Name FROM Market_Presence__c WHERE Account__c = :acc.Id];
        System.assertEquals(marketsList.size(), createdMarketPresenceRecordsBeforeUpdate.size());
        System.assertEquals(marketsUpdatedList.size(), createdMarketPresenceRecordsAfterUpdate.size());

        for(Market_Presence__c marketPresence : createdMarketPresenceRecordsAfterUpdate){
            System.assert(marketsUpdatedList.contains(marketPresence.Name));
            marketsUpdatedList.remove(marketsUpdatedList.indexOf(marketPresence.Name));
        }
    }
    @IsTest
    public static void scm_testSyncCustomerNeedsIntoMarketPresence(){
        String marketWithoutProductNeed = 'Estonia';

        Account acc = new Account (
            Name = 'Contract Holder',
            Market_Presence__c = 'Germany'
        );
        insert acc;

        List<Product_Need__c> productsToInsert = new List<Product_Need__c>();

        Product_Need__c pn1 = new Product_Need__c();
        pn1.Name = 'Pn1';
        pn1.Country__c = 'Germany';
        pn1.Product_Line__c = 'Physical route-to-market services [Market Access]';
        pn1.Product_Category__c = 'Real-time asset dispatch';
        pn1.Product_Owner__c = 'MAN';
        pn1.Contact_Person__c = UserInfo.getUserId();
        productsToInsert.add(pn1);

        Product_Need__c pn2 = new Product_Need__c();
        pn2.Name = 'Pn2';
        pn2.Country__c = 'France';
        pn2.Product_Line__c = 'Upstream Origination';
        pn2.Product_Category__c = 'Upstream GoOs';
        pn2.Product_Owner__c = 'MEN';
        productsToInsert.add(pn2);
        insert productsToInsert;


        for(Product_Need__c pn : productsToInsert){
            msKAMProductNeedSelectorController.saveLink(acc.Id, pn.Id, '');
        }

        Test.startTest();
        //At this point the Market Presence should be Germany;France and we now remove France and add Estonia.
        acc.Market_Presence__c = pn1.Country__c + ';' + marketWithoutProductNeed;
        update acc;
        Test.stopTest();

        Account accUpdated = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id];
        for(Product_Need__c pn : productsToInsert){
            System.assert(
                accUpdated.Market_Presence__c.contains(pn.Country__c), 
                pn.Country__c + 'should be in the Market Presence field.'
            );
        }
        System.assert(
            accUpdated.Market_Presence__c.contains(marketWithoutProductNeed), 
            marketWithoutProductNeed + 'should not be removed from Market Presence in the Sync Process.'
        );
    }
}
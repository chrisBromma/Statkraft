@isTest
public with sharing class SandboxMigrationIdBatchTest {
    @isTest
    static void testIfThrowsExceptionForInvalidSObject() {
        Exception ex;

        try {
            SandboxMigrationIdBatch batchTest = new SandboxMigrationIdBatch('Task');
        } catch (Exception e) {
            ex = e;
        }

        System.assert(
            ex != null &&
            ex.getTypeName() == 'SandboxMigrationIdBatch.InvalidFieldException',
            'The Batch Job start method did not hinder us from creating a Batch instance for an SObject without Migration Id.'
        );
    }

    @isTest
    static void testIfMigrationIdPopulated() {
        //Because in the future the Account will be running with an autopopulation of Sandbox Migration Id, we update the SBMId to null after the insert.
        List<Account> accountList = msGranularTestDataFactory.createTestAccounts(
            1,
            'Germany',
            Application.RecordTypes.byDeveloperName('Account', 'Account').Id
        );
        Batch_Job_Schedule__c sch = BatchJobSchedulerTestDataFactory.createWeeklyBatchJobSchedule();
        insert sch;
        Batch_Apex_Job__c job = BatchJobSchedulerTestDataFactory.createBatchJob(sch);
        job.Batch_Class_Name__c = 'SandboxMigrationIdBatch';
        insert job;
        Account acc = accountList[0];
        acc.Sandbox_Migration_Id__c = 'circumvent_future_autopopulation';
        insert acc;

        acc.Sandbox_Migration_Id__c = null;
        update acc;

        Test.startTest();
        SandboxMigrationIdBatch accountBatchTest = new SandboxMigrationIdBatch('Account');
        //Setting index here for testing purposes, as Account is not part of Sandbox Migration Id Object CMDT.
        accountBatchTest.index = 0;
        Database.executeBatch(accountBatchTest);
        Test.stopTest();

        acc = [SELECT Id, Sandbox_Migration_Id__c FROM Account WHERE Id = :acc.Id];
        System.assert(
            acc.Sandbox_Migration_Id__c != null,
            'The Sandbox Migration Id Batch has not populated the Account Migration Id'
        );
        System.assert(
            SandboxMigrationIdBatch.nextObjectFoundInTest,
            'There was no next Batch Job to fire (either an error or no more Custom Metadata Types in the table).'
        );
    }

    @isTest
    static void testIndexbasedConstructor() {
        List<SandboxMigrationIdObject__mdt> smidObjects = [
            SELECT Id, ObjectName__c
            FROM SandboxMigrationIdObject__mdt
            ORDER BY ObjectName__c ASC
        ];
        String firstObjectName = smidObjects[0].ObjectName__c;

        //this will automatically call the Constructor for index 0;
        SandboxMigrationIdBatch batchForChain = new SandboxMigrationIdBatch();

        System.assertEquals(firstObjectName, batchForChain.sobjectName, 'The Object Name was not retrieved correctly');
    }

    @isTest
    static void testSettingDisabledAndReactivated() {
        ProcessSettings__c ps = new ProcessSettings__c();
        SandboxMigrationIdObject__mdt smidObject = [
            SELECT Id, ObjectName__c, DeactivatedProcessSetting__c
            FROM SandboxMigrationIdObject__mdt
            WHERE DeactivatedProcessSetting__c != NULL
            LIMIT 1
        ];
        Batch_Job_Schedule__c sch = BatchJobSchedulerTestDataFactory.createWeeklyBatchJobSchedule();
        insert sch;
        Batch_Apex_Job__c job = BatchJobSchedulerTestDataFactory.createBatchJob(sch);
        job.Batch_Class_Name__c = 'SandboxMigrationIdBatch';
        insert job;

        ps.put(smidObject.DeactivatedProcessSetting__c, false);
        upsert ps;
        String firstObjectName = smidObject.ObjectName__c;

        //this will automatically call the Constructor for index 0;
        SandboxMigrationIdBatch verificationTest = new SandboxMigrationIdBatch();

        System.assert(
            SandboxMigrationIdBatch.MAP_DISABLED_PROCESSES.containsKey(firstObjectName),
            'Object was not found for construction of Map'
        );
        verificationTest.disabledSetting = smidObject.DeactivatedProcessSetting__c;
        verificationTest.sobjectName = firstObjectName;

        Test.startTest();
        Database.executeBatch(verificationTest);
        Test.stopTest();
    }
}
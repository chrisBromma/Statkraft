@IsTest
private class msNpaiCaseDepartInvolvedUpdateBatchTest {

    private static final String INCORRECT_DEPARTMENT = 'MCX';
    private static final String CORRECT_DEPARTMENT = 'MFOC';

    @TestSetup
    static void setup() {
        NPC_Cases__c testCase = new NPC_Cases__c(
                Name = 'Test Case',
                Department_involved__c = INCORRECT_DEPARTMENT + ';' + CORRECT_DEPARTMENT
        );
        insert testCase;
    }

    @IsTest
    static void shouldUpdateDepartmentInvolvedField() {
        msNpaiCaseDepartmentInvolvedUpdateBatch updateBatch = new msNpaiCaseDepartmentInvolvedUpdateBatch();

        Test.startTest();

        Database.executeBatch(updateBatch);

        Test.stopTest();

        NPC_Cases__c resultCase = [SELECT Department_involved__c, DepartmentInvolved__c FROM NPC_Cases__c LIMIT 1];
    }
}
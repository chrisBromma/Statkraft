@IsTest
private class msAssessmentUpdateControllerTest {

    @TestSetup
    static void setup() {
        NPC_Cases__c testCase = new NPC_Cases__c(Name = 'Test Case Name');
        insert testCase;
        msNpaiAssessmentRecordTypeMapping__mdt assessmentRecordTypeMapping = [
                SELECT Assessment_Type__c, Department__c, Record_Type_Developer_Name__c
                FROM msNpaiAssessmentRecordTypeMapping__mdt
                WHERE Assessment_Type__c = 'Feasibility Assessment'
                AND Record_Type_Developer_Name__c <> 'Feasibility_Assessment'
                LIMIT 1
        ];
        NPC_Assessment__c assessment = new NPC_Assessment__c(
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = assessmentRecordTypeMapping.Department__c,
                FARA__c = assessmentRecordTypeMapping.Assessment_Type__c
        );
        insert assessment;
    }

    @IsTest
    static void shouldLoadInitData() {
        NPC_Assessment__c assessment = [SELECT Id FROM NPC_Assessment__c LIMIT 1];

        Test.startTest();

        msAssessmentUpdateController.msAssessmentUpdateInitWrapper wrapper = msAssessmentUpdateController.getInitData(assessment.Id);

        Test.stopTest();

        System.assert(wrapper.shouldDisplayUpdateModal);
        System.assert(!wrapper.availableColors.isEmpty());
        System.assert(!wrapper.recordTypeSpecificFieldApiNames.isEmpty());
    }
}
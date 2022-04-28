@IsTest
private class msNpaiAssessmentHandlerTest {

    private static final List<String> possibleDepartments = new List<String>{'FTG', 'Legal'};
    private static final String TEST_DESCRIPTION_TEXT = 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.';

    @TestSetup
    static void setup() {
        NPC_Cases__c testCase = new NPC_Cases__c(
                Name = 'Test Case Name'
        );
        insert testCase;
    }

    @IsTest
    static void shouldUpdateDepartmentsInvolvedOnInsert() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        Map<Object, List<String>> dependentValues = ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c);

        Test.startTest();

        List<NPC_Assessment__c> assessmentsWithDepartments = new List<NPC_Assessment__c>();
        for(Integer i = 0; i < possibleDepartments.size(); i++) {
            NPC_Assessment__c assessment = new NPC_Assessment__c();
            assessment.NPC_Case__c = testCase.Id;
            assessment.Statkraft_Department__c = possibleDepartments[i];
            assessment.FARA__c = dependentValues.get(assessment.Statkraft_Department__c)[0];
            assessmentsWithDepartments.add(assessment);
        }
        insert assessmentsWithDepartments;

        Test.stopTest();

        NPC_Cases__c resultCase = [SELECT Id, DepartmentInvolved__c FROM NPC_Cases__c LIMIT 1];
        List<String> resultDepartments = resultCase.DepartmentInvolved__c.split(';');
        System.assertEquals(possibleDepartments.size(), resultDepartments.size());
    }

    @IsTest
    static void shouldUpdateDepartmentsInvolvedOnUpdate() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        Map<Object, List<String>> dependentValues = ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c);
        testCase.DepartmentInvolved__c = possibleDepartments[0];
        update testCase;

        NPC_Cases__c caseAfterUpdate = [SELECT Id, DepartmentInvolved__c FROM NPC_Cases__c LIMIT 1];
        List<String> resultDepartmentsAfterUpdate = caseAfterUpdate.DepartmentInvolved__c.split(';');
        System.assertEquals(1, resultDepartmentsAfterUpdate.size());

        Test.startTest();
        NPC_Assessment__c assessment = new NPC_Assessment__c();
        assessment.NPC_Case__c = testCase.Id;
        assessment.Statkraft_Department__c = possibleDepartments[1];
        assessment.FARA__c = dependentValues.get(assessment.Statkraft_Department__c)[0];
        insert assessment;
        Test.stopTest();

        NPC_Cases__c resultCase = [SELECT Id, DepartmentInvolved__c FROM NPC_Cases__c LIMIT 1];
        List<String> resultDepartments = resultCase.DepartmentInvolved__c.split(';');
        System.assertEquals(2, resultDepartments.size());
    }

    @IsTest
    static void shouldCheckAssessmentRecordTypeCustomMtdSetup() {
        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosByDeveloperName();
        List<msNpaiAssessmentRecordTypeMapping__mdt> recordTypeMappings = [
                SELECT Assessment_Type__c, Department__c, Record_Type_Developer_Name__c
                FROM msNpaiAssessmentRecordTypeMapping__mdt
        ];

        Test.startTest();

        for(msNpaiAssessmentRecordTypeMapping__mdt recordTypeMapping : recordTypeMappings) {
            System.assert(
                    recordTypeMap.containsKey(recordTypeMapping.Record_Type_Developer_Name__c),
                    'Error looking for record type: ' + recordTypeMapping.Record_Type_Developer_Name__c
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void shouldAssignAppropriateRecordType() {
        List<NPC_Assessment__c> assessmentsToInsert = new List<NPC_Assessment__c>();
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];

        for(msNpaiAssessmentRecordTypeMapping__mdt recordTypeMapping : [
                SELECT Assessment_Type__c, Department__c, Record_Type_Developer_Name__c
                FROM msNpaiAssessmentRecordTypeMapping__mdt
        ]) {
            NPC_Assessment__c assessment = new NPC_Assessment__c();
            assessment.Statkraft_Department__c = recordTypeMapping.Department__c;
            assessment.FARA__c = recordTypeMapping.Assessment_Type__c;
            assessment.NPC_Case__c = testCase.Id;
            assessmentsToInsert.add(assessment);
        }

        Test.startTest();

        insert assessmentsToInsert;

        Test.stopTest();

        for(NPC_Assessment__c assessment : assessmentsToInsert) {
            System.assertNotEquals(null, assessment.Id);
        }
    }

    @IsTest
    static void shouldUpdateRelatedFieldsOnCase() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        Map<String,NPC_Assessment__c> assessmentsToProcessByRecordTypeName = new Map<String,NPC_Assessment__c>();
        Map<String, FieldSet> fieldSetMap = SObjectType.NPC_Assessment__c.FieldSets.getMap();
        Map<String, msNpaiAssessmentRecordTypeMapping__mdt> recordTypeMappingByDeveloperName = new Map<String, msNpaiAssessmentRecordTypeMapping__mdt>();
        for(msNpaiAssessmentRecordTypeMapping__mdt mapping : [
                SELECT Assessment_Type__c, Department__c, Record_Type_Developer_Name__c
                FROM msNpaiAssessmentRecordTypeMapping__mdt
        ]) {
            recordTypeMappingByDeveloperName.put(mapping.Record_Type_Developer_Name__c, mapping);
        }

        for(FieldSet fs : fieldSetMap.values()) {
            NPC_Assessment__c testAssessment = new NPC_Assessment__c();
            testAssessment.NPC_Case__c = testCase.Id;
            testAssessment.Statkraft_Department__c = recordTypeMappingByDeveloperName.get(fs.getName()).Department__c;
            testAssessment.FARA__c = recordTypeMappingByDeveloperName.get(fs.getName()).Assessment_Type__c;
            assessmentsToProcessByRecordTypeName.put(fs.getName(), testAssessment);
        }
        insert assessmentsToProcessByRecordTypeName.values();

        Test.startTest();

        Map<String, SObjectField> assessmentFields = Schema.SObjectType.NPC_Assessment__c.fields.getMap();
        List<String> changedFieldNames = new List<String>();
        for(String recordTypeName : assessmentsToProcessByRecordTypeName.keySet()) {
            NPC_Assessment__c currentAssessment = assessmentsToProcessByRecordTypeName.get(recordTypeName);
            for(FieldSetMember fsm : fieldSetMap.get(recordTypeName.toLowerCase()).getFields()) {
                if(fsm.getType() == DisplayType.TEXTAREA) {
                    currentAssessment.put(fsm.getSObjectField(), TEST_DESCRIPTION_TEXT);
                } else if(fsm.getType() == DisplayType.BOOLEAN) {
                    currentAssessment.put(fsm.getSObjectField(), true);
                } else if(fsm.getType() == DisplayType.PICKLIST) {
                    currentAssessment.put(fsm.getSObjectField(), assessmentFields.get(fsm.getFieldPath()).getDescribe().getPicklistValues()[0].getValue());
                }
                changedFieldNames.add(fsm.getFieldPath());
            }
            assessmentsToProcessByRecordTypeName.put(recordTypeName, currentAssessment);
        }
        update assessmentsToProcessByRecordTypeName.values();

        Test.stopTest();

        String query = 'SELECT ' + String.join(changedFieldNames, ', ') + ' FROM NPC_Cases__c LIMIT 1';
        NPC_Cases__c resultCase = (NPC_Cases__c) Database.query(query)[0];

        for(String recordTypeName : assessmentsToProcessByRecordTypeName.keySet()) {
            NPC_Assessment__c currentAssessment = assessmentsToProcessByRecordTypeName.get(recordTypeName);
            for(FieldSetMember fsm : fieldSetMap.get(recordTypeName.toLowerCase()).getFields()) {
                System.assertEquals(currentAssessment.get(fsm.getSObjectField()), resultCase.get(fsm.getFieldPath()));
            }
        }
    }

    @IsTest
    static void shouldValidateUniqueCreditRiskAssessment() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];

        NPC_Assessment__c creditRiskAssessment = new NPC_Assessment__c(
                Name = 'Credit Risk Assessment',
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = 'MFRC',
                FARA__c = 'Credit Risk Assessment'
        );
        insert creditRiskAssessment;

        Test.startTest();

        NPC_Assessment__c duplicateCreditRiskAssessment = new NPC_Assessment__c(
                Name = 'Duplicate Credit Risk Assessment',
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = 'MFRC',
                FARA__c = 'Credit Risk Assessment'
        );

        try {
            insert duplicateCreditRiskAssessment;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('There is currently'));
        }

        Test.stopTest();
    }

    @IsTest
    static void shouldValidateUniqueMarketRiskAssessment() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];

        NPC_Assessment__c marketRiskAssessment = new NPC_Assessment__c(
                Name = 'Market Risk Assessment',
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = 'MFRM',
                FARA__c = 'Market Risk Assessment'
        );
        insert marketRiskAssessment;

        Test.startTest();

        NPC_Assessment__c duplicateMarketRiskAssessment = new NPC_Assessment__c(
                Name = 'Duplicate Market Risk Assessment',
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = 'MFRM',
                FARA__c = 'Market Risk Assessment'
        );

        try {
            insert duplicateMarketRiskAssessment;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('There is currently'));
        }

        Test.stopTest();
    }

    @IsTest
    public static void shouldStartAfterUpdateTrigger() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        testCase.CSR_Check__c = 'Successful';
        update testCase;

        NPC_Assessment__c marketRiskAssessment = new NPC_Assessment__c(
                Name = 'Market Risk Assessment',
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = 'MFRM',
                FARA__c = 'Market Risk Assessment',
                CSRCheck__c = true,
                Conclusion__c = 'Test Conclusion'
        );
        insert marketRiskAssessment;

        marketRiskAssessment.Status2__c = 'Done';
        update marketRiskAssessment;

        NPC_Cases__c updatedTestCase = [SELECT Id, Assessment_Conclusion__c FROM NPC_Cases__c WHERE Id = :testCase.Id];

        System.assertEquals(marketRiskAssessment.Conclusion__c, updatedTestCase.Assessment_Conclusion__c);
    }

    @IsTest
    public static void shouldStartAfterInsertTrigger() {
        NPC_Cases__c testCase = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        testCase.CSR_Check__c = 'Successful';
        update testCase;

        NPC_Assessment__c marketRiskAssessment = new NPC_Assessment__c(
                Name = 'Market Risk Assessment',
                NPC_Case__c = testCase.Id,
                Statkraft_Department__c = 'MFRM',
                FARA__c = 'Market Risk Assessment',
                Conclusion__c = 'Test Conclusion',
                Status2__c = 'Done'
        );
        insert marketRiskAssessment;

        NPC_Cases__c updatedTestCase = [SELECT Id, Assessment_Conclusion__c FROM NPC_Cases__c WHERE Id = :testCase.Id];

        System.assertEquals(marketRiskAssessment.Conclusion__c, updatedTestCase.Assessment_Conclusion__c);
    }
}
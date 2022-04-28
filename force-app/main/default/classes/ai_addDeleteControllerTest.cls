@isTest
private class ai_addDeleteControllerTest {

    @isTest
    static void saveAssessments() {
        Map<Object, List<String>> dependentPicklistValues = ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c);
        String caseName = 'NPAI Case Name';
        String departmentName = 'Legal';
        String longCaseNameSuffix = '';
        for(Integer i=0; i < 60; i++) {
            longCaseNameSuffix += 'a';
        }
        NPC_Cases__c parentCase = new NPC_Cases__c(
                Name = caseName + longCaseNameSuffix,
                CSR_Check__c = 'Pending',
                ProductType__c = 'Test Product Type'
        );
        insert parentCase;

        Test.startTest();

        List<NPC_Assessment__c> assessmentsToProcess = New List<NPC_Assessment__c>();
        assessmentsToProcess.add(new NPC_Assessment__c(
                NPC_Case__c = parentCase.Id,
                Statkraft_Department__c = departmentName,
                FARA__c = dependentPicklistValues.get(departmentName)[0]
        ));
        addDeleteController.saveAssessments(parentCase.Id, assessmentsToProcess);

        Test.stopTest();

        System.assertNotEquals(null, assessmentsToProcess[0].Id);
        System.assert(assessmentsToProcess[0].Name.contains(caseName));
        System.assert(assessmentsToProcess[0].Name.contains(departmentName));
    }

    @IsTest
    static void shouldThrowDMLOnSave() {
        NPC_Cases__c parentCase = new NPC_Cases__c(
                Name = 'Case Name',
                CSR_Check__c = 'Pending',
                ProductType__c = 'Test Product Type'
        );
        insert parentCase;

        Test.startTest();

        List<NPC_Assessment__c> assessmentsToProcess = New List<NPC_Assessment__c>();
        assessmentsToProcess.add(new NPC_Assessment__c(NPC_Case__c = parentCase.Id));
        try {
            addDeleteController.saveAssessments(parentCase.Id, assessmentsToProcess);
        } catch (AuraHandledException e) {
            System.assert(true);
        }

        Test.stopTest();

        System.assertEquals(null, assessmentsToProcess[0].Id);
    }

    @isTest
    static void shouldGetAssessmentRecordTypeId() {
        Test.startTest();

        Id assessmentRecordTypeId = addDeleteController.getDefaultAssessmentRecordTypeId();

        Test.stopTest();

        System.assertNotEquals(null, assessmentRecordTypeId);
    }

    @isTest
    static void shouldGetDependentPicklistValues() {
        Test.startTest();

        Map<Object,List<String>> result =
                addDeleteController.getDependentPicklistValuesByName('NPC_Assessment__c', 'FARA__c');

        Test.stopTest();

        List<String> resultList = result.get('MFRM');
        System.assert(resultList != null);
        System.assert(resultList.size() == 2);
        resultList = result.get('MFRC');
        System.assert(resultList != null);
        System.assert(resultList.size() == 1);
        resultList = result.get('Unused');
        System.assert( resultList == null );
    }
}
@isTest
private class ai_addDeleteControllerImpTest {

    @isTest
    static void saveImplementations() {
        Implementation__c implementation = new Implementation__c(
                Name = 'Test name',
                OwnerId = UserInfo.getUserId(),
                Implementation_Type__c = Implementation__c.Implementation_Type__c.getDescribe().getPickListValues()[0].getValue()
        );
        List<Implementation__c> implementations = new List<Implementation__c>{implementation};

        Test.startTest();

        addDeleteControllerImp.saveImplementations(implementations);

        Test.stopTest();

        System.assertNotEquals(null, implementations[0].Id);
    }

    @isTest
    static void shouldThrowErrorOnImplementationsSave() {
        Implementation__c implementation = new Implementation__c(
                Name = 'Test name',
                OwnerId = UserInfo.getUserId(),
                Implementation_Type__c = Implementation__c.Implementation_Type__c.getDescribe().getPickListValues()[0].getValue(),
                StartDate__c = Date.today().addDays(5),
                EndDate__c = Date.today()
        );
        List<Implementation__c> implementations = new List<Implementation__c>{implementation};

        Test.startTest();

        try {
            addDeleteControllerImp.saveImplementations(implementations);
        } catch (AuraHandledException e) {
            System.assert(true);
        }

        Test.stopTest();
        System.assertEquals(null, implementations[0].Id);
    }

    @isTest
    static void shouldGetImplementationTypes() {
        Implementation__c implementation = new Implementation__c();
        Set<String> expectedOptions = new Set<String>();
        for (Schema.PicklistEntry entry : Implementation__c.Implementation_Type__c.getDescribe().getPickListValues()) {
            expectedOptions.add(entry.getValue());
        }

        Test.startTest();

        List<String> selectOptions = addDeleteControllerImp.getselectOptions(implementation, 'Implementation_Type__c');

        Test.stopTest();

        for(String option : selectOptions) {
            expectedOptions.remove(option);
        }
        System.assert(expectedOptions.isEmpty());
    }
}
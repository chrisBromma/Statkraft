@isTest
private class ai_PicklistValueControllerTest {

    @isTest
    static void shouldGetSelectOptions() {
        NPC_Cases__c case1 = new NPC_Cases__c(Name = 'Xaver', CSR_Check__c = 'Pending', ProductType__c = 'Acme Account', Commodityadditionalinfo__c = 'Sepp');
        Set<String> expectedOptions = new Set<String>();
        for (Schema.PicklistEntry entry : NPC_Cases__c.CSR_Check__c.getDescribe().getPickListValues()) {
            expectedOptions.add(entry.getValue());
        }

        Test.startTest();

        List<String> selectOptions = ai_PicklistValueController.getselectOptions(case1, 'CSR_Check__c');

        Test.stopTest();

        for(String option : selectOptions) {
            expectedOptions.remove(option);
        }
        System.assert(expectedOptions.isEmpty());
    }

    @isTest
    static void shouldGetDependentPicklistValues() {
        Test.startTest();

        Map<Object,List<String>> result =
                ai_PicklistValueController.getDependentPicklist(NPC_Assessment__c.FARA__c);

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
public with sharing class addDeleteControllerImp {

    @AuraEnabled
    public static void saveImplementations(List<Implementation__c> implementations) {
        try {
            insert implementations;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<String> getselectOptions(sObject objObject, string field) {
        return ai_PicklistValueController.getselectOptions(objObject, field);
    }
}
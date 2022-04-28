public without sharing class addDeleteController {

    @AuraEnabled
    public static void saveAssessments(Id caseRecordId, List<NPC_Assessment__c> listAssessment) {
        try {
            NPC_Cases__c caseWithName = [SELECT Name FROM NPC_Cases__c WHERE Id = :caseRecordId];
            for(NPC_Assessment__c assessment : listAssessment) {
                assessment.Name = assessment.Statkraft_Department__c + ' - ' + caseWithName.Name;
                if (assessment.Name.length() > 80) {
                    assessment.Name = assessment.Name.substring(0, 80);
                }
            }
            insert listAssessment;
        } catch (DmlException e) {
            String message = '';
            for(Integer i = 0; i < e.getNumDml(); i++) {
                message += e.getDmlMessage(i) + '\n';
            }
            throw new AuraHandledException(message);
        }
    }

    @AuraEnabled
    public static Id getDefaultAssessmentRecordTypeId() {
        for(Schema.RecordTypeInfo rti : NPC_Assessment__c.SObjectType.getDescribe().getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                return rti.getRecordTypeId();
            }
        }
        return null;
    }

    @AuraEnabled
    public static Map<Object,List<String>> getDependentPicklistValuesByName(String sObjectName, String dependentPicklistField) {
        return ai_PicklistValueController.getDependentPicklist(Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(dependentPicklistField));
    }
}
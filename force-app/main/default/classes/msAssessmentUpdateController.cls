public with sharing class msAssessmentUpdateController {

    @AuraEnabled
    public static msAssessmentUpdateInitWrapper getInitData(Id recordId) {
        msAssessmentUpdateInitWrapper wrapper = new msAssessmentUpdateInitWrapper();
        NPC_Assessment__c assessment = [SELECT Id, Colors__c, RecordType.DeveloperName FROM NPC_Assessment__c WHERE Id = :recordId LIMIT 1];
        wrapper.shouldDisplayUpdateModal = String.isEmpty(assessment.Colors__c);
        wrapper.availableColors = ai_PicklistValueController.getselectOptions(recordId.getSobjectType(), NPC_Assessment__c.Colors__c.getDescribe().getName());
        FieldSet currentAssessmentFieldSet = Schema.SObjectType.NPC_Assessment__c.fieldSets.getMap().get(assessment.RecordType.DeveloperName);
        if(currentAssessmentFieldSet != null && !currentAssessmentFieldSet.getFields().isEmpty()) {
            wrapper.recordTypeSpecificFieldApiNames = new List<String>();
            for(FieldSetMember fsm : currentAssessmentFieldSet.getFields()) {
                wrapper.recordTypeSpecificFieldApiNames.add(fsm.getFieldPath());
            }
        }
        return wrapper;
    }

    public class msAssessmentUpdateInitWrapper {
        @AuraEnabled
        public Boolean shouldDisplayUpdateModal { get; set; }
        @AuraEnabled
        public List<String> availableColors { get; set; }
        @AuraEnabled
        public List<String> recordTypeSpecificFieldApiNames { get; set; }
    }
}
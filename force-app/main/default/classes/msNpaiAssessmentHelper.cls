public without sharing class msNpaiAssessmentHelper {

    private static final Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosByDeveloperName();

    public class NotExistingRecordTypeException extends Exception {

    }

    public static void handleRecordTypeAssignment(List<NPC_Assessment__c> newAssessments) {
        Map<String, String> recordTypeDevNameByDepartmentAssessmentType = new Map<String, String>();
        for (msNpaiAssessmentRecordTypeMapping__mdt recordTypeMapping : [
                SELECT Id, Assessment_Type__c, Department__c, Record_Type_Developer_Name__c
                FROM msNpaiAssessmentRecordTypeMapping__mdt
        ]) {
            recordTypeDevNameByDepartmentAssessmentType.put(
                    recordTypeMapping.Department__c + recordTypeMapping.Assessment_Type__c,
                    recordTypeMapping.Record_Type_Developer_Name__c
            );
        }

        for (NPC_Assessment__c assessment : newAssessments) {
            String recordTypeDeveloperName = recordTypeDevNameByDepartmentAssessmentType.get(assessment.Statkraft_Department__c + assessment.FARA__c);
            if (!recordTypeMap.containsKey(recordTypeDeveloperName)) {
                throw new NotExistingRecordTypeException('Record type not found for department ' + assessment.Statkraft_Department__c + ' and assessment type ' + assessment.FARA__c);
            }
            assessment.RecordTypeId = recordTypeMap.get(recordTypeDeveloperName).getRecordTypeId();
        }
    }

    public static Map<Id, NPC_Cases__c> handleDepartmentsInvolved(Map<Id, NPC_Assessment__c> oldAssessmentsByIds, List<NPC_Assessment__c> newAssessments) {
        Set<Id> caseIdsToUpdate = new Set<Id>();
        for (NPC_Assessment__c assessment : newAssessments) {
            if (oldAssessmentsByIds == null) {
                caseIdsToUpdate.add(assessment.NPC_Case__c);
            } else if (oldAssessmentsByIds.get(assessment.Id).Statkraft_Department__c != assessment.Statkraft_Department__c) {
                caseIdsToUpdate.add(assessment.NPC_Case__c);
            }
        }

        if (!caseIdsToUpdate.isEmpty()) {
            Map<Id, NPC_Cases__c> casesMapToUpdate = new Map<Id, NPC_Cases__c>([SELECT Id, DepartmentInvolved__c FROM NPC_Cases__c WHERE Id IN :caseIdsToUpdate]);
            for (NPC_Assessment__c assessment : (List<NPC_Assessment__c>) Trigger.new) {
                NPC_Cases__c currentCase = casesMapToUpdate.get(assessment.NPC_Case__c);
                if (String.isEmpty(currentCase.DepartmentInvolved__c)) {
                    currentCase.DepartmentInvolved__c = assessment.Statkraft_Department__c;
                } else if (!currentCase.DepartmentInvolved__c.contains(assessment.Statkraft_Department__c)) {
                    List<String> departments = currentCase.DepartmentInvolved__c.split(';');
                    departments.add(assessment.Statkraft_Department__c);
                    currentCase.DepartmentInvolved__c = String.join(departments, ';');
                }
            }
            return casesMapToUpdate;
        }
        return new Map<Id, NPC_Cases__c>();
    }

    public static Map<Id, NPC_Cases__c> handleNpaiCaseRelevantFieldsUpdate(Map<Id, NPC_Assessment__c> oldAssessmentsByIds, List<NPC_Assessment__c> newAssessments) {
        Map<String, FieldSet> fieldSetMap = SObjectType.NPC_Assessment__c.fieldSets.getMap();
        Map<Id, String> fieldSetNameByRecordTypeId = new Map<Id, String>();
        for (String fieldSetName : fieldSetMap.keySet()) {
            fieldSetNameByRecordTypeId.put(recordTypeMap.get(fieldSetMap.get(fieldSetName).getName()).getRecordTypeId(), fieldSetName);
        }
        Map<Id, NPC_Cases__c> casesToUpdateMap = new Map<Id, NPC_Cases__c>();
        for (NPC_Assessment__c newAssessment : newAssessments) {
            NPC_Assessment__c oldAssessment = oldAssessmentsByIds.get(newAssessment.Id);
            if (fieldSetNameByRecordTypeId.get(newAssessment.RecordTypeId) != null) {
                if (!casesToUpdateMap.containsKey(newAssessment.NPC_Case__c)) {
                    casesToUpdateMap.put(newAssessment.NPC_Case__c, new NPC_Cases__c(Id = newAssessment.NPC_Case__c));
                }
                NPC_Cases__c currentCase = casesToUpdateMap.get(newAssessment.NPC_Case__c);
                for (FieldSetMember fsm : fieldSetMap.get(fieldSetNameByRecordTypeId.get(newAssessment.RecordTypeId)).getFields()) {
                    if (newAssessment.get(fsm.getSObjectField()) != oldAssessment.get(fsm.getSObjectField())) {
                        currentCase.put(fsm.getFieldPath(), newAssessment.get(fsm.getSObjectField()));
                    }
                }
            }
        }
        return casesToUpdateMap;
    }

    public static void validateUniquenessOfRiskAssessments(List<NPC_Assessment__c> newAssessments) {
        Id creditRiskAssessmentRTId = recordTypeMap.get('Credit_Risk_Assesment').getRecordTypeId();
        Id marketRiskAssessmentRTId = recordTypeMap.get('Market_Risk_Assessment').getRecordTypeId();
        Map<Id, RecordTypeInfo> recordTypeInfosByIds = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosById();
        Map<Id, List<NPC_Assessment__c>> assessmentsByCaseIds = new Map<Id, List<NPC_Assessment__c>>();
        for (NPC_Assessment__c assessment : newAssessments) {
            if (assessment.RecordTypeId.equals(creditRiskAssessmentRTId) || assessment.RecordTypeId.equals(marketRiskAssessmentRTId)) {
                if (!assessmentsByCaseIds.containsKey(assessment.NPC_Case__c)) {
                    assessmentsByCaseIds.put(assessment.NPC_Case__c, new List<NPC_Assessment__c>());
                }
                assessmentsByCaseIds.get(assessment.NPC_Case__c).add(assessment);
            }
        }
        for (NPC_Assessment__c assessment : [
                SELECT Id, NPC_Case__c, RecordTypeId, NPC_Case__r.Name
                FROM NPC_Assessment__c
                WHERE RecordTypeId IN (:creditRiskAssessmentRTId, :marketRiskAssessmentRTId)
                AND NPC_Case__c IN :assessmentsByCaseIds.keySet()
        ]) {
            for (NPC_Assessment__c newAssessment : assessmentsByCaseIds.get(assessment.NPC_Case__c)) {
                if (newAssessment.RecordTypeId == assessment.RecordTypeId) {
                    newAssessment.addError('There is currently a ' + recordTypeInfosByIds.get(newAssessment.RecordTypeId).getName() + ' tied to ' + assessment.NPC_Case__r.Name);
                }
            }
        }
    }
}
public without sharing class msNpaiAssessmentHandler extends TriggerHandlerExtension {

    private Map<Id, NPC_Cases__c> casesToUpdate = new Map<Id, NPC_Cases__c>();

    public msNpaiAssessmentHandler() {
        super();
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate((List<NPC_Assessment__c>) Trigger.new, false);
            msNpaiAssessmentHelper.handleRecordTypeAssignment((List<NPC_Assessment__c>) Trigger.new);
            msNpaiAssessmentHelper.validateUniquenessOfRiskAssessments((List<NPC_Assessment__c>) Trigger.new);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            casesToUpdate = msNpaiAssessmentHelper.handleNpaiCaseRelevantFieldsUpdate((Map<Id, NPC_Assessment__c>) Trigger.oldMap, (List<NPC_Assessment__c>) Trigger.new);
        }
        if (Trigger.isInsert) {
            casesToUpdate = msNpaiAssessmentHelper.handleDepartmentsInvolved((Map<Id, NPC_Assessment__c>) Trigger.oldMap, (List<NPC_Assessment__c>) Trigger.new);
        }
    }

    //public override void beforeInsert(SObject obj) { addToLoopCount();}

    //public override void beforeUpdate(SObject oldObj, SObject obj) { addToLoopCount();}

    //public override void beforeDelete(SObject obj) { addToLoopCount();}

    public override void afterInsert(SObject obj) {
        addToLoopCount();

        NPC_Assessment__c newAssessment = (NPC_Assessment__c) obj;
        if (newAssessment.Status2__c == 'Done'
                && newAssessment.FARA__c == 'Market Risk Assessment') {
            NPC_Cases__c caseUpdate = new NPC_Cases__c(
                    Id = newAssessment.NPC_Case__c
            );
            if (casesToUpdate.containsKey(newAssessment.NPC_Case__c)) {
                caseUpdate = casesToUpdate.get(newAssessment.NPC_Case__c);
            }
            caseUpdate.RA__c = true;
            caseUpdate.Assessment_Conclusion__c = newAssessment.Conclusion__c;
            casesToUpdate.put(caseUpdate.Id, caseUpdate);
        }
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        addToLoopCount();

        NPC_Assessment__c newAssessment = (NPC_Assessment__c) obj;
        NPC_Assessment__c oldAssessment = (NPC_Assessment__c) oldObj;

        if (newAssessment.Status2__c == 'Done'
                && newAssessment.FARA__c == 'Market Risk Assessment'
                && (newAssessment.Status2__c != oldAssessment.Status2__c
                || newAssessment.FARA__c != oldAssessment.FARA__c)) {
            NPC_Cases__c caseUpdate = new NPC_Cases__c(
                    Id = newAssessment.NPC_Case__c
            );
            if (casesToUpdate.containsKey(newAssessment.NPC_Case__c)) {
                caseUpdate = casesToUpdate.get(newAssessment.NPC_Case__c);
            }
            caseUpdate.RA__c = true;
            caseUpdate.Assessment_Conclusion__c = newAssessment.Conclusion__c;
            casesToUpdate.put(caseUpdate.Id, caseUpdate);
        }
    }

    //public override void afterDelete(SObject obj) {addToLoopCount();}

    public override void andFinally() {
        if(!casesToUpdate.isEmpty()) {
            update casesToUpdate.values();
        }
    }
}
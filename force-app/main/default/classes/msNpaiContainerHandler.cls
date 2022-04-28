/**
 * @description       : NPAI Container Trigger Handler (for Approval Items)
 * @author            : Dennis Grzyb
 * @group             : NPAI
 * @last modified on  : 2021-08-04
 * @last modified by  : Dennis Grzyb
 * @testedBy          : msNpaiContainerApprovalItemHandlerTest
**/

public with sharing class msNpaiContainerHandler extends TriggerHandlerExtension {
    public static final Id APPROVAL_ITEM_RECORD_TYPE = Schema.SObjectType.NPAI_Container__c.getRecordTypeInfosByDeveloperName().get('Approval_Item').getRecordTypeId();
    public static final String APPROVAL_ITEM_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_ITEM_STATUS_IN_APPROVAL = 'In Approval';
    public static final String APPROVAL_ITEM_STATUS_REJECTED = 'Rejected';
    public static final String APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME = 'NPAI_Case_Approval_Path';
    public static final String CASE_APPROVED_EMAIL_TEMPLATE_NAME = 'Case_Approval_Approved';
    public static final String CASE_REJECTED_EMAIL_TEMPLATE_NAME = 'Case_Approval_Rejected';
    public static Map<Id, Map<Id, NPC_Assessment__c>> caseToAssessmentMap = new Map<Id, Map<Id, NPC_Assessment__c>>();

    private msNpaiContainerApprovalItemHandler npaiContainerApprovalItemHandler;

    public msNpaiContainerHandler() {
        super();
        npaiContainerApprovalItemHandler = new msNpaiContainerApprovalItemHandler();
    }

    public override void bulkBefore() { 
        if(Trigger.isInsert){
            SandboxMigrationIdGenerator.populate((List<NPAI_Container__c>) Trigger.new, false);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            List<NPAI_Container__c> containers = (List<NPAI_Container__c>) Trigger.new;
            List<Id> caseIds = new List<Id>();
            for (NPAI_Container__c tempContainer : containers) {
                caseIds.add(tempContainer.NPAI_Case__c);
            }

            List<NPC_Assessment__c> assessments = [SELECT Id, RecordTypeId, OwnerId, NPC_Case__c FROM NPC_Assessment__c WHERE NPC_Case__c IN :caseIds];
            for (NPC_Assessment__c tempAssessment : assessments) {
                Map<Id, NPC_Assessment__c> assessmentsOfCase = caseToAssessmentMap.get(tempAssessment.NPC_Case__c);
                if (assessmentsOfCase == null)
                    assessmentsOfCase = new Map<Id, NPC_Assessment__c>();

                assessmentsOfCase.put(tempAssessment.RecordTypeId, tempAssessment);
                caseToAssessmentMap.put(tempAssessment.NPC_Case__c, assessmentsOfCase);
            }
        }
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        addToLoopCount();

        npaiContainerApprovalItemHandler.addToPostProcessing((NPAI_Container__c) oldObj, (NPAI_Container__c) obj);
    }

    public override void andFinally() {
        npaiContainerApprovalItemHandler.postProcess();
    }
}
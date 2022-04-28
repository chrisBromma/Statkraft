public without sharing class msNpaiContainerApprovalItemHandler {

    public Map<Id, Id> caseIdsByApprovedContainers;
    private Map<Id, Id> caseIdsByRejectedContainers;
    public Map<Id, Set<Id>> approvalProcessContainerIdsByCaseId;
    private Map<Id, ProcessInstance> approvalWorkItemsByContainerIds;
    private Map<Id, NPAI_Container__c> containersByIds;
    private Map<Id, NPC_Cases__c> npaiCases;
    public static final Id CREDIT_RISK_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosByDeveloperName().get('Credit_Risk_Assesment').getRecordTypeId();
    public static final Id MFRM_FEASIBILITY_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosByDeveloperName().get('MFRM_Feasibility_Assessment').getRecordTypeId();


    public msNpaiContainerApprovalItemHandler() {
        npaiCases = new Map<Id, NPC_Cases__c>();
        containersByIds = new Map<Id, NPAI_Container__c>();
        approvalWorkItemsByContainerIds = new Map<Id, ProcessInstance>();
        approvalProcessContainerIdsByCaseId = new Map<Id, Set<Id>>();
        caseIdsByApprovedContainers = new Map<Id, Id>();
        caseIdsByRejectedContainers = new Map<Id, Id>();
    }

    public void addToPostProcessing(NPAI_Container__c oldRecord, NPAI_Container__c newRecord) {
        if (newRecord.RecordTypeId == msNpaiContainerHandler.APPROVAL_ITEM_RECORD_TYPE
                && !newRecord.History_Item__c
                && (oldRecord.Approval_Status__c != newRecord.Approval_Status__c)) {
            if (newRecord.Approval_Status__c == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED) {
                caseIdsByApprovedContainers.put(newRecord.Id, newRecord.NPAI_Case__c);
                approvalProcessContainerIdsByCaseId.put(newRecord.NPAI_Case__c, new Set<Id>());
            }
            if (newRecord.Approval_Status__c == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED) {
                caseIdsByRejectedContainers.put(newRecord.Id, newRecord.NPAI_Case__c);
                approvalProcessContainerIdsByCaseId.put(newRecord.NPAI_Case__c, new Set<Id>());
            }
        }
    }

    public void postProcess() {
        if (!caseIdsByApprovedContainers.isEmpty() || !caseIdsByRejectedContainers.isEmpty()) {
            getRelatedApprovals();
            handleApprovedContainers();
            handleRejectedContainers();
        }
    }

    private void getRelatedApprovals() {
        for (NPAI_Container__c container : [
                SELECT Id, NPAI_Case__c, Approval_Status__c, Approval_Version__c
                FROM NPAI_Container__c
                WHERE (NPAI_Case__c IN :caseIdsByApprovedContainers.values() OR NPAI_Case__c IN :caseIdsByRejectedContainers.values())
                AND History_Item__c = false
        ]) {
            containersByIds.put(container.Id, container);
            approvalProcessContainerIdsByCaseId.get(container.NPAI_Case__c).add(container.Id);
        }

        for (ProcessInstance approvalProcess : [
                SELECT Id, TargetObjectId, (SELECT Id, ActorId, StepStatus FROM Steps ORDER BY CreatedDate DESC LIMIT 1), (SELECT Id FROM Workitems)
                FROM ProcessInstance
                WHERE TargetObjectId IN :containersByIds.keySet()
                AND ProcessDefinition.DeveloperName = :msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME
        ]) {
            approvalWorkItemsByContainerIds.put(approvalProcess.TargetObjectId, approvalProcess);
        }

        npaiCases = new Map<Id, NPC_Cases__c>([
                SELECT Id, FO_Requestor__c, OwnerId, FOSponsor__c, Status__c
                FROM NPC_Cases__c
                WHERE Id IN :caseIdsByApprovedContainers.values()
                OR Id IN :caseIdsByRejectedContainers.values()
        ]);
    }

    private void handleApprovedContainers() {
        Map<Id, NPC_Cases__c> casesToSave = new Map<Id, NPC_Cases__c>();
        Map<Id, Id> caseIdsByOwnerIds = new Map<Id, Id>();
        Map<Id, NPAI_Container__c> containersToUpdate = new Map<Id, NPAI_Container__c>();
        for (Id approvedContainerId : caseIdsByApprovedContainers.keySet()) {
            Boolean isApproved = true;
            Decimal latestVersion = containersByIds.get(approvedContainerId).Approval_Version__c;
            List<NPAI_Container__c> containers = new List<NPAI_Container__c>();
            for (Id containerId : approvalProcessContainerIdsByCaseId.get(caseIdsByApprovedContainers.get(approvedContainerId))) {
                NPAI_Container__c container = containersByIds.get(containerId);
                if (container.Approval_Version__c == latestVersion && container.Approval_Status__c != msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED
                        && container.Approval_Status__c != approvalWorkItemsByContainerIds.get(containerId).Steps[0].StepStatus) {
                    isApproved = false;
                    break;
                }
                container.History_Item__c = true;
                containers.add(container);
            }
            if (isApproved) {
                NPC_Cases__c currentCase = npaiCases.get(caseIdsByApprovedContainers.get(approvedContainerId));
                currentCase.Status__c = 'Implementation';
                currentCase.In_Approval_Process__c = false;
                currentCase.RAFAApproval__c = true;
                casesToSave.put(currentCase.Id, currentCase);
                caseIdsByOwnerIds.put(currentCase.OwnerId, currentCase.Id);
                containersToUpdate.putAll(containers);
            }
        }
        if (!casesToSave.isEmpty()) {
            update containersToUpdate.values();
            unlockAndUpdateCases(casesToSave.values());
            sendNotifications(
                    extractRecipientForApprovedCases(casesToSave.values(), caseIdsByOwnerIds),
                    msNpaiContainerHandler.CASE_APPROVED_EMAIL_TEMPLATE_NAME
            );
        }
    }

    private void handleRejectedContainers() {
        List<Approval.ProcessWorkitemRequest> approvalItemsToReject = new List<Approval.ProcessWorkitemRequest>();
        List<NPAI_Container__c> containersToProcess = new List<NPAI_Container__c>();
        Map<Id, Set<Id>> recipientIdsByObjectId = new Map<Id, Set<Id>>();
        Map<Id, Id> rejectedContainerIdByCaseOwnerId = new Map<Id, Id>();
        List<NPC_Cases__c> casesToSave = new List<NPC_Cases__c>();
        for (Id rejectedContainerId : caseIdsByRejectedContainers.keySet()) {
            ProcessInstanceStep rejectionStep = approvalWorkItemsByContainerIds.get(rejectedContainerId).Steps[0];
            if (rejectionStep.StepStatus == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED) {
                Set<Id> recipientIds = new Set<Id>();
                Id rejectedById = rejectionStep.ActorId;
                NPC_Cases__c currentCase = npaiCases.get(caseIdsByRejectedContainers.get(rejectedContainerId));
                Decimal latestVersion = containersByIds.get(rejectedContainerId).Approval_Version__c;
                for (Id containerId : approvalProcessContainerIdsByCaseId.get(currentCase.Id)) {
                    NPAI_Container__c container = containersByIds.get(containerId);
                    if (latestVersion == container.Approval_Version__c) {
                        ProcessInstanceStep latestApprovalStep = approvalWorkItemsByContainerIds.get(containerId).Steps[0];
                        if (rejectedContainerId != containerId) {
                            recipientIds.add(latestApprovalStep.ActorId);
                        }
                        if (container.Approval_Status__c == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_IN_APPROVAL) {
                            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                            request.setWorkitemId(approvalWorkItemsByContainerIds.get(containerId).Workitems[0].Id);
                            request.setAction('Reject');
                            approvalItemsToReject.add(request);
                        }
                        container.History_Item__c = true;
                        container.Rejected_By__c = rejectedById;
                        containersToProcess.add(container);
                    }
                }
                currentCase.Status__c = 'RAFA Summary';
                currentCase.In_Approval_Process__c = false;
                casesToSave.add(currentCase);
                recipientIds.add(currentCase.FO_Requestor__c);
                if (currentCase.FOSponsor__c != null) {
                    recipientIds.add(currentCase.FOSponsor__c);
                }

                Map<Id, NPC_Assessment__c> assessmentsOfCase = msNpaiContainerHandler.caseToAssessmentMap.get(currentCase.Id);
                if (assessmentsOfCase != null) {
                    if (assessmentsOfCase.containsKey(CREDIT_RISK_ASSESSMENT_RECORD_TYPE)) {
                        recipientIds.add(assessmentsOfCase.get(CREDIT_RISK_ASSESSMENT_RECORD_TYPE).OwnerId);
                    }
                    if (assessmentsOfCase.containsKey(MFRM_FEASIBILITY_ASSESSMENT_RECORD_TYPE)) {
                        recipientIds.add(assessmentsOfCase.get(MFRM_FEASIBILITY_ASSESSMENT_RECORD_TYPE).OwnerId);
                    }
                }
                recipientIdsByObjectId.put(rejectedContainerId, recipientIds);
                rejectedContainerIdByCaseOwnerId.put(currentCase.OwnerId, rejectedContainerId);
            }
        }

        if (!casesToSave.isEmpty()) {
            update containersToProcess;
            Approval.process(approvalItemsToReject);
            unlockAndUpdateCases(casesToSave);
            sendNotifications(
                    extractRecipientUserIdsFromGroupByObjectId(recipientIdsByObjectId, rejectedContainerIdByCaseOwnerId),
                    msNpaiContainerHandler.CASE_REJECTED_EMAIL_TEMPLATE_NAME
            );
        }
    }

    private void unlockAndUpdateCases(List<NPC_Cases__c> cases) {
        Approval.unlock(cases);
        update cases;
    }

    private Map<Id, Set<Id>> extractRecipientForApprovedCases(List<NPC_Cases__c> cases, Map<Id, Id> objectIdsByOwnerIds) {
        Map<Id, Set<Id>> recipientIdsByObjectId = new Map<Id, Set<Id>>();
        for (NPC_Cases__c c : cases) {
            Set<Id> recipientIds = new Set<Id>{
                    c.FO_Requestor__c
            };
            if (c.FOSponsor__c != null) {
                recipientIds.add(c.FOSponsor__c);
            }

            Map<Id, NPC_Assessment__c> assessmentsOfCase = msNpaiContainerHandler.caseToAssessmentMap.get(c.Id);
            if (assessmentsOfCase != null) {
                if (assessmentsOfCase.containsKey(CREDIT_RISK_ASSESSMENT_RECORD_TYPE)) {
                    recipientIds.add(assessmentsOfCase.get(CREDIT_RISK_ASSESSMENT_RECORD_TYPE).OwnerId);
                }
                if (assessmentsOfCase.containsKey(MFRM_FEASIBILITY_ASSESSMENT_RECORD_TYPE)) {
                    recipientIds.add(assessmentsOfCase.get(MFRM_FEASIBILITY_ASSESSMENT_RECORD_TYPE).OwnerId);
                }
            }
            recipientIdsByObjectId.put(c.Id, recipientIds);
        }
        return extractRecipientUserIdsFromGroupByObjectId(recipientIdsByObjectId, objectIdsByOwnerIds);
    }

    private Map<Id, Set<Id>> extractRecipientUserIdsFromGroupByObjectId(Map<Id, Set<Id>> recipientIdsByObjectId, Map<Id, Id> objectIdsByOwnerIds) {
        for (GroupMember member : [
                SELECT Id, UserOrGroupId, GroupId
                FROM GroupMember
                WHERE GroupId IN :objectIdsByOwnerIds.keySet()
        ]) {
            if (member.UserOrGroupId.getSobjectType() == User.SObjectType) {
                recipientIdsByObjectId.get(objectIdsByOwnerIds.get(member.GroupId)).add(member.UserOrGroupId);
            }
        }
        for (Id ownerId : objectIdsByOwnerIds.keySet()) {
            if (ownerId.getSobjectType() == User.SObjectType) {
                recipientIdsByObjectId.get(objectIdsByOwnerIds.get(ownerId)).add(ownerId);
            }
        }
        return recipientIdsByObjectId;
    }

    private void sendNotifications(Map<Id, Set<Id>> recipientIdsByObjectIds, String templateName) {
        for (Id key : recipientIdsByObjectIds.keySet()) {
            sendEmails(key, recipientIdsByObjectIds.get(key), templateName);
        }
    }

    @Future
    private static void sendEmails(Id recordId, Set<Id> recipientIds, String templateName) {
        EmailTemplate template = msNotificationLogic.getEmailTemplateByName(templateName);
        sendTemplatedEmailToRecipients(recipientIds, recordId, template);
    }

    private static void sendTemplatedEmailToRecipients(Set<Id> recipients, Id relatedRecord, EmailTemplate template) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Id recipient : recipients) {
            emails.add(msNotificationLogic.createSingleEmailMessageWithTemplateId(recipient, relatedRecord, template.Id));
        }
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
    }
}
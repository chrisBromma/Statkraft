public without sharing class msNPAICaseApprovalController {

    public static final Id CREDIT_RISK_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosByDeveloperName().get('Credit_Risk_Assesment').getRecordTypeId();
    public static final Id MARKET_RISK_ASSESSMENT_RECORD_TYPE = Schema.SObjectType.NPC_Assessment__c.getRecordTypeInfosByDeveloperName().get('Market_Risk_Assessment').getRecordTypeId();
    public static final String NPAI_CONTAINER_APPROVAL_ITEM_RECORD_TYPE_DEVELOPER_NAME = 'Approval_Item';
    public static final String EMPTY_DESCRIPTION = 'N/A';

    @AuraEnabled
    public static NPAICaseApprovalDescriptionWrapper getApprovalDescriptions(Id recordId) {
        NPC_Cases__c caseWithRelatedAssessments = [
                SELECT Id, Name, OperationalRisk__c, GreenLightforFOMandateApproval__c, Assessment_Conclusion__c, (
                        SELECT Id, Approval_Required__c, RecordTypeId
                        FROM NPC_Assesments__r
                        WHERE RecordTypeId IN (:CREDIT_RISK_ASSESSMENT_RECORD_TYPE, :MARKET_RISK_ASSESSMENT_RECORD_TYPE)
                )
                FROM NPC_Cases__c
                WHERE Id = :recordId
        ];
        NPAICaseApprovalDescriptionWrapper wrapper = new NPAICaseApprovalDescriptionWrapper();
        wrapper.operationalApprovalRequest = extractDescription(caseWithRelatedAssessments.OperationalRisk__c);
        wrapper.caseName = caseWithRelatedAssessments.Name;
        wrapper.greenLightForMandateApproval = caseWithRelatedAssessments.GreenLightforFOMandateApproval__c;
        for (NPC_Assessment__c assessment : caseWithRelatedAssessments.NPC_Assesments__r) {
            if(assessment.RecordTypeId == CREDIT_RISK_ASSESSMENT_RECORD_TYPE) {
                wrapper.creditRiskAssessmentApprovalRequest = extractDescription(assessment.Approval_Required__c);
            }
            if(assessment.RecordTypeId == MARKET_RISK_ASSESSMENT_RECORD_TYPE) {
                wrapper.marketRiskAssessmentApprovalRequest = extractDescription(assessment.Approval_Required__c);
            }
        }
        wrapper.market_risk_assessment_conclusion = extractDescription(caseWithRelatedAssessments.Assessment_Conclusion__c);
        wrapper.market_risk_assessment_conclusion_with_links = turnImagesIntoLinks(extractDescription(caseWithRelatedAssessments.Assessment_Conclusion__c));
        return wrapper;
    }

    @AuraEnabled
    public static void saveApprovalItems(Id caseId, List<NPAI_Container__c> approvalItems) {
        try {
            Id approvalItemRecordTypeId =
                    Schema.SObjectType.NPAI_Container__c.getRecordTypeInfosByDeveloperName().get(NPAI_CONTAINER_APPROVAL_ITEM_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();
            List<NPAI_Container__c> previousApprovalItem = [
                    SELECT Id, Approval_Version__c
                    FROM NPAI_Container__c
                    WHERE NPAI_Case__c = :caseId
                    ORDER BY Approval_Version__c DESC LIMIT 1
            ];
            NPC_Cases__c relatedCase = [SELECT Id, Assessment_Conclusion__c FROM NPC_Cases__c WHERE Id =:caseId];
            for(NPAI_Container__c container : approvalItems) {
                container.RecordTypeId = approvalItemRecordTypeId;
                container.NPAI_Case__c = caseId;
                container.Assessment_Conclusion__c = extractDescription(relatedCase.Assessment_Conclusion__c);
                if(previousApprovalItem.isEmpty()) {
                    container.Approval_Version__c = 1;
                } else {
                    container.Approval_Version__c = Integer.valueOf(previousApprovalItem[0].Approval_Version__c) + 1;
                }
            }
            insert approvalItems;
            List<Approval.ProcessSubmitRequest> approvalItemsProcessSubmitRequests = new List<Approval.ProcessSubmitRequest>();
            for(NPAI_Container__c container : approvalItems) {
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                request.setObjectId(container.Id);
                request.setProcessDefinitionNameOrId(msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME);
                request.setNextApproverIds(new List<Id>{container.Approver__c});
                request.setComments(container.Comments__c);
                approvalItemsProcessSubmitRequests.add(request);
            }
            Approval.process(approvalItemsProcessSubmitRequests);

            NPC_Cases__c caseToProcess = new NPC_Cases__c(
                    Id = caseId,
                    Status__c = msNpaiContainerHandler.APPROVAL_ITEM_STATUS_IN_APPROVAL,
                    In_Approval_Process__c = true
            );
            update caseToProcess;
            Approval.lock(caseId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String extractDescription(String description) {
        return String.isNotEmpty(description) ? description : EMPTY_DESCRIPTION;
    }

    private static String turnImagesIntoLinks(String stringWithImages) {
        String stringWithLinks = stringWithImages
                .replaceAll('img src','a href')
                .replaceAll(' alt="image.png"></img>','>'+System.Label.msNPAIImageLink+'</a>')
                .replaceAll('<p><br></p>','');
        return stringWithLinks;
    }

    public class NPAICaseApprovalDescriptionWrapper {
        @AuraEnabled
        public String creditRiskAssessmentApprovalRequest { get; set; }
        @AuraEnabled
        public String marketRiskAssessmentApprovalRequest { get; set; }
        @AuraEnabled
        public String operationalApprovalRequest { get; set; }
        @AuraEnabled
        public String caseName { get; set; }
        @AuraEnabled
        public Boolean greenLightForMandateApproval { get; set; }
        @AuraEnabled
        public String market_risk_assessment_conclusion { get; set; }
        @AuraEnabled
        public String market_risk_assessment_conclusion_with_links { get; set; }
    }
}
@IsTest
private class msApprovalLinkControllerTest {

    @TestSetup
    static void setup() {
        NPC_Cases__c caseForApproval = new NPC_Cases__c(
                Name = 'Test Case Name',
                Status__c = 'RAFA Summary',
                FO_Requestor__c = UserInfo.getUserId()
        );
        insert caseForApproval;

        NPAI_Container__c container = new NPAI_Container__c();
        container.RecordTypeId = msNpaiContainerHandler.APPROVAL_ITEM_RECORD_TYPE;
        container.Approver__c = UserInfo.getUserId();
        container.Market_Risk_Assessment__c = true;
        container.NPAI_Case__c = caseForApproval.Id;
        insert container;

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(container.Id);
        request.setProcessDefinitionNameOrId(msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME);
        request.setNextApproverIds(new List<Id>{container.Approver__c});
        Approval.process(request);
    }

    @IsTest
    static void shouldGetApprovalLink() {
        NPAI_Container__c approvalItem = [SELECT Id FROM NPAI_Container__c LIMIT 1];

        Test.startTest();

        msApprovalLinkController approvalLinkController = new msApprovalLinkController();
        approvalLinkController.recordId = approvalItem.Id;
        String resultUrl = approvalLinkController.approvalLinkUrl;

        Test.stopTest();

        System.assert(String.isNotEmpty(resultUrl));
    }
}
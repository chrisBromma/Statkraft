@IsTest
private class msNPAICaseApprovalHistoryControllerTest {

    @TestSetup
    static void setup() {
        NPC_Cases__c caseForApproval = new NPC_Cases__c(
                Name = 'Test Case Name',
                Status__c = 'RAFA Summary',
                FO_Requestor__c = UserInfo.getUserId()
        );
        insert caseForApproval;
        List<NPAI_Container__c> containersToInsert = new List<NPAI_Container__c>();
        for(Integer i=0; i<10; i++) {
            NPAI_Container__c container = new NPAI_Container__c();
            container.Approver__c = UserInfo.getUserId();
            container.Market_Risk_Assessment__c = true;
            container.NPAI_Case__c = caseForApproval.Id;
            container.Approval_Version__c = 1;
            containersToInsert.add(container);
        }
        insert containersToInsert;

        List<Approval.ProcessSubmitRequest> approvalItemsProcessSubmitRequests = new List<Approval.ProcessSubmitRequest>();
        for(NPAI_Container__c container : containersToInsert) {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(container.Id);
            request.setProcessDefinitionNameOrId(msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME);
            request.setNextApproverIds(new List<Id>{container.Approver__c});
            request.setComments(container.Comments__c);
            approvalItemsProcessSubmitRequests.add(request);
        }
        Approval.process(approvalItemsProcessSubmitRequests);

        List<ProcessInstance> processInstances = [
                SELECT Id, (SELECT Id, isDeleted FROM Workitems)
                FROM ProcessInstance
        ];

        Approval.ProcessWorkitemRequest rejectRequest = new Approval.ProcessWorkitemRequest();
        rejectRequest.setWorkitemId(processInstances[0].Workitems[0].Id);
        rejectRequest.setAction('Reject');
        Approval.process(rejectRequest);

        List<NPAI_Container__c> containersToInsertForSecondApproval = new List<NPAI_Container__c>();
        for(Integer i=0; i<10; i++) {
            NPAI_Container__c container = new NPAI_Container__c();
            container.Approver__c = UserInfo.getUserId();
            container.Market_Risk_Assessment__c = true;
            container.NPAI_Case__c = caseForApproval.Id;
            container.Approval_Version__c = 2;
            containersToInsertForSecondApproval.add(container);
        }
        insert containersToInsertForSecondApproval;

        List<Approval.ProcessSubmitRequest> approvalItemsProcessSubmitRequestsForSecondApproval = new List<Approval.ProcessSubmitRequest>();
        for(NPAI_Container__c container : containersToInsertForSecondApproval) {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(container.Id);
            request.setProcessDefinitionNameOrId(msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME);
            request.setNextApproverIds(new List<Id>{container.Approver__c});
            request.setComments(container.Comments__c);
            approvalItemsProcessSubmitRequestsForSecondApproval.add(request);
        }
        Approval.process(approvalItemsProcessSubmitRequestsForSecondApproval);

        caseForApproval.Status__c = msNpaiContainerHandler.APPROVAL_ITEM_STATUS_IN_APPROVAL;
        caseForApproval.In_Approval_Process__c = true;
        update caseForApproval;

        List<ProcessInstance> processInstancesForSecondApproval = [
                SELECT Id, (SELECT Id, isDeleted FROM Workitems)
                FROM ProcessInstance
                WHERE TargetObjectId IN :containersToInsertForSecondApproval
        ];

        List<Approval.ProcessWorkitemRequest> approvalsToProcessForSecondApproval = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstance approval : processInstancesForSecondApproval) {
            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
            request.setWorkitemId(approval.Workitems[0].Id);
            request.setNextApproverIds(new List<String>{UserInfo.getUserId()});
            request.setAction('Approve');
            approvalsToProcessForSecondApproval.add(request);
        }
        Approval.process(approvalsToProcessForSecondApproval);
    }

    @IsTest
    static void shouldGetApprovalHistoryWrappers() {
        NPC_Cases__c caseFromApproval = [SELECT Id FROM NPC_Cases__c LIMIT 1];

        Test.startTest();

        List<msNPAICaseApprovalHistoryController.msNPAICaseApprovalHistoryWrapper> resultWrappers =
                msNPAICaseApprovalHistoryController.getApprovalItemsForNpaiCase(caseFromApproval.Id);

        Test.stopTest();

        System.assertEquals(2, resultWrappers.size());
        System.assertEquals(msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED, resultWrappers[0].status);
        System.assertEquals(msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED, resultWrappers[1].status);
    }
}
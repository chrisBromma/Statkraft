@IsTest
public class msNpaiContainerApprovalItemHandlerTest {

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
			container.RecordTypeId = msNpaiContainerHandler.APPROVAL_ITEM_RECORD_TYPE;
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

        caseForApproval.Status__c = msNpaiContainerHandler.APPROVAL_ITEM_STATUS_IN_APPROVAL;
        caseForApproval.In_Approval_Process__c = true;
        update caseForApproval;
    }

    @IsTest
    static void shouldUpdateCaseStatusOnContainerApprovals() {
        //when
        NPC_Cases__c caseForApproval = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        List<ProcessInstance> processInstances = [ 
                SELECT Id, (SELECT Id, isDeleted FROM Workitems)
                FROM ProcessInstance
                WHERE TargetObjectId IN (SELECT Id FROM NPAI_Container__c WHERE NPAI_Case__c = :caseForApproval.Id)
                AND ProcessDefinition.DeveloperName = :msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME
                ORDER BY CreatedDate
        ];

        System.assertEquals(10, processInstances.size());

        Test.startTest();

        List<Approval.ProcessWorkitemRequest> approvalsToProcess = new List<Approval.ProcessWorkitemRequest>();
        for(Integer i=0; i < processInstances.size() -1; i++) {
            Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
            request.setWorkitemId(processInstances[i].Workitems[0].Id);
            request.setAction('Approve');
            approvalsToProcess.add(request);
        }
        Approval.process(approvalsToProcess);

        Approval.ProcessWorkitemRequest finalApprovalStep = new Approval.ProcessWorkitemRequest();
        finalApprovalStep.setWorkitemId(processInstances[processInstances.size()-1].Workitems[0].Id);
        finalApprovalStep.setAction('Approve');
        Approval.process(finalApprovalStep);

        Test.stopTest();

        System.assertEquals('Implementation', [SELECT Id, Status__c FROM NPC_Cases__c WHERE Id = :caseForApproval.Id].Status__c);
        System.assertEquals(10, [SELECT Id FROM NPAI_Container__c WHERE Approval_Status__c = :msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED].size());
        System.assertEquals(10, [SELECT Id FROM ProcessInstanceStep WHERE StepStatus = :msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED ORDER BY CreatedDate DESC].size());
    }

    @IsTest
    static void shouldRejectContainers() {
        //when
        NPC_Cases__c caseForApproval = [SELECT Id FROM NPC_Cases__c LIMIT 1];
        List<ProcessInstance> processInstances = [
                SELECT Id, SubmittedById,
                (SELECT Id, StepStatus, isDeleted, TargetObjectId, Comments FROM StepsAndWorkitems ORDER BY CreatedDate DESC LIMIT 1),
                (SELECT Id, isDeleted FROM Workitems),
                (SELECT Id FROM Nodes)
                FROM ProcessInstance
                WHERE TargetObjectId IN (SELECT Id FROM NPAI_Container__c WHERE NPAI_Case__c = :caseForApproval.Id)
                AND ProcessDefinition.DeveloperName = :msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME
                ORDER BY CreatedDate
        ];

        System.assertEquals(10, processInstances.size());

        Test.startTest();

        Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
        approveRequest.setWorkitemId(processInstances[0].Workitems[0].Id);
        approveRequest.setAction('Approve');
        Approval.process(approveRequest);

        Approval.ProcessWorkitemRequest rejectRequest = new Approval.ProcessWorkitemRequest();
        rejectRequest.setWorkitemId(processInstances[1].Workitems[0].Id);
        rejectRequest.setAction('Reject');
        Approval.process(rejectRequest);

        Test.stopTest();

        System.assertEquals('RAFA Summary', [SELECT Id, Status__c FROM NPC_Cases__c WHERE Id = :caseForApproval.Id].Status__c);
        System.assertEquals(9, [SELECT Id FROM NPAI_Container__c WHERE Approval_Status__c = :msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED AND History_Item__c = true].size());
        System.assertEquals(1, [SELECT Id FROM NPAI_Container__c WHERE Approval_Status__c = :msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED AND History_Item__c = true].size());
        System.assertEquals(9, [SELECT Id FROM ProcessInstanceStep WHERE StepStatus = :msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED ORDER BY CreatedDate DESC].size());
        System.assertEquals(1, [SELECT Id FROM ProcessInstanceStep WHERE StepStatus = :msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED ORDER BY CreatedDate DESC].size());
    }
}
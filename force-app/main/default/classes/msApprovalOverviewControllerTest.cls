@IsTest
private class msApprovalOverviewControllerTest {

    private static final String CREDIT_RISK_ASSESSMENT_DESCRIPTION = 'Test credit risk assessment description';
    private static final String MARKET_RISK_ASSESSMENT_DESCRIPTION = 'Test market risk assessment description';

    @TestSetup
    static void setup() {
        NPC_Cases__c caseForApproval = new NPC_Cases__c(
                Name = 'Test Case Name',
                Status__c = 'RAFA Summary',
                FO_Requestor__c = UserInfo.getUserId()
        );
        insert caseForApproval;

        NPC_Assessment__c creditRiskAssessment = new NPC_Assessment__c(
                Name = 'Credit Risk Assessment',
                Approval_Required__c = CREDIT_RISK_ASSESSMENT_DESCRIPTION,
                NPC_Case__c = caseForApproval.Id,
                Statkraft_Department__c = 'MFRC',
                FARA__c = 'Credit Risk Assessment'
        );
        insert creditRiskAssessment;

        NPC_Assessment__c marketRiskAssessment = new NPC_Assessment__c(
                Name = 'Market Risk Assessment',
                Approval_Required__c = MARKET_RISK_ASSESSMENT_DESCRIPTION,
                NPC_Case__c = caseForApproval.Id,
                Statkraft_Department__c = 'MFRM',
                FARA__c = 'Market Risk Assessment'
        );
        insert marketRiskAssessment;

        NPAI_Container__c approvalContainer = new NPAI_Container__c(
                NPAI_Case__c = caseForApproval.Id
        );
        insert approvalContainer;
    }

    @IsTest
    static void shouldGetApprovalOverview() {
        NPAI_Container__c approvalContainer = [SELECT Id FROM NPAI_Container__c LIMIT 1];

        Test.startTest();

        msApprovalOverviewController controller = new msApprovalOverviewController();
        controller.recordId = approvalContainer.Id;
        msNPAICaseApprovalController.NPAICaseApprovalDescriptionWrapper descriptionWrapper = controller.descriptionWrapper;

        Test.stopTest();
        System.assertEquals(CREDIT_RISK_ASSESSMENT_DESCRIPTION, descriptionWrapper.creditRiskAssessmentApprovalRequest);
        System.assertEquals(MARKET_RISK_ASSESSMENT_DESCRIPTION, descriptionWrapper.marketRiskAssessmentApprovalRequest);
        System.assertEquals(msNPAICaseApprovalController.EMPTY_DESCRIPTION, descriptionWrapper.operationalApprovalRequest);
    }
}
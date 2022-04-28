@IsTest
private class msApprovalRiskScopeControllerTest {

    @IsTest
    static void shouldReturnApprovalScopeForCreditRisk() {
        NPAI_Container__c container = new NPAI_Container__c(
                Credit_Risk_Assessment__c = true
        );
        insert container;

        Test.startTest();

        msApprovalRiskScopeController controller = new msApprovalRiskScopeController();
        controller.containerId = container.Id;
        String approvalScope = controller.riskScope;

        Test.stopTest();

        System.assertEquals(NPAI_Container__c.Credit_Risk_Assessment__c.getDescribe().getLabel(), approvalScope);
    }

    @IsTest
    static void shouldReturnApprovalScopeForMarketRisk() {
        NPAI_Container__c container = new NPAI_Container__c(
                Market_Risk_Assessment__c = true
        );
        insert container;

        Test.startTest();

        msApprovalRiskScopeController controller = new msApprovalRiskScopeController();
        controller.containerId = container.Id;
        String approvalScope = controller.riskScope;

        Test.stopTest();

        System.assertEquals(NPAI_Container__c.Market_Risk_Assessment__c.getDescribe().getLabel(), approvalScope);
    }

    @IsTest
    static void shouldReturnApprovalScopeForOperationalRisk() {
        NPAI_Container__c container = new NPAI_Container__c(
                Operational_Approval_Request__c = true
        );
        insert container;

        Test.startTest();

        msApprovalRiskScopeController controller = new msApprovalRiskScopeController();
        controller.containerId = container.Id;
        String approvalScope = controller.riskScope;

        Test.stopTest();

        System.assertEquals(NPAI_Container__c.Operational_Approval_Request__c.getDescribe().getLabel(), approvalScope);
    }
}
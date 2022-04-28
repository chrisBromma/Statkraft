@IsTest
public class msNPAICaseApprovalControllerTest {

    private static final String TEST_OPERATIONAL_RISK_DESCRIPTION = 'Test operational risk';
    private static final String CREDIT_RISK_ASSESSMENT_DESCRIPTION = 'Test credit risk assessment description';
    private static final String MARKET_RISK_ASSESSMENT_DESCRIPTION = 'Test market risk assessment description';
    private static final String STATKRAFT_DEPARTMENT = NPC_Assessment__c.Statkraft_Department__c.getDescribe().getPicklistValues()[0].getValue();
    private static final String NPAI_EMAIL_TEMPLATE_DEVELOPERNAME = 'NPAI_Case_Approval_Assignment';

    @TestSetup
    static void setup() {
        User userWithAccessToCaseOperationalRiskField = [SELECT Id FROM User WHERE Profile.Name = 'NPC AM Platform' AND IsActive = TRUE LIMIT 1];
        System.runAs(userWithAccessToCaseOperationalRiskField) {
            NPC_Cases__c caseForApproval = new NPC_Cases__c(
                    Name = 'Test Case Name',
                    Status__c = 'RAFA Summary',
                    FO_Requestor__c = UserInfo.getUserId(),
                    OperationalRisk__c = TEST_OPERATIONAL_RISK_DESCRIPTION
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

            EmailTemplate npaiEmailTemplate = new EmailTemplate();
            npaiEmailTemplate.isActive = true;
            npaiEmailTemplate.Name = 'name';
            npaiEmailTemplate.DeveloperName = NPAI_EMAIL_TEMPLATE_DEVELOPERNAME;
            npaiEmailTemplate.TemplateType = 'text';
            npaiEmailTemplate.FolderId = UserInfo.getUserId();
            npaiEmailTemplate.Subject = 'Your Subject Here';

            insert npaiEmailTemplate;
        }
    }

    @IsTest
    static void shouldReturnAssessmentDescriptions() {
        NPC_Cases__c caseForApproval = [SELECT Id FROM NPC_Cases__c LIMIT 1];

        Test.startTest();

        msNPAICaseApprovalController.NPAICaseApprovalDescriptionWrapper descriptionWrapper = msNPAICaseApprovalController.getApprovalDescriptions(caseForApproval.Id);

        Test.stopTest();
        System.assertEquals(CREDIT_RISK_ASSESSMENT_DESCRIPTION, descriptionWrapper.creditRiskAssessmentApprovalRequest);
        System.assertEquals(MARKET_RISK_ASSESSMENT_DESCRIPTION, descriptionWrapper.marketRiskAssessmentApprovalRequest);
        System.assertEquals(TEST_OPERATIONAL_RISK_DESCRIPTION, descriptionWrapper.operationalApprovalRequest);
    }

    @IsTest
    static void shouldSaveRecordsAndStartApprovalProcess() {
        NPC_Cases__c caseForApproval = [SELECT Id FROM NPC_Cases__c LIMIT 1];

        Test.startTest();

        List<NPAI_Container__c> approvalItems = new List<NPAI_Container__c>();
        for(Integer i=0; i<3; i++) {
            NPAI_Container__c container = new NPAI_Container__c();
            container.Approver__c = UserInfo.getUserId();
            container.Credit_Risk_Assessment__c = true;
            container.Market_Risk_Assessment__c = true;
            approvalItems.add(container);
        }
        msNPAICaseApprovalController.saveApprovalItems(caseForApproval.Id, approvalItems);

        Test.stopTest();

        System.assertEquals(msNpaiContainerHandler.APPROVAL_ITEM_STATUS_IN_APPROVAL, [SELECT Id, Status__c FROM NPC_Cases__c LIMIT 1].Status__c);
        System.assertEquals(3, [SELECT count() FROM NPAI_Container__c]);
        System.assertEquals(3, [SELECT count() FROM ProcessInstanceStep WHERE StepStatus = 'Started']);
    }
}
public without sharing class msApprovalRiskScopeController {

    public Id containerId { get; set; }
    public String riskScope {
        get {
            String scope = '';
            try {
                NPAI_Container__c container = [
                        SELECT Market_Risk_Assessment__c, Credit_Risk_Assessment__c, Operational_Approval_Request__c
                        FROM NPAI_Container__c
                        WHERE Id = :containerId
                ];
                if(container.Credit_Risk_Assessment__c) {
                    scope = NPAI_Container__c.Credit_Risk_Assessment__c.getDescribe().getLabel();
                } else if(container.Market_Risk_Assessment__c) {
                    scope = NPAI_Container__c.Market_Risk_Assessment__c.getDescribe().getLabel();
                } else if(container.Operational_Approval_Request__c) {
                    scope = NPAI_Container__c.Operational_Approval_Request__c.getDescribe().getLabel();
                }
            } catch (Exception e) {
                System.debug('e.getMessage() --> ' + e.getMessage());
            }
            return scope;
        }
        private set;
    }
}
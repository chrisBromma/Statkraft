public class msApprovalOverviewController {

    public Id recordId { get; set; }
    public msNPAICaseApprovalController.NPAICaseApprovalDescriptionWrapper descriptionWrapper {
        get {
            descriptionWrapper = new msNPAICaseApprovalController.NPAICaseApprovalDescriptionWrapper();
            List<NPAI_Container__c> containers = [SELECT NPAI_Case__c FROM NPAI_Container__c WHERE Id = :recordId];
            if(!containers.isEmpty()) {
                descriptionWrapper = msNPAICaseApprovalController.getApprovalDescriptions(containers[0].NPAI_Case__c);
            }
            return descriptionWrapper;
        }
        set;
    }
}
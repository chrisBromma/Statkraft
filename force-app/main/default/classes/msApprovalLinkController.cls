public class msApprovalLinkController {

    public Id recordId { get; set; }
    public String approvalLinkUrl {
        get {
            List<ProcessInstanceWorkitem> approvalRequests = [
                    SELECT Id
                    FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :recordId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];

            if(approvalRequests.isEmpty()) {
                return '';
            }
            return Url.getSalesforceBaseUrl().toExternalForm() + '/' + approvalRequests[0].Id;
    }
        private set;
    }
}
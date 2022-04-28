public without sharing class msNPAICaseApprovalHistoryController {

    private static String APPROVAL_STATUS_REOPENED = 'Reopened';

    @AuraEnabled
    public static List<msNPAICaseApprovalHistoryWrapper> getApprovalItemsForNpaiCase(Id recordId) {
        Map<Integer, msNPAICaseApprovalHistoryWrapper> wrappers = new Map<Integer, msNPAICaseApprovalHistoryWrapper>();
        Map<Id, NPAI_Container__c> approvalItems = new Map<Id, NPAI_Container__c>([
                SELECT Id, Comments__c, Owner.Name, OwnerId, Approver__c, Approver__r.Name, Approval_Version__c, Market_Risk_Assessment__c, Operational_Approval_Request__c, Credit_Risk_Assessment__c
                FROM NPAI_Container__c
                WHERE NPAI_Case__c = :recordId
        ]);
        for(ProcessInstance approval : [
                SELECT Id, TargetObjectId, CreatedDate,
                (SELECT Id, ActorId, Actor.Name, Comments, StepStatus, CreatedDate FROM Steps ORDER BY CreatedDate DESC LIMIT 1)
                FROM ProcessInstance
                WHERE TargetObjectId IN :approvalItems.keySet()
                AND ProcessDefinition.DeveloperName = :msNpaiContainerHandler.APPROVAL_ITEM_APPROVAL_PROCESS_DEVELOPER_NAME
        ]) {
            NPAI_Container__c currentApprovalItem = approvalItems.get(approval.TargetObjectId);
            Integer currentApprovalVersion = Integer.valueOf(currentApprovalItem.Approval_Version__c);
            msNPAICaseApprovalItemWrapper approvalItemWrapper = new msNPAICaseApprovalItemWrapper(currentApprovalItem, approval.Steps[0]);
            if(!wrappers.containsKey(currentApprovalVersion)) {
                wrappers.put(currentApprovalVersion, new msNPAICaseApprovalHistoryWrapper(currentApprovalItem, approval));
            }
            wrappers.get(currentApprovalVersion).approvalItems.add(approvalItemWrapper);
        }

        List<msNPAICaseApprovalHistoryWrapper> resultWrappers = wrappers.values();
        resultWrappers.sort();
        for(msNPAICaseApprovalHistoryWrapper wrapper : resultWrappers) {
            wrapper.calculateStatus(resultWrappers.size());
        }
        return resultWrappers;
    }

    public class msNPAICaseApprovalHistoryWrapper implements Comparable {
        @AuraEnabled public Integer approvalVersion { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String displayedDate { get; set; }
        @AuraEnabled public Datetime submittedDate { get; set; }
        @AuraEnabled public List<msNPAICaseApprovalItemWrapper> approvalItems { get; set; }

        public msNPAICaseApprovalHistoryWrapper(NPAI_Container__c approvalItem, ProcessInstance approval) {
            this.approvalVersion = Integer.valueOf(approvalItem.Approval_Version__c);
            this.submittedDate = approval.CreatedDate;
            this.displayedDate = msNPAICaseApprovalHistoryController.getDateTimeInCurrentLocale(approval.CreatedDate);
            this.approvalItems = new List<msNPAICaseApprovalItemWrapper>();
        }

        public void calculateStatus(Integer numberOfApprovals) {
            this.status = msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED;
            for(msNPAICaseApprovalItemWrapper itemWrapper : approvalItems) {
                if(itemWrapper.itemStatus == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED) {
                    this.status = msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED;
                    break;
                }
                if(itemWrapper.itemStatus != msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED
                        && itemWrapper.itemStatus != msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED) {
                    this.status = msNpaiContainerHandler.APPROVAL_ITEM_STATUS_IN_APPROVAL;
                }
            }
            if(this.status == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED && this.approvalVersion < numberOfApprovals) {
                this.status = APPROVAL_STATUS_REOPENED;
            }
        }

        public Integer compareTo(Object compareTo) {
            msNPAICaseApprovalHistoryWrapper compareToWrapper = (msNPAICaseApprovalHistoryWrapper) compareTo;
            if (submittedDate == compareToWrapper.submittedDate) return 0;
            if (submittedDate < compareToWrapper.submittedDate) return 1;
            return -1;
        }
    }

    public class msNPAICaseApprovalItemWrapper {
        @AuraEnabled public String submitterName { get; set; }
        @AuraEnabled public String submitterUrl { get; set; }
        @AuraEnabled public String assignedToName { get; set; }
        @AuraEnabled public String actualApproverName { get; set; }
        @AuraEnabled public String assignedToUrl { get; set; }
        @AuraEnabled public String actualApproverUrl { get; set; }
        @AuraEnabled public String approvalScope { get; set; }
        @AuraEnabled public String itemStatus { get; set; }
        @AuraEnabled public String lastActionDate { get; set; }
        @AuraEnabled public String comment { get; set; }
        @AuraEnabled public String approverComment { get; set; }

        public msNPAICaseApprovalItemWrapper(NPAI_Container__c approvalItem, ProcessInstanceStep approvalStep) {
            this.actualApproverName = approvalStep.Actor.Name;
            this.actualApproverUrl = '/' + approvalStep.ActorId;
            this.itemStatus = approvalStep.StepStatus;
            this.lastActionDate = msNPAICaseApprovalHistoryController.getDateTimeInCurrentLocale(approvalStep.CreatedDate);
            this.submitterName = approvalItem.Owner.Name;
            this.submitterUrl = '/' + approvalItem.OwnerId;
            this.assignedToName = approvalItem.Approver__r.Name;
            this.assignedToUrl = '/' + approvalItem.Approver__c;
            this.comment = approvalItem.Comments__c;
            if(this.itemStatus == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_APPROVED || this.itemStatus == msNpaiContainerHandler.APPROVAL_ITEM_STATUS_REJECTED) {
                this.approverComment = approvalStep.Comments;
            }
            this.approvalScope = retrieveApprovalScope(approvalItem);
        }

        private String retrieveApprovalScope(NPAI_Container__c approvalItem) {
            if(approvalItem.Credit_Risk_Assessment__c) {
                return NPAI_Container__c.Credit_Risk_Assessment__c.getDescribe().getLabel();
            }
            if(approvalItem.Market_Risk_Assessment__c) {
                return NPAI_Container__c.Market_Risk_Assessment__c.getDescribe().getLabel();
            }
            if(approvalItem.Operational_Approval_Request__c) {
                return NPAI_Container__c.Operational_Approval_Request__c.getDescribe().getLabel();
            }
            return '';
        }
    }

    private static String getDateTimeInCurrentLocale(Datetime dateValue) {
        return dateValue.format('dd.MM.yyyy HH:mm', UserInfo.getTimeZone().toString());
    }
}
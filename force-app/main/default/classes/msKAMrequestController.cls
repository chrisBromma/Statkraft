public without sharing class msKAMrequestController {
    public static Boolean USER_HAS_ACCESS_TO_AMC_VIEW =
            FeatureManagement.checkPermission('KAM_AMC_View_of_KAM_Request_Dashboard');
    public static Id currentUserId = UserInfo.getUserId();

    static Map<String, String> picklistLabelsByApiValues = new Map<String, String>();
    static String delegateShorthand;

    static KAM_request_approver__mdt approver;
    static Boolean userIsApprover;
    static Delegation__c delegation;
    static Boolean userIsDelegate;

    static Map<String, List<Id>> approversByMarket = new Map<String, List<Id>>();


    public static List<KAM_Request_Dashboard_Settings__c> settings = new List<KAM_Request_Dashboard_Settings__c>();
    public static List<KAM_request__c> requestsOfLastWeek = new List<KAM_request__c>();
    public static Boolean allApprovalsSubmitted = true;
    public static List<KAM_request__c> activeKamRequests = new List<KAM_request__c>();

    public static Integer newRequestCounter = 0;

    public static void loadPicklistMap() {
        if (picklistLabelsByApiValues.isEmpty()) {
            for (PicklistEntryWrapper market : getMarketPicklistValues()) {
                picklistLabelsByApiValues.put(market.picklistValue, market.picklistLabel);
            }
        }
    }

    public static List<KAM_request__c> getRequests() {
        getSettings();
        if (activeKamRequests.isEmpty()) {
            activeKamRequests = [
                    SELECT
                            Id, Name,
                            KAM_request_sent__c,
                            KAM_allocation_conflict__c,
                            Deadline__c,
                            Request_Batch_Date__c,
                            isActive__c,
                            Key_Account__r.KAM_Approval_Step__c,
                            Key_Account__r.KAM_request_sent__c,
                            Key_Account__r.KAM_allocation_conflict__c,
                            Key_Account__r.Comments_from_AMC__c,
                            Key_Account__r.name,
                            Key_Account__r.BillingCountry,
                            Key_Account__r.BillingCountryCode,
                            Key_Account__r.Customer_Segment_industry__c,
                            Key_Account__r.Last_KAM_Submitter__r.Name,
                            Key_Account__r.KAM_proposal__c,
                            Key_Account__r.KAM_proposal_comment__c,
                            Key_Account__r.KAM_approved__c,
                            Key_Account__r.KAM_pending__c,
                            Key_Account__r.Owner.Name,
                            Key_Account__r.customer_type__c,
                            VP_MCO_approved_KAM__c, VP_MCO_comment__c, VP_MCO_locked__c, VP_MCO_delegate__c,
                            VP_MCU_approved_KAM__c, VP_MCU_comment__c, VP_MCU_locked__c, VP_MCU_delegate__c,
                            VP_MTG_approved_KAM__c, VP_MTG_comment__c, VP_MTG_locked__c, VP_MTG_delegate__c,
                            VP_MTN_approved_KAM__c, VP_MTN_comment__c, VP_MTN_locked__c, VP_MTN_delegate__c,
                            VP_MTC_approved_KAM__c, VP_MTC_comment__c, VP_MTC_locked__c, VP_MTC_delegate__c,
                            VP_MTS_approved_KAM__c, VP_MTS_comment__c, VP_MTS_locked__c, VP_MTS_delegate__c
                    FROM KAM_request__c
                    WHERE (Key_Account__r.KAM_Approval_Step__c = '' AND KAM_request_sent__c <= :settings[0].Query_Date__c AND isActive__c = TRUE)
                    ORDER BY Key_Account__r.KAM_proposal__c ASC
            ];
        }
        return activeKamRequests;
    }
    public static Boolean currentUserIsApprover() {
        if (approver == null) {
            List<KAM_request_approver__mdt> approverList = [
                    SELECT Approver_Id__c, Associated_VP__c
                    FROM KAM_request_approver__mdt
                    WHERE Approver_Id__c = :currentUserId
                    LIMIT 1
            ];
            if (!approverList.isEmpty()) {
                approver = approverList[0];
                delegateShorthand = approver.Associated_VP__c;
            }
        }
        return approver != null;
    }
    public static Boolean currentUserIsDelegate() {
        if (delegation == null) {
            List<Delegation__c> delegationList = [
                    SELECT Id, Delegate_for_Market__c
                    FROM Delegation__c
                    WHERE Delegate__c = :UserInfo.getUserId()
                    AND (Valid_From__c <= TODAY AND Valid_To__c >= TODAY)
                    LIMIT 1
            ];
            if (!delegationList.isEmpty()) {
                delegation = delegationList[0];
                delegateShorthand = delegation.Delegate_for_Market__c;
            }
        }
        return delegation != null;
    }
    public static List<RequestWrapper> convertToWrapper(List<KAM_request__c> kamRequests) {
        List<RequestWrapper> requestsToShow = new List<RequestWrapper>();
        for (KAM_request__c request : kamRequests) {
            if (userIsApprover || userIsDelegate || USER_HAS_ACCESS_TO_AMC_VIEW) {
                RequestWrapper preparedRequest = new RequestWrapper(request);
                checkIfNewRequest(request);

                if (userIsApprover || userIsDelegate) {
                    preparedRequest = prepareRequest(
                            preparedRequest,
                            request,
                            delegateShorthand
                    );
                } else if (USER_HAS_ACCESS_TO_AMC_VIEW) {
                    preparedRequest.Locked = false;
                    preparedRequest.VPComment = request.Key_Account__r.Comments_from_AMC__c;
                    preparedRequest.DelegateField = 'AMC';
                }
                if (!preparedRequest.Locked) {
                    AllApprovalsSubmitted = false;
                }
                requestsToShow.add(preparedRequest);
            }
        }
        return requestsToShow;
    }
    public static void checkIfNewRequest(KAM_request__c kamRequest) {
        if (kamRequest.Deadline__c == null) {
            newRequestCounter++;
        }
    }
    public static RequestWrapper prepareRequest(RequestWrapper preparedRequest, KAM_request__c request, String delegateShorthand) {
        preparedRequest.Approval = (Boolean) request.get('VP_' + delegateShorthand + '_approved_KAM__c');
        preparedRequest.VPComment = (String) request.get('VP_' + delegateShorthand + '_comment__c');
        preparedRequest.Locked = request.Deadline__c < Date.today() ? true : (Boolean) request.get('VP_' + delegateShorthand + '_locked__c');
        preparedRequest.Delegate = (Id) request.get('VP_' + delegateShorthand + '_delegate__c');
        preparedRequest.DelegateField = delegateShorthand;

        return preparedRequest;
    }
    public static List<KAM_request__c> convertToRequest(List<RequestWrapper> requestWrappersToUpdate, Boolean submitted) {
        userIsApprover = currentUserIsApprover();
        userIsDelegate = currentUserIsDelegate();

        List<KAM_request__c> requestsToUpdate = new List<KAM_request__c>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        List<Id> requestsToUpdateIds = new List<Id>();
        for (RequestWrapper requestWrapperToUpdate : requestWrappersToUpdate) {
            requestsToUpdateIds.add(requestWrapperToUpdate.RequestId);
        }
        Map<Id, KAM_request__c> KAMrequestsToUpdate = new Map<Id, KAM_request__c>([
                SELECT
                        Key_Account__c,
                        Deadline__c,
                        Request_Batch_Date__c
                FROM KAM_request__c
                WHERE Id IN :requestsToUpdateIds
        ]);
        List<Id> KAMrequestAccountIds = new List<Id>();
        for (KAM_request__c request : KAMrequestsToUpdate.values()) {
            KAMrequestAccountIds.add(request.Key_Account__c);
        }
        Map<Id, Account> KAMrequestAccounts = new Map<Id, Account>([
                SELECT Comments_from_AMC__c
                FROM Account
                WHERE Id = :KAMrequestAccountIds
        ]);


        for (RequestWrapper request : requestWrappersToUpdate) {
            KAM_request__c requestUpdate = KAMrequestsToUpdate.get(request.RequestId);
            if (requestUpdate.Deadline__c == null) {
                requestUpdate.Deadline__c = request.deadline;
            }
            if (requestUpdate.Request_Batch_Date__c == null) {
                requestUpdate.Request_Batch_Date__c = request.RequestBatchDate;
            }

            if (userIsApprover || userIsDelegate) {
                requestUpdate.put('VP_' + delegateShorthand + '_approved_KAM__c', request.Approval);
                requestUpdate.put('VP_' + delegateShorthand + '_comment__c', request.VPComment);
                if (submitted) {
                    requestUpdate.put('VP_' + delegateShorthand + '_locked__c', submitted);
                }
            } else if (USER_HAS_ACCESS_TO_AMC_VIEW) {
                Account accountToUpdate = KAMrequestAccounts.get(request.AccountId);
                accountToUpdate.Comments_from_AMC__c = request.VPComment;
                accountsToUpdate.put(request.AccountId, accountToUpdate);
            }
            requestsToUpdate.add(requestUpdate);
        }
        update accountsToUpdate.values();
        return requestsToUpdate;
    }
    @AuraEnabled
    public static List<RequestWrapper> getAllocationRequests() {
        List<KAM_request__c> allocationRequests = new List<KAM_request__c>();
        for (KAM_request__c request : getRequests()) {
            if (request.key_account__r.kam_pending__c == true
                    && request.Key_Account__r.KAM_approved__c == NULL
                    && request.Key_Account__r.KAM_allocation_conflict__c == false) {
                allocationRequests.add(request);
            }
        }
        List<RequestWrapper> wrappedAllocationRequests = convertToWrapper(allocationRequests);
        wrappedAllocationRequests.sort();
        return wrappedAllocationRequests;
    }
    @AuraEnabled
    public static List<RequestWrapper> getChangeRequests() {
        List<KAM_request__c> changeRequests = new List<KAM_request__c>();
        for (KAM_request__c request : getRequests()) {
            if (request.key_account__r.kam_pending__c == true
                    && request.Key_Account__r.KAM_approved__c != NULL
                    && request.Key_Account__r.KAM_allocation_conflict__c == false) {
                changeRequests.add(request);
            }
        }
        List<RequestWrapper> wrappedChangeRequests = convertToWrapper(changeRequests);
        wrappedChangeRequests.sort();
        return wrappedChangeRequests;
    }
/* NOT YET IMPLEMENTED: The users don't have their departments in Salesforce yet
@AuraEnabled
public static List<RequestWrapper> getChangeRequestsSameTeam(){
    getApprovers();

    requestsOfLastWeek = getRequests();
    List<KAM_request__c> changeRequests = new List<KAM_request__c>();
    for (KAM_request__c request : requestsOfLastWeek) {
        if (request.key_account__r.kam_pending__c == true
            && request.Key_Account__r.KAM_approved__c != NULL
            && Key_Account__r.KAM_allocation_conflict__c == false
            && request.Key_Account__r.ownerId.department == request.Key_Account__r.KAM_Proposal__r.department) {
            changeRequests.add(request);
        }
    }
    List<RequestWrapper> wrappedChangeRequests = convertToWrapper(changeRequests);
    return wrappedChangeRequests;
}
*/
    @AuraEnabled
    public static List<RequestWrapper> getInConflictRequests() {
        List<KAM_request__c> inConflictRequests = new List<KAM_request__c>();
        for (KAM_request__c request : getRequests()) {
            if (request.key_account__r.kam_pending__c == true
                    && request.key_account__r.KAM_allocation_conflict__c == true
                    ) {
                inConflictRequests.add(request);
            }
        }
        List<RequestWrapper> wrappedInConflictRequests = convertToWrapper(inConflictRequests);
        wrappedInConflictRequests.sort();
        return wrappedInConflictRequests;
    }
    @AuraEnabled
    public static Map<String, List<Object>> getAllRequests() {
        userIsApprover = currentUserIsApprover();
        userIsDelegate = currentUserIsDelegate();

        Map<String, List<Object>> allRequests = new Map<String, List<Object>>();
        allRequests.put('AllocationRequests', getAllocationRequests());
        allRequests.put('ChangeRequests', getChangeRequests());
        allRequests.put('InConflictRequests', getInConflictRequests());

        List<Object> vpList = new List<Object>();
        RequestWrapper vp = new RequestWrapper();
        vp.numberOfNewRequests = newRequestCounter;
        vp.selectedDate = settings[0].Query_Date__c;
        vp.selectedDateFormatted = settings[0].Query_Date__c.format();
        vp.deadline = settings[0].Deadline__c;
        vp.deadlineFormatted = settings[0].Deadline__c.format();
        vp.Locked = settings[0].Deadline__c < Date.today();
        vp.AllApprovalsSubmitted = AllApprovalsSubmitted;

        for (List<Object> requestWrapperObjects : allRequests.values()) {
            List<RequestWrapper> requestWrappers = (List<RequestWrapper>)requestWrapperObjects;
            if (!requestWrappers.isEmpty()) {
                vp.Delegate = requestWrappers[0].Delegate;
                vp.RequestId = requestWrappers[0].RequestId;
                if (approver == null && userIsDelegate) {
                    vp.DelegateUser = true;
                }
                break;
            }
        }

        vp.AMCUser = USER_HAS_ACCESS_TO_AMC_VIEW;
        vp.DelegateField = delegateShorthand;
        vp.DelegateFieldForEmail = picklistLabelsByApiValues.get(delegateShorthand);
        vpList.add(vp);
        allRequests.put('VPDefinition', vpList);

        allRequests.put('MarketPicklistValues', getMarketPicklistValues());

        return allRequests;
    }
    public static Messaging.SingleEmailMessage prepareDelegationEmail(String delegate, String vpForEmail) {
        getSettings();
        EmailTemplate lstEmailTemplate = [SELECT Id, Body, Subject FROM EmailTemplate WHERE DeveloperName = 'KAM_Request_Delegation_Notification'];
        String body = lstEmailTemplate.Body;
        body = body.replace('{!VPname}', vpForEmail);
        body = body.replace('{!KAMDashboardLink}', 'https://' + System.URL.getSalesforceBaseURL().getHost() + '/lightning/n/KAM_Request_Dashboard');
        body = body.replace('{!QueryDate}', settings[0].Query_Date__c.format());
        body = body.replace('{!Deadline}', settings[0].Deadline__c.format());
        String subject = lstEmailTemplate.Subject;


        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setPlainTextBody(body);
        mail.setSubject(subject);
        mail.setSaveAsActivity(false);
        mail.setTargetObjectId(delegate);

        return mail;
    }
    @AuraEnabled
    public static void saveData(String requests, Boolean submitted) {
        //Convert the RequestWrappers to KAM_Request__c records
        List<KAM_request__c> requestsToUpdate = convertToRequest((List<RequestWrapper>) JSON.deserialize(requests, List<RequestWrapper>.class), submitted);
        //update the corresponding records
        update requestsToUpdate;
        if (submitted) {
            List<User> AMCusers = [SELECT Id FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'KAM AMC')];
            List<Id> AMCuserIds = new List<Id>();
            for (User AMCuser : AMCusers) {
                AMCuserIds.add(AMCuser.Id);
            }
            EmailTemplate lstEmailTemplate = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = 'KAM_Request_Submit_Notification'];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(lstEmailTemplate.Id);
            mail.setSaveAsActivity(false);
            mail.setTargetObjectId(UserInfo.getUserId());
            mail.setToAddresses(AMCuserIds);
            mail.setTreatTargetObjectAsRecipient(false);

            Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    mail
            });
        }

    }
    @AuraEnabled
    public static void saveQueryDate(Date newQueryDate) {
        KAM_Request_Dashboard_Settings__c orgDefault = KAM_Request_Dashboard_Settings__c.getOrgDefaults();
        orgDefault.Query_Date__c = newQueryDate;
        update orgDefault;
    }
    @AuraEnabled
    public static void sendEmailReminder(Date deadline) {
        getSettings();
        settings[0].Deadline__c = deadline;
        update settings[0];
        msKAMrequestReminder.msKAMrequestReminder(deadline);
        Map<String, List<Object>> requestsToUpdate = getAllRequests();
        List<RequestWrapper> allRequests = new List<RequestWrapper>();
        allRequests.addAll((List<RequestWrapper>)requestsToUpdate.get('AllocationRequests'));
        allRequests.addAll((List<RequestWrapper>)requestsToUpdate.get('ChangeRequests'));
        allRequests.addAll((List<RequestWrapper>)requestsToUpdate.get('InConflictRequests'));
        for (RequestWrapper request : allRequests) {
            request.deadline = deadline;
            request.RequestBatchDate = Date.today();
        }
        String requestString = JSON.serialize(allRequests);
        Boolean submitted = false;
        saveData(requestString, submitted);
    }
    public static void getSettings() {
        if (settings.isEmpty()) {
            settings = [
                    SELECT Id, Deadline__c, Query_Date__c, Countries_with_Flags__c
                    FROM KAM_Request_Dashboard_Settings__c
                    WHERE VP_Type__c = 'DAT'
            ];
        }
    }
    @AuraEnabled
    public static List<PicklistEntryWrapper> getMarketPicklistValues() {
        List<PicklistEntryWrapper> marketPicklistEntries = new List<PicklistEntryWrapper>();
        for (PicklistEntry picklistEntry : Delegation__c.Delegate_for_Market__c.getDescribe().getPicklistValues()) {
            marketPicklistEntries.add(new PicklistEntryWrapper(picklistEntry));
        }
        return marketPicklistEntries;
    }
    @AuraEnabled
    public static List<DelegationWrapper> getCurrentDelegations(String delegateShorthand) {
        loadPicklistMap();
        List<DelegationWrapper> currentDelegationsWrapped = new List<DelegationWrapper>();
        String queryString = 'SELECT Id, Delegate__c, Delegate__r.Name, Delegate_for_Market__c, Valid_From__c, Valid_To__c ' +
                'FROM Delegation__c WHERE (Valid_From__c <= TODAY AND Valid_To__c >= TODAY)';
        if (delegateShorthand != null) {
            queryString += ' AND Delegate_for_Market__c = :delegateShorthand';
        }
        List<Delegation__c> currentDelegations = Database.query(queryString);
        for (Delegation__c delegation : currentDelegations) {
            currentDelegationsWrapped.add(new DelegationWrapper(delegation));
        }
        return currentDelegationsWrapped;
    }
    @AuraEnabled
    public static void saveNewDelegations(String newDelegations) {
        List<Delegation__c> delegationsToInsert = new List<Delegation__c>();
        List<DelegationWrapper> newDelegationWrappers = ((List<DelegationWrapper>) JSON.deserialize(newDelegations, List<DelegationWrapper>.class));

        for (DelegationWrapper delegationWrapper : newDelegationWrappers) {
            delegationsToInsert.add(new Delegation__c(
                    Delegate__c = delegationWrapper.delegateId,
                    Delegate_for_Market__c = delegationWrapper.market,
                    Valid_From__c = Date.today(),
                    Valid_To__c = KAM_Request_Dashboard_Settings__c.getOrgDefaults().Deadline__c
            ));
        }
        insert delegationsToInsert;

        sendDelegationEmail(delegationsToInsert);
    }
    public static void sendDelegationEmail(List<Delegation__c> delegations){
        List<Messaging.SingleEmailMessage> emailMessagesToSend = new List<Messaging.SingleEmailMessage>();
        loadPicklistMap();
        for (Delegation__c delegation : delegations) {
            emailMessagesToSend.add(
                    prepareDelegationEmail(
                            delegation.Delegate__c,
                            picklistLabelsByApiValues.get(delegation.Delegate_for_Market__c)
                    )
            );
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(emailMessagesToSend);
    }
    @AuraEnabled
    public static List<Id> getCurrentDelegateIds(){
        List<Id> delegateIds = new List<Id>();
        for (Delegation__c delegation : [SELECT Id, Delegate__c FROM Delegation__c WHERE (Valid_From__c <= TODAY AND Valid_To__c >= TODAY)]){
            delegateIds.add(delegation.Delegate__c);
        }
        return delegateIds;
    }


    public class DelegationWrapper {
        @AuraEnabled
        public String delegationId { get; set; }
        @AuraEnabled
        public String delegateName { get; set; }
        @AuraEnabled
        public String market { get; set; }
        @AuraEnabled
        public Id delegateId { get; set; }
        @AuraEnabled
        public String validFrom { get; set; }
        @AuraEnabled
        public String validTo { get; set; }

        public DelegationWrapper(){

        }

        public DelegationWrapper(Delegation__c delegation) {
            delegationId = delegation.Id;
            delegateName = delegation.Delegate__r.Name;
            market = picklistLabelsByApiValues.get(delegation.Delegate_for_Market__c);
            validFrom = delegation.Valid_From__c.format();
            validTo = delegation.Valid_To__c.format();
            delegateId = delegation.Delegate__c;
        }
    }

    public class PicklistEntryWrapper {
        @AuraEnabled
        public String picklistLabel { get; set; }
        @AuraEnabled
        public String picklistValue { get; set; }

        public PicklistEntryWrapper(PicklistEntry picklistEntry) {
            picklistLabel = picklistEntry.label;
            picklistValue = picklistEntry.value;
        }
    }

    public class RequestWrapper implements Comparable {
        @AuraEnabled
        public String RequestId { get; set; }
        @AuraEnabled
        public String AccountId { get; set; }
        @AuraEnabled
        public String Accountname { get; set; }
        @AuraEnabled
        public String BillingCountry { get; set; }
        @AuraEnabled
        public String BillingCountryCode { get; set; }
        @AuraEnabled
        public Boolean ShowFlag { get; set; }
        @AuraEnabled
        public String CustomerSegment { get; set; }
        @AuraEnabled
        public String RequestDate { get; set; }
        @AuraEnabled
        public String LastKAMSubmitter { get; set; }
        @AuraEnabled
        public String KAMProposal { get; set; }
        @AuraEnabled
        public String KAMProposalComment { get; set; }
        @AuraEnabled
        public String CommentsFromAMC { get; set; }
        @AuraEnabled
        public Boolean Approval { get; set; }
        @AuraEnabled
        public String VPComment { get; set; }
        @AuraEnabled
        public Boolean Locked { get; set; }
        @AuraEnabled
        public String Delegate { get; set; }
        @AuraEnabled
        public String DelegateField { get; set; }
        @AuraEnabled
        public String DelegateFieldForEmail { get; set; }
        @AuraEnabled
        public Boolean AMCUser { get; set; }
        @AuraEnabled
        public Date selectedDate { get; set; }
        @AuraEnabled
        public String selectedDateFormatted { get; set; }
        @AuraEnabled
        public Date deadline { get; set; }
        @AuraEnabled
        public String deadlineFormatted { get; set; }
        @AuraEnabled
        public String CustomerCategory { get; set; }
        @AuraEnabled
        public String CurrentAccountOwner { get; set; }
        @AuraEnabled
        public Date Today { get; set; }
        @AuraEnabled
        public Date RequestBatchDate { get; set; }
        @AuraEnabled
        public Boolean DelegateUser { get; set; }
        @AuraEnabled
        public Boolean AllApprovalsSubmitted { get; set; }
        @AuraEnabled
        public List<Id> Delegates { get; set; }
        @AuraEnabled
        public Integer numberOfNewRequests { get; set; }

        public RequestWrapper(KAM_request__c request) {
            RequestId = request.Id;
            AccountId = request.Key_Account__r.Id;
            Accountname = request.Key_Account__r.Name;
            BillingCountry = request.Key_Account__r.BillingCountry;
            BillingCountryCode = request.Key_Account__r.BillingCountryCode;
            ShowFlag = (settings[0].Countries_with_Flags__c.split(';')).contains(request.Key_Account__r.BillingCountryCode) ? true : false;
            CustomerSegment = request.Key_Account__r.Customer_Segment_industry__c;
            RequestDate = request.KAM_request_sent__c.format();
            LastKAMSubmitter = request.Key_Account__r.last_KAM_Submitter__r.Name;
            KAMProposal = request.Key_Account__r.KAM_proposal__c;
            KAMProposalComment = request.Key_Account__r.KAM_Proposal_Comment__c;
            CommentsFromAMC = request.Key_Account__r.Comments_from_AMC__c;
            CustomerCategory = request.Key_Account__r.Customer_Type__c;
            CurrentAccountOwner = request.Key_Account__r.Owner.Name;
        }
        public RequestWrapper() {

        }
        public Integer compareTo(Object compareTo) {
            RequestWrapper compareToReq = (RequestWrapper) compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (BillingCountry > compareToReq.BillingCountry) {
                returnValue = 1;
            } else if (BillingCountry < compareToReq.BillingCountry) {
                returnValue = -1;
            } else {
                if (CurrentAccountOwner > compareToReq.CurrentAccountOwner) {
                    returnValue = 1;
                } else if (CurrentAccountOwner < compareToReq.CurrentAccountOwner) {
                    returnValue = -1;
                }
            }
            return returnValue;
        }
    }
}
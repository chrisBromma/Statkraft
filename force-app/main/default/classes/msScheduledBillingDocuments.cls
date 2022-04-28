/**
 *   Create By	 : Georg Luch (Statkraft)
 *   Create Date : 26.05.2021
 *   Description : Collects all billing-documents(invoices) at 09:00, 12:00, 15:00 and 18:00
 *                 and sends just one email to customer at 09:00, 12:00, 15:00 and 18:00 o'clock.
 *                 This prevents the spamming of the customer with too many emails, as it collects all invoices.
 *                 After sending them, the ContentVersion object will have customerNotInformed__c set to FALSE
 *                 for all relevant files.
 *   Ticket:       https://statkraftonjira.atlassian.net/browse/PIM-1153
 *
 *   Confluence-
 *   Documentation:https://statkraft.atlassian.net/wiki/spaces/SKH/pages/3040215060/Automation+Billing-Documents
 *
 *   Installation: Use the "Batch Apex Scheduler"-App in Salesforce with your custom cron expression.
 *
 */

public without sharing class msScheduledBillingDocuments extends BatchJobBase implements Queueable {

    static final Datetime CURRENTDATE = Datetime.now();
    static final String LOG_MESSAGE = 'Billing Documents - Notification';
    Set<String> contractsSet = new Set<String>();

    /**
     * @description Entrypoint-method to send an email-notification towards a customer about his billing-documents
     * @param ctx Standard parameter in scheduleables
     */
    public void execute(QueueableContext ctx) {
        super.startLogging(ctx?.getJobId());
        System.attachFinalizer(this);
        run('new_invoice');
        super.logInformation(ctx?.getJobId(), 'Billing Documents Sent');
    }

    public void run(String invoiceType) {
        Logger.info('Billing Documents: Scheduled Job Started successfully at: ' + System.now());

        List<msUserNotificationSetting__c> subscribedUsers = getSubscribedUsersToNotification(invoiceType); // Get subscriptions to billing-documents
        if (subscribedUsers == null) {
            Logger.info('Billing Documents: No subscribed users found. Stopping Job.');
            Logger.saveLog(LOG_MESSAGE + ': No subscribed users found');
            return; // Early STOPPING: No subscribed users found
        }

        List<Id> contractsToNotifyAboutNewBillingDocument = getContractIdsGivenSubscribedUsers(subscribedUsers);
        if (contractsToNotifyAboutNewBillingDocument == null) {
            Logger.info('Billing Documents: No contracts found. Stopping Job.');
            Logger.saveLog(LOG_MESSAGE + ': No contracts found');
            return; // Early STOPPING:
        }

        Map<Id, List<ContentVersion>> entityIdToContentVersions = createContractIdToListOfContentVersions(CURRENTDATE, contractsToNotifyAboutNewBillingDocument);

        if (!entityIdToContentVersions.isEmpty()) {
            List<String> contractList = new List<String>();
            contractList.addAll(contractsSet);
            Logger.info('Billing Documents: These contracts were informed about new billing-documents: ' + JSON.serializePretty(contractList) + ' - And these are the billing-documents: ' + JSON.serializePretty(entityIdToContentVersions));
            Logger.saveLog(LOG_MESSAGE);
            msNotificationLogic.distributeMessage('Contract__c', contractList, 'new_invoice_by_trigger', null, null, null, entityIdToContentVersions);

            // Customer is informed about this file, so change flag(informed) of each file
            setCustomerNotInformedFieldInContentVersionToFalse(entityIdToContentVersions);
        } else {
            Logger.info('Billing Documents: No emails sent due to empty entityIdToContentVersions (no Contract__c.Id´s with corresponding contentVerion found).');
            Logger.saveLog(LOG_MESSAGE + ': No Documents found');
        }
    }

    /**
     * @description Gets users subscribed to billing-document-notification
     *  msNotificationType__c can be:
     *      - new_invoice
     *      - downreg_notification
     *      - submeter_enabled
     *      - monthly_production_data
     * @param notificationType The notification type
     * @return List<msUserNotificationSetting__c>
     */
    public List<msUserNotificationSetting__c> getSubscribedUsersToNotification(String notificationType) {

        List<msUserNotificationSetting__c> subscribedUsers = new List<msUserNotificationSetting__c>([
                SELECT Id, msContact__c
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = :notificationType
        ]);

        return subscribedUsers;

        // Map<Id, User> receiveRecipients(String objectType, List<String> recordIds, String messageType) {
    }

    /**
     * @description Gets Contract__c.Id´s given subscribed-users
     * @param subscribedUsers List<msUserNotificationSetting__c> subscribedUsers
     * @return List<Id> Contract Ids as a list
    */
    public List<Id> getContractIdsGivenSubscribedUsers(List<msUserNotificationSetting__c> subscribedUsers) {

        Set<Id> contactIdsFromMsUserNotificationSetting = new Set<Id>();

        // Get Contract__c.Id from msUserNotificationSetting__c
        for (msUserNotificationSetting__c contractId : subscribedUsers) {
            contactIdsFromMsUserNotificationSetting.add(contractId.msContact__c);
        }

        // Select ONLY valid/active contracts, given subscribed-users
        List<Contract_Role__c> respectiveContracts = new List<Contract_Role__c>([
                SELECT Contract__c
                FROM Contract_Role__c
                WHERE Contact__c IN :contactIdsFromMsUserNotificationSetting
                AND Contract__r.Status__c = 'Active'
        ]);

        List<Id> contractList = new List<Id>();
        for (Contract_Role__c contractId : respectiveContracts) {
            contractList.add(contractId.Contract__c);
        }

        return contractList;
    }

    /**
     * @description Creates a MAP with Contract__c.Id´s to list of contentVerion
     * @param currentDate The current date
     * @param contractIdsAsList contract__c.Id´s as a list
     *
     * @return entityIdToContentVersions (Entity is in this case the Contract__c.Id)
     */
    public Map<Id, List<ContentVersion>> createContractIdToListOfContentVersions(Datetime currentDate, List<Id> contractIdsAsList) {

        String day = currentDate.format('dd');
        String month = currentDate.format('MM');
        String year = currentDate.format('YYYY');

        Integer currentHour = currentDate.hour();

        Datetime createdDate = Datetime.newInstanceGmt( // GMT time zone !
                Integer.valueOf(year),
                Integer.valueOf(month),
                Integer.valueOf(day),
                currentHour,
                00,
                00
        );

        // 0. Get all valid Attachmenttypes__c, which are valid for billing-documents.
        // Please note, that there are many of them. It´s NOT only just one!
        // AND: "Billing document" is not correct here.
        List<Attachmenttypes__c> attachmentTypesForBillingDocumentsList = new List<Attachmenttypes__c>(
        [
                SELECT msPicklist_Value_API_Name__c
                FROM Attachmenttypes__c
                WHERE Related_Object__c = 'Contract__c'
                AND msIsSendNotifications__c = TRUE
                AND msIsShowInPortal__c = TRUE
        ]
        );
        Set<String> attachmentTypesForBillingDocuments = new Set<String>();
        for (Attachmenttypes__c attachmenttype : attachmentTypesForBillingDocumentsList) {
            attachmentTypesForBillingDocuments.add(attachmenttype.msPicklist_Value_API_Name__c);
        }

        // 1. Get all new Billing-Documents
        List<ContentVersion> contentVersionDocumentsList = new List<ContentVersion>(
        [
                SELECT ContentDocumentId, Attachement_Type__c
                FROM ContentVersion
                WHERE customerNotInformed__c = TRUE
                AND Attachement_Type__c IN :attachmentTypesForBillingDocuments
                AND CreatedDate <= :createdDate
                AND IsLatest = TRUE
        ]
        );
        Map<Id, ContentVersion> contentDocumentIdsToContentVersionMap = new Map<Id, ContentVersion>();

        for (ContentVersion contentVersionDocument : contentVersionDocumentsList) {
            contentDocumentIdsToContentVersionMap.put(contentVersionDocument.ContentDocumentId, contentVersionDocument);
        }

        // 2. Get all ContentDocumentLink (We don´t want files with Entity.Id = User.Id | Only Entity.Id = Contract.Id)
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>(
        [
                SELECT Id, ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contentDocumentIdsToContentVersionMap.keySet()
                AND LinkedEntityId IN :contractIdsAsList
        ]
        );

        // Map<Id, List<ContentVersion>> entityIdToContentVersions):
        //          1st element ist the Contract__c.Id (this is the EntityId here)
        //          2nd element is a list of ContentVersion.
        // Map<Id, List<ContentVersion>> entityIdToContentVersions = new Map<Id, List<ContentVersion>>();
        Map<Id, List<ContentVersion>> entityIdToContentVersions = new Map<Id, List<ContentVersion>>();

        // Better LOOP (THX @ Dennis Grzyb):
        for (ContentDocumentLink cdl : contentDocumentLinkList) { // Mapping: Contract(LinkedEntityId) <-TO-> ContentVersion
            ContentVersion contentVersion = contentDocumentIdsToContentVersionMap.get(cdl.ContentDocumentId);

            if (entityIdToContentVersions.get(cdl.LinkedEntityId) == null) { // No contract found yet, so create a new entry
                List<ContentVersion> cvList = new List<ContentVersion>();
                cvList.add(contentVersion);
                entityIdToContentVersions.put(cdl.LinkedEntityId, cvList); // Create 1st-contract + CV-List
            } else { // Update map: Add more contentVersion records to the same Contract(LinkedEntityId)
                entityIdToContentVersions.get(cdl.LinkedEntityId).add(contentVersion);
            }

            contractsSet.add(cdl.LinkedEntityId);
        }

        return entityIdToContentVersions;
    }

    /**
     * @description Updates all relevant billing-documents(contentVersion) to: CustomerWasNotifiedAboutThisDocument
     * @param entityIdToContentVersions A map with contract__c.Id´s with a List of content-versions
     */
    public void setCustomerNotInformedFieldInContentVersionToFalse(Map<Id, List<ContentVersion>> entityIdToContentVersions) {
        List<ContentVersion> contentVersionDocumentsToUpdate = new List<ContentVersion>();

        for (List<ContentVersion> contentVersionMap : entityIdToContentVersions.values()) {
            for (ContentVersion contentVersionId : contentVersionMap) {

                // customerNotInformed__c == false : Customer was informed via email.
                ContentVersion contentVersionDocument = new ContentVersion(Id = contentVersionId.Id, customerNotInformed__c = false);
                contentVersionDocumentsToUpdate.add(contentVersionDocument);
            }
        }

        update contentVersionDocumentsToUpdate;
    }

}
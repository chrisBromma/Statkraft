/****************************************************************************************************
 * Class msBrytNotificationLogic
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 13.02.2019
 *   Description : Central class for all notifications that are executed through the Bryt Customer Portal
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	13.02.2019	Init version.
 *****************************************************************************************************/

public without sharing class msBrytNotificationLogic {

    public static final Id BRYT_CONTRACT_RECORD_TYPE_ID = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
    public static final Id BRYT_CONTRACT_ROLE_RECORD_TYPE_ID = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
    public static final Id BRYT_CONTACT_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('msBrytContact').getRecordTypeId();

    @Future(Callout=true)
    public static void notifyForTrades(List<Id> pcIds) {
        Bryt_Portal_Settings__mdt portalSetting = msBrytUtility.getMetadata();
        List<Pricing_Component__c> pcList = [
                SELECT Id, Contract__c
                FROM Pricing_Component__c
                WHERE Id IN :pcIds
        ];
        Set<Id> contractIds = new Set<Id>();
        Map<Id, Set<Id>> contractToPCIdsMap = new Map<Id, Set<Id>>();
        for (Pricing_Component__c pcItem : pcList) {
            contractIds.add(pcItem.Contract__c);
            if (!contractToPCIdsMap.containsKey(pcItem.Contract__c)) {
                contractToPCIdsMap.put(pcItem.Contract__c, new Set<Id>());
            }
            contractToPCIdsMap.get(pcItem.Contract__c).add(pcItem.Id);
        }

        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([
                SELECT Id, Name, BrytNotificationEmails__c
                FROM Contract__c
                WHERE Id IN :contractIds
        ]);

        if (portalSetting.Enable_Trade_Notifications_Debug_Mode__c) {
            try {
                Id targetCheck = [
                        SELECT Id
                        FROM User
                        WHERE Id = :portalSetting.Trade_Notifications_Debug_Target__c
                        AND IsActive = TRUE
                        LIMIT 1
                ].Id;
            } catch (Exception e) {
                System.debug('Bryt Debug User Id is improper');
                portalSetting.Trade_Notifications_Debug_Target__c = null;
            }
        }
        List<String> notificationTargetEmails = portalSetting.Trade_Notification_Recipients__c.split(';');
        Set<String> vettedNotificationTargets = new Set<String>();
        for (String emailToCheck : notificationTargetEmails) {
            if (checkEmailPattern(emailToCheck)) {
                vettedNotificationTargets.add(emailToCheck);
            } else {
                System.debug('Bryt Portal Setting has an failing Email address: ' + emailToCheck);
            }
        }

        Map<Id, Set<Id>> contractIdToUserIdsToNotifyMap = getAllUsersRelatedToContracts(contractIds);

        List<notificationWrapper> notifications = new List<notificationWrapper>();
        for (Id contractId : contractIds) {
            notificationWrapper contractNotification = new notificationWrapper();
            contractNotification.contract = contractsMap.get(contractId);
            contractNotification.pcIds = contractToPCIdsMap.get(contractId);
            contractNotification.isDebug = portalSetting.Enable_Trade_Notifications_Debug_Mode__c;
            contractNotification.debugTarget = portalSetting.Trade_Notifications_Debug_Target__c;
            contractNotification.targetUserIds = contractIdToUserIdsToNotifyMap.get(contractId);
            contractNotification.targetEmailsList = vettedNotificationTargets;
            notifications.add(contractNotification);
        }

        msBrytMailConf.msSendConfirmationMails(notifications);

    }

    private static Map<Id, Set<Id>> getAllUsersRelatedToContracts(Set<Id> contractIds) {
        Id brytCustomerProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'Bryt Customer Community User' LIMIT 1].Id;

        List<Contract_Role__c> connectedRoles = [
                SELECT Contact__c, Contract__c
                FROM Contract_Role__c
                WHERE RecordTypeId = :BRYT_CONTRACT_ROLE_RECORD_TYPE_ID
                AND Contract__r.RecordTypeId = :BRYT_CONTRACT_RECORD_TYPE_ID
                AND Contact__r.RecordTypeId = :BRYT_CONTACT_RECORD_TYPE_ID
                AND Contract__c IN :contractIds
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
                AND Bryt_isTPI__c = TRUE
        ];

        Map<Id, Set<Id>> contractIdsToContactsToNotifyIdsMap = new Map<Id, Set<Id>>();
        Set<Id> contactIdsToMatchToUsers = new Set<Id>();
        for (Contract_Role__c connectedRole : connectedRoles) {
            if (!contractIdsToContactsToNotifyIdsMap.containsKey(connectedRole.Contract__c)) {
                contractIdsToContactsToNotifyIdsMap.put(connectedRole.Contract__c, new Set<Id>());
            }
            contractIdsToContactsToNotifyIdsMap.get(connectedRole.Contract__c).add(connectedRole.Contact__c);
            contactIdsToMatchToUsers.add(connectedRole.Contact__c);
        }

        List<User> connectedUsers = [
                SELECT Id, ContactId
                FROM User
                WHERE (ContactId IN :contactIdsToMatchToUsers OR Id = :UserInfo.getUserId())
                AND ProfileId = :brytCustomerProfileId
        ];
        Map<Id, Id> contactIdToUserIdMap = new Map<Id, Id>();
        for (User connectedUser : connectedUsers) {
            contactIdToUserIdMap.put(connectedUser.ContactId, connectedUser.Id);
        }

        Map<Id, Set<Id>> contractIdToUserIdsToNotifyMap = new Map<Id, Set<Id>>();
        for (Id contractId : contractIdsToContactsToNotifyIdsMap.keySet()) {
            if (contractIdsToContactsToNotifyIdsMap.containsKey(contractId)) {
                for (Id contactId : contractIdsToContactsToNotifyIdsMap.get(contractId)) {
                    if (contactIdToUserIdMap.containsKey(contactId)) {
                        if (!contractIdToUserIdsToNotifyMap.containsKey(contractId)) {
                            contractIdToUserIdsToNotifyMap.put(contractId, new Set<Id>());
                        }
                        contractIdToUserIdsToNotifyMap.get(contractId).add(contactIdToUserIdMap.get(contactId));
                    }
                }
            }
        }

        return contractIdToUserIdsToNotifyMap;
    }

    public static Boolean checkEmailPattern(String emailToCheck) {
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher emailMatcher = emailPattern.matcher(emailToCheck);
        return emailMatcher.matches();
    }

    public class notificationWrapper {
        public Contract__c contract { get; set; }
        public Set<Id> pcIds { get; set; }
        public Set<Id> targetUserIds { get; set; }
        public Set<String> targetEmailsList { get; set; }
        public Boolean isDebug { get; set; }
        public Id debugTarget { get; set; }

        public notificationWrapper() {
            contract = null;
            pcIds = new Set<Id>();
            targetUserIds = new Set<Id>();
            targetEmailsList = new Set<String>();
            isDebug = false;
            debugTarget = null;
        }
    }
}
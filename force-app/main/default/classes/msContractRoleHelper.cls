/****************************************************************************************************
* Class msContractRoleHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-06-15
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-06-15       	Init version.
*****************************************************************************************************/

public without sharing class msContractRoleHelper {

    //List all needed RecordType Ids here
    public static final Id CONTRACT_ROLE_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract_Role__c', 'Contract_Role_Contact').Id;
    public static final Id SITE_ROLE_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Site_Role__c', 'Site_Role_Contact').Id;

    //Trigger Maps/Lists
    private List<Contract_Role__c> triggerOld;
    private List<Contract_Role__c> triggerNew;
    private Map<Id, Contract_Role__c> oldMap;
    private Map<Id, Contract_Role__c> newMap;


    //SOQL Maps from bulk. Important: Only ever use one Map per SObject Type!
    private Map<Id, Contact> contactMap = new Map<Id, Contact>();
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Contract_Role__c> contractRoleMap = new Map<Id, Contract_Role__c>();
    private Map<Id, MeterRegistration__c> meterRegistrationMap = new Map<Id, MeterRegistration__c>();
    private Map<Id, Site_Role__c> siteRoleMap = new Map<Id, Site_Role__c>();
    private Map<Id, msUserNotificationSetting__c> userNotificationSettingsMap = new Map<Id, msUserNotificationSetting__c>();


    //DML Lists and Maps. Important only ever use one Map/List per SObject Type and DML operation!
    public Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>();
    public List<Contract_Role__c> contractRolesToInsertList = new List<Contract_Role__c>();
    public Map<Id, Contract_Role__c> contractRoleUpdateMap = new Map<Id, Contract_Role__c>();
    public List<Site_Role__c> siteRolesToInsertList = new List<Site_Role__c>();
    public Map<Id, Site_Role__c> siteRoleUpdateMap = new Map<Id, Site_Role__c>();
    public List<msUserNotificationSetting__c> userNotificationSettingsToInsert = new List<msUserNotificationSetting__c>();


    //All Helper Variables for ContractRole Naming
    Set<Id> crn_ContractIds = new Set<Id>();
    private Map<Id, Set<String>> crn_contractIdToMeterNamesMap = new Map<Id, Set<String>>();


    //All Helper Variables for automated Customer Portal Role creation
    private Set<Id> ccr_Ids = new Set<Id>();
    private Set<Id> ccr_ContactIds = new Set<Id>();
    private Set<Id> ccr_ContractIds = new Set<Id>();
    private Set<Id> ccr_MeterIds = new Set<Id>();
    private Map<Id, ListMapContainer> ccr_contactIdToContractToListContractRolesCustomerPortal =
            new Map<Id, ListMapContainer>();
    private Map<Id, ListMapContainer> ccr_contactIdToMeterToListSiteRolesCustomerPortal
            = new Map<Id, ListMapContainer>();
    private ListMapContainer ccr_contractIdToMeterRegistrationMap
            = new ListMapContainer(MeterRegistration__c.getSObjectType());

    //All Helper variables for France Invoice Notification Auto Register
    private Set<Id> fpr_Ids = new Set<Id>();
    private Set<Id> fpr_Contacts = new Set<Id>();
    private Set<Id> fpr_Contracts = new Set<Id>();
    private Set<Id> fpr_contactIdsRegisteredForNewInvoiceNotifications = new Set<Id>();
    private Set<Id> fpr_ContactsToEnablePortalInvoiceNotifications = new Set<Id>();

    public msContractRoleHelper(
            List<Contract_Role__c> oldList,
            List<Contract_Role__c> newList,
            Map<Id, Contract_Role__c> mapOld,
            Map<Id, Contract_Role__c> mapNew) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    public void crn_identifyAllContractsForContractRoleNaming() {
        for (Contract_Role__c newRole : triggerNew) {
            crn_ContractIds.add(newRole.Contract__c);
        }
    }

    public void crn_identifyAllContractsForContractRoleRenaming() {
        for (Contract_Role__c newRole : triggerNew) {
            if(newRole.Name == 'Reinitialize') {
                crn_ContractIds.add(newRole.Contract__c);
            }
        }
    }

    public void crn_checkContractRoleForRenaming(Contract_Role__c newRole) {
        if (newRole.Name == 'Reinitialize') {
            crn_nameContractRole(newRole);
        }
    }

    public void ccr_identifyContractualContactRoleIds() {
        for (Contract_Role__c roleToInspect : triggerNew) {
            if (roleToInspect.Role__c != null
                    && roleToInspect.Role__c.contains('Contractual contact')
                    && roleToInspect.Contract__c != null
                    && roleToInspect.RecordTypeId == CONTRACT_ROLE_RECORD_TYPE) {
                ccr_ContactIds.add(roleToInspect.Contact__c);
                ccr_ContractIds.add(roleToInspect.Contract__c);
                ccr_Ids.add(roleToInspect.Id);
            }
        }
    }

    public void ccr_identifyMeterIds() {
        for (MeterRegistration__c regItem : meterRegistrationMap.values()) {
            if (ccr_ContractIds.contains(regItem.Contract__c)) {
                ccr_MeterIds.add(regItem.Meter__c);
            }
        }
    }

    public void fpr_identifyIdsForFranceAutoSubscriptionToNotifications() {
        for (Contract_Role__c contract_role : triggerNew) {
            if (contract_role.RecordTypeId == CONTRACT_ROLE_RECORD_TYPE
                    && contract_role.Role__c != null
                    && contract_role.Role__c.contains('Customer Portal')
                    && contract_role.Contact__c != null) {
                fpr_Contacts.add(contract_role.Contact__c);
                fpr_Contracts.add(contract_role.Contract__c);
                fpr_Ids.add(contract_role.Id);
            }
        }
    }

    public void loadContacts() {
        if (!fpr_Contacts.isEmpty()
                || !ccr_ContactIds.isEmpty()) {
            contactMap = new Map<Id, Contact>([
                    SELECT Name, Email, (SELECT Id, Username FROM Users)
                    FROM Contact
                    WHERE Id IN :fpr_Contacts
                    OR Id IN :ccr_ContactIds
            ]);
        }
    }

    public void loadContracts() {
        if (!crn_ContractIds.isEmpty()
                || !fpr_Contracts.isEmpty()
                || !ccr_ContractIds.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, Name, Global_Portal_Market__c, (
                            SELECT Id, Meter__r.Name, Contract__c
                            FROM Meter_Registrations__r
                            ORDER BY CreatedDate ASC
                    )
                    FROM Contract__c
                    WHERE Id IN :crn_ContractIds
                    OR Id IN :fpr_Contracts
                    OR Id IN :ccr_ContractIds
            ]);
        }
    }

    public void loadContractRoles() {
        if (!ccr_ContactIds.isEmpty() && !ccr_ContractIds.isEmpty()) {
            contractRoleMap = new Map<Id, Contract_Role__c>([
                    SELECT Id, Name, Contact__c, Contract__c, Start_Date__c, End_Date__c, Role__c, RecordTypeId
                    FROM Contract_Role__c
                    WHERE Contact__c IN :ccr_ContactIds
                    AND Contract__c IN :ccr_ContractIds
                    AND RecordTypeId = :CONTRACT_ROLE_RECORD_TYPE
                    ORDER BY Start_Date__c ASC
            ]);
        }
    }

    public void loadMeterRegistrations() {
        if (!ccr_ContractIds.isEmpty()) {
            meterRegistrationMap = new Map<Id, MeterRegistration__c>([
                    SELECT Id, Name, Meter__c, Contract__c, Valid_to__c, Valid_from__c
                    FROM MeterRegistration__c
                    WHERE Contract__c IN :ccr_ContractIds
                    OR Contract__r.Parent_Contract__c IN :ccr_ContractIds
                    ORDER BY Valid_from__c ASC
            ]);
        }
    }

    public void loadSiteRoles() {
        if (!ccr_ContactIds.isEmpty() && !ccr_MeterIds.isEmpty()) {
            siteRoleMap = new Map<Id, Site_Role__c>([
                    SELECT Id, Name, Meter__c, Contact__c, Start_Date__c, End_Date__c, Role__c, RecordTypeId
                    FROM Site_Role__c
                    WHERE Meter__c IN :ccr_MeterIds
                    AND Contact__c IN :ccr_ContactIds
                    AND RecordTypeId = :SITE_ROLE_RECORD_TYPE
                    ORDER BY Start_Date__c ASC
            ]);
        }
    }

    public void loadUserNotificationSettings() {
        if (!fpr_Contacts.isEmpty()) {
            userNotificationSettingsMap = new Map<Id, msUserNotificationSetting__c>([
                    SELECT Id, msContact__c, msNotificationType__c
                    FROM msUserNotificationSetting__c
            ]);
        }
    }


    public void crn_buildContractRoleNameDataModel() {
        for (Id contractId : crn_ContractIds) {
            for (MeterRegistration__c regItem : contractMap.get(contractId).Meter_Registrations__r) {
                msLepton.addToMap(regItem.Contract__c, regItem.Meter__r.Name, crn_contractIdToMeterNamesMap);
            }
        }
    }

    public void ccr_buildContractualContactDataModel() {
        for (Contract_Role__c roleItem : contractRoleMap.values()) {
            if (roleItem.Role__c != null
                    && roleItem.Role__c.contains('Customer Portal')
                    && roleItem.Contact__c != null
                    && roleItem.RecordTypeId == CONTRACT_ROLE_RECORD_TYPE
                    && ccr_ContactIds.contains(roleItem.Contact__c)) {
                msLepton.addToMap(roleItem.Contact__c, roleItem.Contract__c, roleItem, ccr_contactIdToContractToListContractRolesCustomerPortal);
            }
        }
        for (Site_Role__c roleItem : siteRoleMap.values()) {
            if (roleItem.Role__c != null
                    && roleItem.Role__c.contains('Customer Portal')
                    && roleItem.Contact__c != null
                    && roleItem.RecordTypeId == SITE_ROLE_RECORD_TYPE
                    && ccr_ContactIds.contains(roleItem.Contact__c)) {
                msLepton.addToMap(roleItem.Contact__c, roleItem.Meter__c, roleItem, ccr_contactIdToMeterToListSiteRolesCustomerPortal);
            }
        }
        for (MeterRegistration__c regItem : meterRegistrationMap.values()) {
            ccr_contractIdToMeterRegistrationMap.addToMap(regItem.Contract__c, regItem);
        }
    }

    public void fpr_buildFrenchPortalRoleDataModel() {
        for (msUserNotificationSetting__c settingItem : userNotificationSettingsMap.values()) {
            if (fpr_Contacts.contains(settingItem.msContact__c)
                    && settingItem.msNotificationType__c == 'new_invoice') {
                fpr_contactIdsRegisteredForNewInvoiceNotifications.add(settingItem.msContact__c);
            }
        }
    }

    public void ccr_prepareInsertOrUpdateOfPortalRoles(Contract_Role__c newContractRole) {
        if (ccr_Ids.contains(newContractRole.Id)) {
            List<Contract_Role__c> existingContractRolesCustomerPortal = new List<Contract_Role__c>();
            if (ccr_contactIdToContractToListContractRolesCustomerPortal.get(newContractRole.Contact__c) != null) {
                existingContractRolesCustomerPortal =
                        ccr_contactIdToContractToListContractRolesCustomerPortal.get(newContractRole.Contact__c).get(newContractRole.Contract__c);
            }
            if (existingContractRolesCustomerPortal == null) {
                addInsertContractRoleCustomerPortal(contractRolesToInsertList, newContractRole);
            } else {
                Boolean matchFound = tryToAddToUpdateMap(contractRoleUpdateMap, existingContractRolesCustomerPortal, newContractRole);
                if (!matchFound) {
                    addInsertContractRoleCustomerPortal(contractRolesToInsertList, newContractRole);
                }
            }

            List<MeterRegistration__c> relevantMeterRegistrations = ccr_contractIdToMeterRegistrationMap.get(newContractRole.Contract__c);
            if (relevantMeterRegistrations != null) {
                Set<Id> meterIdsToConnect = new Set<Id>();
                for (MeterRegistration__c regItem : relevantMeterRegistrations) {
                    if (msLepton.checkDateIntersectionWithInfinity(
                            regItem.Valid_from__c,
                            regItem.Valid_to__c,
                            newContractRole.Start_Date__c,
                            newContractRole.End_Date__c)) {
                        meterIdsToConnect.add(regItem.Meter__c);
                    }
                }

                ListMapContainer existingSiteRolesCustomerPortal = ccr_contactIdToMeterToListSiteRolesCustomerPortal.get(newContractRole.Contact__c);
                for (Id meterId : meterIdsToConnect) {
                    if (existingSiteRolesCustomerPortal == null || existingSiteRolesCustomerPortal.get(meterId) == null) {
                        addInsertSiteRoleCustomerPortal(siteRolesToInsertList, newContractRole, meterId);
                    } else {
                        Boolean matchFound = tryToAddToUpdateMap(siteRoleUpdateMap, existingSiteRolesCustomerPortal.get(meterId), newContractRole);
                        if (!matchFound) {
                            addInsertSiteRoleCustomerPortal(siteRolesToInsertList, newContractRole, meterId);
                        }
                    }
                }
            }
        }
    }

    public void crn_nameContractRole(Contract_Role__c newRole) {
        newRole.Name = contractMap.get(newRole.Contract__c).Name;
        if (crn_contractIdToMeterNamesMap.containsKey(newRole.Contract__c)) {
            newRole.Name += '-';
            for (String meterName : crn_contractIdToMeterNamesMap.get(newRole.Contract__c)) {
                newRole.Name += meterName + ',';
            }
            newRole.Name = newRole.Name.removeEnd(',');
            if (newRole.Name.length() > 80) {
                newRole.Name = newRole.Name.left(76) + '...';
            }
        }
    }

    public void fpr_checkForFranceInvoiceNotificationSubscription(Contract_Role__c newContractRole) {
        if (fpr_Ids.contains(newContractRole.Id)
                && contractMap.get(newContractRole.Contract__c).Global_Portal_Market__c == 'France'
                && newContractRole.Contact__c != null
                && (contactMap.get(newContractRole.Contact__c).Email == null
                || !contactMap.get(newContractRole.Contact__c).Email.contains('@statkraft.'))
                && !fpr_contactIdsRegisteredForNewInvoiceNotifications.contains(newContractRole.Contact__c)
                && newContractRole.Role__c != null
                && newContractRole.Role__c.contains('Customer Portal')
                && newContractRole.RecordTypeId == CONTRACT_ROLE_RECORD_TYPE) {
            fpr_ContactsToEnablePortalInvoiceNotifications.add(newContractRole.Contact__c);
        }
    }

    private static void addInsertContractRoleCustomerPortal(
            List<Contract_Role__c> contractRolesToInsertList,
            Contract_Role__c contractRoleToMatch) {
        Boolean matchToInsertFound = false;

        for (Contract_Role__c roleToInsert : contractRolesToInsertList) {
            if (roleToInsert.Role__c != null
                    && roleToInsert.Role__c.contains('Customer Portal')
                    && contractRoleToMatch.Contract__c == roleToInsert.Contract__c
                    && roleToInsert.RecordTypeId == CONTRACT_ROLE_RECORD_TYPE) {
                matchToInsertFound = true;
                roleToInsert.Start_Date__c = msLepton.min(roleToInsert.Start_Date__c, contractRoleToMatch.Start_Date__c);
                roleToInsert.End_Date__c = null;
                break;
            }
        }
        if (!matchToInsertFound) {
            addToInsertList(contractRolesToInsertList, contractRoleToMatch);
        }
    }

    private static void addToInsertList(
            List<Contract_Role__c> contractRolesToInsertList, Contract_Role__c contractRole) {
        contractRolesToInsertList.add(new Contract_Role__c(
                Role__c = 'Customer Portal',
                Start_Date__c = contractRole.Start_Date__c,
                Contract__c = contractRole.Contract__c,
                Contact__c = contractRole.Contact__c,
                msAwaitingPortalActivation__c = true,
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        ));
    }

    private static void addInsertSiteRoleCustomerPortal(
            List<Site_Role__c> siteRolesToInsertList,
            Contract_Role__c contractRoleToMatch,
            Id meterId) {
        Boolean matchToInsertFound = false;

        for (Site_Role__c roleToInsert : siteRolesToInsertList) {
            if (roleToInsert.Role__c != null
                    && roleToInsert.Role__c.contains('Customer Portal')
                    && roleToInsert.Meter__c == meterId
                    && roleToInsert.RecordTypeId == SITE_ROLE_RECORD_TYPE) {
                matchToInsertFound = true;
                roleToInsert.Start_Date__c = msLepton.min(roleToInsert.Start_Date__c, contractRoleToMatch.Start_Date__c);
                roleToInsert.End_Date__c = null;
                break;
            }
        }
        if (!matchToInsertFound) {
            addToInsertList(siteRolesToInsertList, contractRoleToMatch, meterId);
        }
    }

    private static void addToInsertList(
            List<Site_Role__c> siteRolesToInsertList, Contract_Role__c contractRole, Id meterId) {
        siteRolesToInsertList.add(new Site_Role__c(
                Role__c = 'Customer Portal',
                Start_Date__c = contractRole.Start_Date__c,
                Meter__c = meterId,
                Contact__c = contractRole.Contact__c,
                msAwaitingPortalActivation__c = true,
                RecordTypeId = SITE_ROLE_RECORD_TYPE
        ));
    }

    private static Boolean tryToAddToUpdateMap(
            Map<Id, Contract_Role__c> contractRolesToUpdateMap,
            List<Contract_Role__c> existingContractRolesCustomerPortal,
            Contract_Role__c contractRoleToMatch
    ) {
        Boolean matchFound = false;
        for (Contract_Role__c roleToCheck : existingContractRolesCustomerPortal) {

            if (msLepton.checkDateIntersectionWithInfinity(
                    roleToCheck.Start_Date__c,
                    roleToCheck.End_Date__c,
                    contractRoleToMatch.Start_Date__c,
                    contractRoleToMatch.End_Date__c)) {
                matchFound = true;
                roleToCheck.Start_Date__c = msLepton.min(roleToCheck.Start_Date__c, contractRoleToMatch.Start_Date__c);
                roleToCheck.End_Date__c = null;
                contractRolesToUpdateMap.put(roleToCheck.Id, roleToCheck);
                break;
            }
        }
        return matchFound;
    }

    private static Boolean tryToAddToUpdateMap(
            Map<Id, Site_Role__c> siteRolesToUpdateMap,
            List<Site_Role__c> existingSiteRolesCustomerPortal,
            Contract_Role__c contractRoleToMatch
    ) {
        Boolean matchFound = false;
        for (Site_Role__c roleToCheck : existingSiteRolesCustomerPortal) {

            if (msLepton.checkDateIntersectionWithInfinity(
                    roleToCheck.Start_Date__c,
                    roleToCheck.End_Date__c,
                    contractRoleToMatch.Start_Date__c,
                    contractRoleToMatch.End_Date__c)) {
                matchFound = true;
                roleToCheck.Start_Date__c = msLepton.min(roleToCheck.Start_Date__c, contractRoleToMatch.Start_Date__c);
                roleToCheck.End_Date__c = null;
                siteRolesToUpdateMap.put(roleToCheck.Id, roleToCheck);
                break;
            }
        }
        return matchFound;
    }

    public void ccr_updateContactForPortalActivationIfNecessary(Contract_Role__c newRole) {
        if (ccr_Ids.contains(newRole.Id)
                && contactMap.get(newRole.Contact__c).Users.size() == 0) {

            Contact contactRequest = contactMap.get(newRole.Contact__c);
            contactRequest.msPortalRequestBy__c = null;
            contactRequest.msAwaitingPortalActivation__c = true;
            contactsToUpdateMap.put(contactRequest.Id, contactRequest);
        }
    }

    public void fpr_registerFrancePortalSubscriptions() {
        for (Id contactId : fpr_ContactsToEnablePortalInvoiceNotifications) {
            userNotificationSettingsToInsert.add(new msUserNotificationSetting__c(
                    msContact__c = contactId,
                    msNotificationType__c = 'new_invoice',
                    msIsEmail__c = true
            ));
        }
    }
}
/****************************************************************************************************
* Class msContractRoleHandler
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   --
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Steffen Naundorf (mindsquare GmbH)   --      	            Init version.
*****************************************************************************************************/


public without sharing class msContractRoleHandler extends TriggerHandlerExtension {

    msContractRoleHelper Helper;

    public msContractRoleHandler() {
        super();
        Helper = new msContractRoleHelper(
                (List<Contract_Role__c>) Trigger.old,
                (List<Contract_Role__c>) Trigger.new,
                (Map<Id, Contract_Role__c>) Trigger.oldMap,
                (Map<Id, Contract_Role__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate(Trigger.new, false);
            Helper.crn_identifyAllContractsForContractRoleNaming();
        }
        if (Trigger.isUpdate) {
            Helper.crn_identifyAllContractsForContractRoleRenaming();
        }
        Helper.loadContracts();
        Helper.crn_buildContractRoleNameDataModel();
    }

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            Helper.fpr_identifyIdsForFranceAutoSubscriptionToNotifications();
            Helper.ccr_identifyContractualContactRoleIds();
        }
        Helper.loadUserNotificationSettings();
        Helper.loadContracts();
        Helper.loadContacts();
        Helper.loadContractRoles();
        Helper.loadMeterRegistrations();
        Helper.ccr_identifyMeterIds();
        Helper.loadSiteRoles();
        Helper.ccr_buildContractualContactDataModel();
        Helper.fpr_buildFrenchPortalRoleDataModel();
    }

    public override void beforeInsert(SObject obj) {
        Contract_Role__c newRole = (Contract_Role__c) obj;
        Helper.crn_nameContractRole(newRole);
    }

    public override void beforeUpdate(SObject oldObj, SObject newObj) {
        Contract_Role__c newRole = (Contract_Role__c) newObj;
        Helper.crn_checkContractRoleForRenaming(newRole);
    }

    public override void afterInsert(SObject obj) {
        Contract_Role__c newContractRole = (Contract_Role__c) obj;

        Helper.fpr_checkForFranceInvoiceNotificationSubscription(newContractRole);
        Helper.ccr_prepareInsertOrUpdateOfPortalRoles(newContractRole);
        Helper.ccr_updateContactForPortalActivationIfNecessary(newContractRole);
    }

    public override void andFinally() {
        Helper.fpr_registerFrancePortalSubscriptions();
        if (!Helper.userNotificationSettingsToInsert.isEmpty()) {
            lstInsert.addAll(Helper.userNotificationSettingsToInsert);
        }
        if (!Helper.contractRolesToInsertList.isEmpty()) {
            lstInsert.addAll(Helper.contractRolesToInsertList);
        }
        if (!Helper.siteRolesToInsertList.isEmpty()) {
            lstInsert.addAll(Helper.siteRolesToInsertList);
        }
        if (!Helper.contactsToUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contactsToUpdateMap.values());
        }
        if (!Helper.contractRoleUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.contractRoleUpdateMap.values());
        }
        if (!Helper.siteRoleUpdateMap.isEmpty()) {
            lstUpdate.addAll(Helper.siteRoleUpdateMap.values());
        }

        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
        if (!lstUpdate.isEmpty()) {
            update lstUpdate;
        }
    }
}
/****************************************************************************************************
 * Class msAccountHandler
 *
 *   Create By	:   Mandy Bebenroth (mindsquare GmbH)
 *   Create Date	:   14.05.2020
 *   Description	:	rac_ - Remit ACER Code Change Cases
 *                      npo_ -  Negotiating Partner Ownership -
 *                              in Germany, the Owner of the Negotiation Party always has to be the Owner of the Account as well
 *                      TODO: The old logic still needs to be refactored to avoid double SOQLs etc
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                          	    Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Mandy Bebenroth (mindsquare GmbH)		14.05.2020       	Init version.
 *   * Fabian Murk (mindsquare AG)		        17.05.2021       	added precention of email notifications for insert and upsert
 *****************************************************************************************************/

public without sharing class msAccountHandler extends TriggerHandlerExtension {
    msAccountHelper Helper;

    // Constructor
    public msAccountHandler() {
        super();
        Helper = new msAccountHelper(
            (List<Account>) Trigger.old,
            (List<Account>) Trigger.new,
            (Map<Id, Account>) Trigger.oldMap,
            (Map<Id, Account>) Trigger.newMap
        );
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public override void bulkBefore() {
        if (Trigger.isInsert) {
            Helper.loadRelatedNegotiatingPartyParentAccounts();
            Helper.npo_listNegotiatingParties_Insert();
        } else if (Trigger.isUpdate) {
            Helper.loadRelatedNegotiatingPartyParentAccounts();
            Helper.npo_listNegotiatingParties_Update();
            Helper.loadRelatedNegotiatingPartyParentAccounts();
            Helper.scm_defineAccountsToSyncMarketPresenceFor();
        }
        Helper.load_CustomerNeedLinks();
        Helper.scm_buildDataModel();
        Helper.load_Accounts();
    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public override void bulkAfter() {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Helper.mpg_gatherMarketPresenceRelevantAccountIds();
        }
        if (Trigger.isUpdate) {
            Helper.load_KamTaskData();
            Helper.rac_identifyContractHolderForCases_Update();
        }
        Helper.loadNegotiatingParties();
        Helper.load_Contracts();
        Helper.load_Market_Presences();
        Helper.rac_buildDataModel();
        Helper.mpg_buildDataModel();
    }

    public override void beforeInsert(SObject obj) {
        Account newAccount = (Account) obj;
        Helper.npo_ensureCorrectOwnerId_Insert(newAccount);
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Account newAccount = (Account) obj;
        Account oldAccount = (Account) oldObj;
        Helper.preventNegotiatingPartyHierarchy(newAccount);
        Helper.npo_ensureCorrectOwnerId_Update(oldAccount, newAccount);
        Helper.scm_addMissingMarketsIntoMarketPresence(newAccount);
    }

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public override void afterInsert(SObject obj) {
        Account newAccount = (Account) obj;
        Helper.calculateNegotiatingPartyChildren(newAccount);
        Helper.mpg_getMarketPresencesToCreate(newAccount);
        Helper.mpg_getMarketPresencesToDelete(newAccount);
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public override void afterUpdate(SObject oldObj, SObject obj) {
        Account newAccount = (Account) obj;
        Account oldAccount = (Account) oldObj;
        Helper.defineKAMTasksToCreateOrReassign(newAccount);
        Helper.calculateNegotiatingPartyChildren(newAccount);
        Helper.rac_createAcerCodeChangeRemitCasesIfNecessary(oldAccount, newAccount);
        Helper.mpg_getMarketPresencesToCreate(newAccount);
        Helper.mpg_getMarketPresencesToDelete(newAccount);
    }

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public override void afterDelete(SObject obj) {
        Account oldAccount = (Account) obj;
        Helper.subtractNegotiatingPartyChild(oldAccount);
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public override void andFinally() {
        //Tasks are created and updated in future methods to be able to control notifications
        //Insert Tasks from Tasks Configuration Metadata
        if (!(Helper.accIdsToCreateTasksFor).isEmpty()) {
            msAccountHelper.createNewTasks(
                new List<Id>(Helper.accIdsToCreateTasksFor),
                JSON.serialize(Helper.taskConfigByTaskSubjectMap)
            );
        }

        //Update Tasks from Tasks Configuration Metadata
        if (!(Helper.taskIdsForOwnerUpdate).isEmpty()) {
            msAccountHelper.updateTaskOwner(
                new List<Id>(Helper.taskIdsForOwnerUpdate),
                JSON.serialize(Helper.taskConfigByTaskSubjectMap)
            );
        }

        // update lstUpdate-List
        if (!(Helper.accountUpdateMap).isEmpty()) {
            TriggerHandlerExtension.disableObject(Account.SObjectType);
            Database.update(Helper.accountUpdateMap.values());
            TriggerHandlerExtension.enableObject(Account.SObjectType);
        }

        if (!Helper.casesToInsert.isEmpty()) {
            lstInsert.addAll(Helper.casesToInsert);
        }

        if (!Helper.mpg_marketPresencesToCreate.isEmpty()) {
            lstInsert.addAll(Helper.mpg_marketPresencesToCreate.values());
        }

        if (!Helper.mpg_marketPresencesToDelete.isEmpty()) {
            lstDelete.addAll(Helper.mpg_marketPresencesToDelete.values());
        }

        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }

        if (!lstDelete.isEmpty()) {
            delete lstDelete;
        }
    }
}
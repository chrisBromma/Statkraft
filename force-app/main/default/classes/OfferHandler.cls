/****************************************************************************************************
 * Class OfferHandler
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2021-03-16
 *   Description	:
 *                      chd_ - Contract Historical Data (Files needs to be pushed from Offer to Resulting Contract)
 *                      eco_ - close lost of type extra ordinary needs special handling (contracts and pricing
 *                              need to be shortened etc.)
 *                      cwv_ - Closed Won Validations: Apex validations that are too complicated for regular validation
 *                              rules
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2021-03-16       	Init version.
 *****************************************************************************************************/

public without sharing class OfferHandler extends TriggerHandlerExtension {
    OfferHelper helper;

    public OfferHandler() {
        super();
        helper = new OfferHelper(
            (List<Offer__c>) Trigger.old,
            (List<Offer__c>) Trigger.new,
            (Map<Id, Offer__c>) Trigger.oldMap,
            (Map<Id, Offer__c>) Trigger.newMap);
    }

    public override void bulkBefore() {
    }

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            helper.eco_identifyRelevantOfferContractsInsert();
        }
        if (Trigger.isUpdate) {
            helper.cdh_identifyOffersWithSwitchingResultingContract();
            helper.eco_identifyRelevantOfferContractsUpdate();
        }
        if (Trigger.isUndelete) {
            helper.eco_identifyRelevantOfferContractsInsert();
        }
        helper.load_ContentDocumentLinks();
        helper.chd_buildCDLDataModel();
        helper.load_ContentVersions();
        helper.chd_buildCVDataModel();
        helper.load_Contracts();
        helper.load_PricingComponents();
        helper.eco_buildDataModel();
    }

    public override void beforeInsert(SObject obj) {
        Offer__c newOffer = (Offer__c) obj;
        helper.cwv_validateFieldsIfClosedWon(newOffer);
    }

    public override void beforeUpdate(SObject oldObj, SObject obj) {
        Offer__c oldOffer = (Offer__c) oldObj;
        Offer__c newOffer = (Offer__c) obj;
        helper.cwv_validateFieldsIfClosedWon(oldOffer, newOffer);
    }

    public override void afterInsert(SObject obj) {
        Offer__c newOffer = (Offer__c) obj;
        helper.eco_updateContract_Insert(newOffer);
        helper.eco_updatePCsIfNecessary_Insert(newOffer);
    }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        Offer__c oldOffer = (Offer__c) oldObj;
        Offer__c newOffer = (Offer__c) obj;
        helper.chd_ifContractChangedPassHistoricalData(oldOffer, newOffer);
        helper.eco_updateContract_Update(oldOffer, newOffer);
        helper.eco_updatePCsIfNecessary_Update(oldOffer, newOffer);
    }

    public override void afterUndelete(SObject obj) {
        Offer__c newOffer = (Offer__c) obj;
        helper.eco_updateContract_Insert(newOffer);
        helper.eco_updatePCsIfNecessary_Insert(newOffer);
        helper.cwv_validateFieldsIfClosedWon(newOffer);
    }

    public override void andFinally() {
        if (!helper.contractUpdateMap.isEmpty()) {
            lstUpdate.addAll(helper.contractUpdateMap.values());
        }
        if (!helper.pcUpdateMap.isEmpty()) {
            lstUpdate.addAll(helper.pcUpdateMap.values());
        }

        if (!lstUpdate.isEmpty()) {
            update (lstUpdate);
        }

        if (!helper.contentDocumentLinksToInsert.isEmpty()) {
            lstInsert.addAll(helper.contentDocumentLinksToInsert);
        }

        if (!lstInsert.isEmpty()) {
            insert lstInsert;
        }
    }
}
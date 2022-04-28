/****************************************************************************************************
 * Class OfferHelper
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2021-07-29
 *   Description	:	chd_ - Contract Historical Data (Files needs to be pushed from Offer to Resulting Contract)
 *                      eco_ - close lost of type extra ordinary needs special handling (contracts and pricing
 *                              need to be shortened etc.)
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2021-07-29       	Init version.
 *****************************************************************************************************/

public without sharing class OfferHelper {
    //Trigger Maps/Lists
    private List<Offer__c> triggerOld;
    private List<Offer__c> triggerNew;
    private Map<Id, Offer__c> oldMap;
    private Map<Id, Offer__c> newMap;

    public OfferHelper(
            List<Offer__c> oldList,
            List<Offer__c> newList,
            Map<Id, Offer__c> mapOld,
            Map<Id, Offer__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //Statics
    public static final Id OFFER_PPA_EXTENSION_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Extension').Id;
    public static final Id OFFER_PPA_NEGOTIATION_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Negotiation').Id;
    private static final String OFFER_FRAMEWORK_AGREEMENT = 
            'Framework Agreement';
    private Map<String, Schema.FieldSet> OFFER_FIELDSETS_BY_DEVELOPERNAME;

    //SOQL Maps from bulk. Important: Only ever use one Map per SObject Type!
    private Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
    private Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>();
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Pricing_Component__c> pcMap = new Map<Id, Pricing_Component__c>();

    //DML Lists and Maps. Important only ever use one Map/List per SObject Type and DML operation!
    public List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
    public Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();
    public Map<Id, Pricing_Component__c> pcUpdateMap = new Map<Id, Pricing_Component__c>();

    //Variables for Contract Historical Data
    private Set<Id> chd_offersWithNewResultingContract = new Set<Id>();
    private Set<Id> chd_newResultingContractIds = new Set<Id>();
    private Set<Id> chd_offerContentDocumentIds = new Set<Id>();
    private Set<Id> chd_contractContentDocumentIds = new Set<Id>();
    private Map<Id, Set<Id>> chd_offerIdToContentDocumentIds = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>> chd_contractIdToContentDocumentIds = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>> chd_offerIdToHistoricalDataContentDocumentsId = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>> chd_contractIdToHistoricalDataContentDocumentsId = new Map<Id, Set<Id>>();

    //Variables for Extraordinary Cancellation of Offer
    private Set<Id> eco_baseContractIds = new Set<Id>();
    private ListMapContainer eco_contractIdToPCs = new ListMapContainer(Pricing_Component__c.SObjectType);

    public void load_ContentDocumentLinks() {
        if (!chd_offersWithNewResultingContract.isEmpty()) {
            cdlMap = new Map<Id, ContentDocumentLink>([
                    SELECT ContentDocumentId, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :chd_offersWithNewResultingContract
                    OR LinkedEntityId IN :chd_newResultingContractIds
            ]);
        }
    }

    public void load_ContentVersions() {
        if (!chd_offerContentDocumentIds.isEmpty()) {
            cvMap = new Map<Id, ContentVersion>([
                    SELECT Attachement_Type__c, ContentDocumentId
                    FROM ContentVersion
                    WHERE (ContentDocumentId IN :chd_offerContentDocumentIds
                    OR ContentDocumentId IN :chd_contractContentDocumentIds)
                    AND Attachement_Type__c = 'Historical Data'
            ]);
        }
    }

    public void load_Contracts() {
        if (!eco_baseContractIds.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, End_Date__c, Termination_Status__c, Contract_s_Termination_Reason__c
                    FROM Contract__c
                    WHERE Id IN :eco_baseContractIds
            ]);
        }
    }

    public void load_PricingComponents() {
        if (!eco_baseContractIds.isEmpty()) {
            pcMap = new Map<Id, Pricing_Component__c>([
                    SELECT Id, End_Date__c, Contract__c, Contract__r.End_Date__c, RecordTypeId, Start_Date__c
                    FROM Pricing_Component__c
                    WHERE Contract__c IN :eco_baseContractIds
                    ORDER BY End_Date__c DESC
            ]);
        }
    }

    public void cdh_identifyOffersWithSwitchingResultingContract() {
        for (Offer__c newOffer : newMap.values()) {
            if (newOffer.Resulting_Contract__c != null
                    && oldMap.get(newOffer.Id).Resulting_Contract__c != newOffer.Resulting_Contract__c) {
                chd_offersWithNewResultingContract.add(newOffer.Id);
                chd_newResultingContractIds.add(newOffer.Resulting_Contract__c);
            }
        }
    }

    public void chd_buildCDLDataModel() {
        if (!chd_offersWithNewResultingContract.isEmpty() && !cdlMap.isEmpty()) {
            List<ContentDocumentLink> allRelevantOfferDocumentLinks = new List<ContentDocumentLink>();
            List<ContentDocumentLink> allRelevantContractDocumentLinks = new List<ContentDocumentLink>();
            for (ContentDocumentLink linkItem : cdlMap.values()) {
                if (linkItem.LinkedEntityId.getSobjectType() == Offer__c.SObjectType) {
                    allRelevantOfferDocumentLinks.add(linkItem);
                } else if (linkItem.LinkedEntityId.getSobjectType() == Contract__c.SObjectType) {
                    allRelevantContractDocumentLinks.add(linkItem);
                }
            }
            for (ContentDocumentLink linkItem : allRelevantOfferDocumentLinks) {
                chd_offerContentDocumentIds.add(linkItem.ContentDocumentId);
                msLepton.addToMap(linkItem.LinkedEntityId, linkItem.ContentDocumentId, chd_offerIdToContentDocumentIds);
            }
            for (ContentDocumentLink linkItem : allRelevantContractDocumentLinks) {
                chd_contractContentDocumentIds.add(linkItem.ContentDocumentId);
                msLepton.addToMap(linkItem.LinkedEntityId, linkItem.ContentDocumentId, chd_contractIdToContentDocumentIds);
            }
        }
    }

    public void chd_buildCVDataModel() {
        if (!cvMap.isEmpty()) {
            Set<Id> historicalDataContentDocumentIds = new Set<Id>();
            for (ContentVersion versionItem : cvMap.values()) {
                if (versionItem.Attachement_Type__c == 'Historical Data') {
                    historicalDataContentDocumentIds.add(versionItem.ContentDocumentId);
                }
            }

            for (Id offerId : chd_offerIdToContentDocumentIds.keySet()) {
                for (Id contentDocumentId : chd_offerIdToContentDocumentIds.get(offerId)) {
                    if (historicalDataContentDocumentIds.contains(contentDocumentId)) {
                        msLepton.addToMap(offerId, contentDocumentId, chd_offerIdToHistoricalDataContentDocumentsId);
                    }
                }
            }
            for (Id contractId : chd_contractIdToContentDocumentIds.keySet()) {
                for (Id contentDocumentId : chd_contractIdToContentDocumentIds.get(contractId)) {
                    if (historicalDataContentDocumentIds.contains(contentDocumentId)) {
                        msLepton.addToMap(contractId, contentDocumentId, chd_contractIdToHistoricalDataContentDocumentsId);
                    }
                }
            }
        }
    }

    public void chd_ifContractChangedPassHistoricalData(Offer__c oldOffer, Offer__c newOffer) {
        List<ContentDocumentLink> historicalDataContentDocumentLinksToInsert = new List<ContentDocumentLink>();
        if (newOffer.Resulting_Contract__c != oldOffer.Resulting_Contract__c
                && newOffer.Resulting_Contract__c != null
                && chd_offerIdToHistoricalDataContentDocumentsId.containsKey(newOffer.Id)) {
            for (Id historicalDataContentDocumentId : chd_offerIdToHistoricalDataContentDocumentsId.get(newOffer.Id)) {
                if (newOffer.Resulting_Contract__c != null
                        && (!chd_contractIdToHistoricalDataContentDocumentsId.containsKey(newOffer.Resulting_Contract__c)
                        || !chd_contractIdToHistoricalDataContentDocumentsId.get(newOffer.Resulting_Contract__c)
                        .contains(historicalDataContentDocumentId))) {
                    historicalDataContentDocumentLinksToInsert.add(
                            new ContentDocumentLink(
                                    LinkedEntityId = newOffer.Resulting_Contract__c,
                                    ContentDocumentId = historicalDataContentDocumentId
                            )
                    );
                    msLepton.addToMap(
                            newOffer.Resulting_Contract__c,
                            historicalDataContentDocumentId,
                            chd_contractIdToHistoricalDataContentDocumentsId
                    );
                }
            }
            for (ContentDocumentLink cdlToInsert : historicalDataContentDocumentLinksToInsert) {
                Boolean matched = false;
                for (ContentDocumentLink cdlInInsertList : contentDocumentLinksToInsert) {
                    if (cdlToInsert.ContentDocumentId == cdlInInsertList.ContentDocumentId
                            && cdlToInsert.LinkedEntityId == cdlInInsertList.LinkedEntityId) {
                        matched = true;
                    }
                }
                if (!matched) {
                    contentDocumentLinksToInsert.add(cdlToInsert);
                }
            }
        }
    }

    public void eco_identifyRelevantOfferContractsInsert() {
        for (Offer__c offerItem : triggerNew) {
            if (eco_offerIsExtraOrdinaryClosure(offerItem) || eco_offerIsUnknownClosure(offerItem)) {
                eco_baseContractIds.add(offerItem.Base_Contract__c);
            }
        }
    }

    public void eco_identifyRelevantOfferContractsUpdate() {
        for (Offer__c offerItem : triggerNew) {
            if ((eco_offerIsExtraOrdinaryClosure(offerItem) || eco_offerIsUnknownClosure(offerItem))
                    && eco_offerHasRelevantFieldChanges(oldMap.get(offerItem.Id), offerItem)) {
                eco_baseContractIds.add(offerItem.Base_Contract__c);
            }
        }
    }

    private Boolean eco_offerHasRelevantFieldChanges(Offer__c oldOffer, Offer__c newOffer) {
        return oldOffer.Status__c != newOffer.Status__c
                || oldOffer.Contract_s_Termination_Reason__c != newOffer.Contract_s_Termination_Reason__c
                || oldOffer.Country__c != newOffer.Country__c
                || oldOffer.Workflow_Type__c != newOffer.Workflow_Type__c
                || oldOffer.Base_Contract__c != newOffer.Base_Contract__c;
    }

    private Boolean eco_offerIsExtraOrdinaryClosure(Offer__c offer) {
        return offer.Contract_s_Termination_Reason__c == 'Extraordinary'
                && offer.Status__c == 'Closed Lost'
                && offer.Country__c == 'Germany'
                && offer.Workflow_Type__c == 'Amendment'
                && offer.Base_Contract__c != null
                && offer.RecordTypeId == OFFER_PPA_EXTENSION_REC_TYPE_ID;
    }
    private Boolean eco_offerIsUnknownClosure(Offer__c offer) {
        return offer.Contract_s_Termination_Reason__c == null
                && offer.Status__c == 'Closed Lost'
                && offer.Country__c == 'Germany'
                && offer.Workflow_Type__c == 'Amendment'
                && offer.Base_Contract__c != null
                && offer.RecordTypeId == OFFER_PPA_EXTENSION_REC_TYPE_ID;
    }

    public void eco_buildDataModel() {
        if (!eco_baseContractIds.isEmpty() && !pcMap.isEmpty()) {
            for (Pricing_Component__c pcItem : pcMap.values()) {
                if (eco_baseContractIds.contains(pcItem.Contract__c)) {
                    if (pcItem.End_Date__c == pcItem.Contract__r.End_Date__c) {
                        eco_contractIdToPCs.addToMap(pcItem.Contract__c, pcItem);
                    }
                }
            }
        }
    }

    public void eco_updateContract_Insert(Offer__c newOffer) {
        if (eco_offerIsExtraOrdinaryClosure(newOffer) || eco_offerIsUnknownClosure(newOffer)) {
            eco_calculateContractUpdate(newOffer);
        }
    }

    public void eco_updateContract_Update(Offer__c oldOffer, Offer__c newOffer) {
        if ((eco_offerIsExtraOrdinaryClosure(newOffer)
                || eco_offerIsUnknownClosure(newOffer))
                && eco_offerHasRelevantFieldChanges(oldOffer, newOffer)) {
            eco_calculateContractUpdate(newOffer);
        }
    }

    private void eco_calculateContractUpdate(Offer__c newOffer) {
        Contract__c relevantContract = contractMap.get(newOffer.Base_Contract__c);
        Boolean changed = false;
        if (relevantContract.Termination_Status__c != newOffer.Resulting_Termination_Status__c) {
            relevantContract.Termination_Status__c = newOffer.Resulting_Termination_Status__c;
            changed = true;
        }
        if (eco_offerIsExtraOrdinaryClosure(newOffer)) {
            if (relevantContract.Contract_s_Termination_Reason__c != newOffer.Contract_s_Termination_Reason__c) {
                relevantContract.Contract_s_Termination_Reason__c = newOffer.Contract_s_Termination_Reason__c;
                changed = true;
            }
            if (relevantContract.End_Date__c != newOffer.Contract_End_Date_Offer__c) {
                relevantContract.End_Date__c = newOffer.Contract_End_Date_Offer__c;
                changed = true;
            }
        }

        if (changed) {
            contractUpdateMap.put(relevantContract.Id, relevantContract);
        }
    }

    public void eco_updatePCsIfNecessary_Update(Offer__c oldOffer, Offer__c newOffer) {
        if (eco_offerHasRelevantFieldChanges(oldOffer, newOffer)
                && eco_offerIsExtraOrdinaryClosure(newOffer)
                && eco_contractIdToPCs.containsKey(newOffer.Base_Contract__c)) {
            eco_updatePricingComponents(newOffer);
        }
    }

    public void eco_updatePCsIfNecessary_Insert(Offer__c newOffer) {
        if (eco_offerIsExtraOrdinaryClosure(newOffer)
                && eco_contractIdToPCs.containsKey(newOffer.Base_Contract__c)) {
            eco_updatePricingComponents(newOffer);
        }
    }

    private void eco_updatePricingComponents(Offer__c newOffer) {
        List<Pricing_Component__c> pricingComponentsToEndDate = eco_contractIdToPCs.get(newOffer.Base_Contract__c);
        for (Pricing_Component__c pcItem : pricingComponentsToEndDate) {
            if (pcItem.End_Date__c != newOffer.Contract_End_Date_Offer__c) {
                pcItem.End_Date__c = newOffer.Contract_End_Date_Offer__c;
                pcUpdateMap.put(pcItem.Id, pcItem);
            }
        }
    }

    //Offer Closed Won Validation
    public void cwv_validateFieldsIfClosedWon(Offer__c newOffer) {
        if (cwv_isValidationRelevant(newOffer)) {
            if (OFFER_FIELDSETS_BY_DEVELOPERNAME == null) {
                OFFER_FIELDSETS_BY_DEVELOPERNAME = FieldSetCachedProvider.getBySObjectType(SObjectType.Offer__c);
            }
            Boolean throwError = false;

            String validationIdentifier = 'cwv_' + Application.RecordTypes.byId(newOffer.RecordTypeId).DeveloperName;
            if(newOffer.Contract_Type_New__c == 'Framework Agreement') {
                validationIdentifier += '_FWA';
            }

            throwError = cwv_checkOfferForEmptyFields(
                newOffer, 
                OFFER_FIELDSETS_BY_DEVELOPERNAME.get(validationIdentifier).getFields()
                );

            if (throwError) {
                newOffer.addError(Label.Offer_Validation_Record_Level_Error);
            }
        }
    }

    public Boolean cwv_checkOfferForEmptyFields(Offer__c offerToCheck, List<Schema.FieldSetMember> fieldsToCheck){
        Boolean emptyFieldDetected = false;
        for (Schema.FieldSetMember field : fieldsToCheck) {
            if (offerToCheck.get(field.getFieldPath()) == null) {
                offerToCheck.addError(field.getFieldPath(), Label.Offer_Validation_Field_Level_Error);
                emptyFieldDetected = true;
            }
        }
        return emptyFieldDetected;
    }

    public void cwv_validateFieldsIfClosedWon(Offer__c oldOffer, Offer__c newOffer) {
        if (cwv_isValidationRelevantUpdate(oldOffer, newOffer)) {
            cwv_validateFieldsIfClosedWon(newOffer);
        }
    }

    private Boolean cwv_isValidationRelevant(Offer__c newOffer) {
        return newOffer.Workflow_Type__c != 'Auto-Extension'
                && newOffer.Country__c == 'Germany'
                && newOffer.Status__c == 'Closed Won'
                && (newOffer.RecordTypeId == OFFER_PPA_NEGOTIATION_REC_TYPE_ID
                || newOffer.RecordTypeId == OFFER_PPA_EXTENSION_REC_TYPE_ID);
    }

    private Boolean cwv_isValidationRelevantUpdate(Offer__c oldOffer, Offer__c newOffer) {
        return oldOffer.Status__c != 'Closed Won' && newOffer.Status__c == 'Closed Won';
    }
}
/****************************************************************************************************
 * Class msBrytSendConfController
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 21.01.2019
 *   Description : Controller for the msBrytSendConf Visualforce page
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	21.01.2019	Init version.
 *****************************************************************************************************/
public with sharing class msBrytSendConfController {

    public List<Pricing_Component__c> pcList { get; set; }
    public List<List<Pricing_Component__c>> formattedListPricingComponents { get; set; }

    public msBrytSendConfController() {
        pcList = getPricingComponents();
        formattedListPricingComponents = getFormattedPricingComponents();
    }

    @AuraEnabled
    public static List<Pricing_Component__c> getPricingComponents() {
        String listOfIdsByConcatenation;
        String[] splitIds;
        List<String> pcIdList = new List<String>();
        List<Pricing_Component__c> pcList = new List<Pricing_Component__c>();
        try {
            listOfIdsByConcatenation = ApexPages.currentPage().getParameters().get('listOfIdsByConcatenation');
            splitIds = listOfIdsByConcatenation.split('\\.');
            for (String pcItem : splitIds) {
                pcItem.remove('.');
                pcItem.remove('null');
                pcIdList.add(pcItem);
            }
            pcList = [
                    SELECT
                            Id,
                            Name,
                            msBrytTransactionType__c,
                            msBrytProduct_Name__c,
                            Value__c,
                            Fixed_Volume__c,
                            CreatedBy.FirstName,
                            CreatedBy.LastName,
                            Contract__r.Contract_Holder__r.Name,
                            CreatedDate
                    FROM Pricing_Component__c
                    WHERE Id IN :pcIdList
            ];
        } catch (Exception e) {
            Pricing_Component__c failure = new Pricing_Component__c();
            failure.msBrytProduct_Name__c = 'The Query failed';
            pcList.add(failure);
        }
        for (Pricing_Component__c pcItem : pcList) {
            if (pcItem.Fixed_Volume__c != null) {
                pcItem.Fixed_Volume__c = Math.abs(pcItem.Fixed_Volume__c);
            } else {
                pcItem.Fixed_Volume__c = 0;
            }

            if ((pcItem.CreatedBy.FirstName != null
                    && pcItem.CreatedBy.FirstName.contains('Pixos'))
                    || (pcItem.CreatedBy.LastName != null
                    && pcItem.CreatedBy.LastName.contains('Pixos'))) {
                pcItem.CreatedBy.FirstName = 'System';
                pcItem.CreatedBy.LastName = '';
            }
        }
        return pcList;
    }

    @AuraEnabled
    public List<List<Pricing_Component__c>> getFormattedPricingComponents() {
        Integer counterRows = 0;
        List<List<Pricing_Component__c>> formattedListPricingComponents = new List<List<Pricing_Component__c>>();
        List<Pricing_Component__c> sublistPricingComponents = new List<Pricing_Component__c>();
        for (Pricing_Component__c pcItem : pcList) {
            sublistPricingComponents.add(pcItem);
            counterRows++;
            if (counterRows == 15) {
                formattedListPricingComponents.add(sublistPricingComponents);
                sublistPricingComponents = new List<Pricing_Component__c>();
                counterRows = 0;
            }
        }
        if (counterRows != 0) {
            formattedListPricingComponents.add(sublistPricingComponents);
        }
        return formattedListPricingComponents;
    }
}
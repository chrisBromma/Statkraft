/****************************************************************************************************
 * Class msBrytTradeConfPDFController
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 22.01.2019
 *   Description : Controller for the msBrytTradeConfPDF Visualforce page
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	22.01.2019	Init version.
 *****************************************************************************************************/

public without sharing class msBrytTradeConfPDFController {
    public String accName { get; set; }
    public List<Pricing_Component__c> pcList { get; set; }
    public String userId { get; set; }
    public List<List<Pricing_Component__c>> formattedListPricingComponents { get; set; }
    public String userName { get; set; }


    public msBrytTradeConfPDFController() {
        accName = getAccountName();
        pcList = getPricingComponents();
        userId = getUserId();
        userName = getUserName();
        formattedListPricingComponents = getFormattedPricingComponents();
        String exportTime = Datetime.now().format();
        String fileName = 'attachment; filename=Trade_Confirmation:_' + pcList[0].Contract__r.Name + '---' + exportTime + '.pdf';
        ApexPages.currentPage().getHeaders().put('content-disposition', fileName);

    }
    @AuraEnabled
    public static String getUserId() {
        String userId;

        userId = ApexPages.currentPage().getParameters().get('userId');
        if (userId == null) {
            userId = 'failed to catch UserId';
        }
        return userId;
    }
    @AuraEnabled
    public static String getUserName() {
        String userId;
        String userName;
        userId = ApexPages.currentPage().getParameters().get('userId');

        if (userId != null) {
            User queryUser = [SELECT Name FROM User WHERE Id = :userId LIMIT 1];
            userName = queryUser.Name;
        } else {
            userName = 'failed to catch UserId';
        }
        return userName;
    }
    @AuraEnabled
    public static String getAccountName() {
        Id userId;
        String accName;
        userId = ApexPages.currentPage().getParameters().get('userId');
        if (userId != null) {
            User userAcc = [SELECT Name, Account.Name FROM User WHERE Id = :userId LIMIT 1];
            accName = userAcc.Account.Name;
        } else {
            accName = 'failed to find Account';
        }
        return accName;
    }
    @AuraEnabled
    public static List<Pricing_Component__c> getPricingComponents() {
        Id userId;
        List<Pricing_Component__c> pcList = new List<Pricing_Component__c>();
        userId = ApexPages.currentPage().getParameters().get('userId');
        if (userId != null) {
            pcList = [
                    SELECT
                            Id,
                            Contract__r.Name,
                            Name,
                            msBrytTransactionType__c,
                            msBrytProduct_Name__c,
                            Value__c,
                            Fixed_Volume__c,
                            CreatedDate,
                            CreatedBy.FirstName,
                            CreatedBy.LastName,
                            Contract__r.Contract_Holder__r.Name
                    FROM Pricing_Component__c
                    WHERE CreatedById = :userId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
        } else {
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
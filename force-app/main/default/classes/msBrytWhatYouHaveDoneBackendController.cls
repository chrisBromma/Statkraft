/****************************************************************************************************
* Class msBrytWhatsGoingOnController
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:   29.11.2018
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)       29.11.2018      	    Init version.
*****************************************************************************************************/

public without sharing class msBrytWhatYouHaveDoneBackendController {

    @AuraEnabled
    public List<Pricing_Component__c> getUserDetails { get; set; }
    public String username { get; set; }
    public String accName { get; set; }
    public Date endDate { get; set; }
    public Date startDate { get; set; }
    public String blankString { get; set; }
    public String selectedContract { get; set; }
    public List<List<Pricing_Component__c>> formattedListPricingComponents { get; set; }
    public String contractName { get; set; }

    public msBrytWhatYouHaveDoneBackendController() {

        username = getUsername();
        accName = getAccountName();
        endDate = getEndDate();
        startDate = getStartDate();

        if (startDate == Date.newInstance(1900, 01, 01)) {
            startDate = null;
        }
        if (endDate == Date.newInstance(9999, 12, 31)) {
            endDate = null;
        }

        String selectedContract = ApexPages.currentPage().getParameters().get('selectedContract');
        getUserDetails = queryPricingComponents(selectedContract);
        blankString = '.';
        formattedListPricingComponents = getformattedPricingComponents(getUserDetails);
        contractName = getContractName();

        if (ApexPages.currentPage() != null) {

            String exportTime = Datetime.now().format();
            String fileName = 'attachment; filename=Trading_History:_' + contractName + '---' + exportTime + '.pdf';
            ApexPages.currentPage().getHeaders().put('content-disposition', fileName);
        }
    }

    @AuraEnabled
    public static String getSessionUser() {

        String sessionUser = UserInfo.getUserId();
        return sessionUser;
    }

    @AuraEnabled
    public static String getUsername() {

        String userId = getSessionUser();
        List<User> queryuser = [SELECT Name FROM User WHERE Id = :userId];
        String username = queryuser[0].Name;

        return username;
    }

    @AuraEnabled
    public static String getAccountName() {

        String userId = getSessionUser();
        List<User> queryacc = [SELECT Name, Account.Name FROM User WHERE Id = :userId];
        String accName = queryacc[0].Account.Name;

        return accName;
    }

    @AuraEnabled
    public static Date getStartDate() {

        String startDateStr;
        Date startDate;
        try {
            startDateStr = ApexPages.currentPage().getParameters().get('startDate');
            startDate = Date.valueOf(startDateStr);

        } catch (Exception e) {
            startDate = Date.newInstance(1900, 01, 01);
        }

        return startDate;
    }

    @AuraEnabled
    public static Date getEndDate() {

        String endDateStr;
        Date endDate;
        try {
            endDateStr = ApexPages.currentPage().getParameters().get('endDate');
            endDate = Date.valueOf(endDateStr);
        } catch (Exception e) {
            endDate = Date.newInstance(9999, 12, 31);
        }
        return endDate;
    }

    @AuraEnabled
    public static User getUserId() {

        String sessionUser = getSessionUser();

        User userId = [
                SELECT Name, FirstName, Profile.Name, ContactId
                FROM User
                WHERE Id = :sessionUser
                LIMIT 1
        ];
        return userId;
    }

    @AuraEnabled
    public static List<Pricing_Component__c> queryPricingComponents(String selectedContract) {
        msBrytUtility.checkObjectAccess(selectedContract);
        if (selectedContract != null && selectedContract != '0') {
            // Variable initialization
            String startDateStr;
            String endDateStr;
            Date startDate;
            Date endDate;
            Datetime endDatetime;

            try {
                startDateStr = ApexPages.currentPage().getParameters().get('startDate');
                startDate = Date.valueOf(startDateStr);


            } catch (Exception e) {
                // When startDate is not found, set it to wide range.
                startDate = Date.newInstance(1900, 01, 01);

            }
            try {
                endDateStr = ApexPages.currentPage().getParameters().get('endDate');
                endDate = Date.valueOf(endDateStr);

            } catch (Exception e) {
                // When endDate is not found, set it to wide range.
                endDate = Date.newInstance(9999, 12, 31);
            }

            endDatetime = Datetime.newInstanceGmt(endDate, Time.newInstance(23, 59, 59, 999));
            List<Pricing_Component__c> pricingComponents = [
                    SELECT Id,
                            Name,
                            Contract__r.Id,
                            Contract__r.Name,
                            Start_Date__c,
                            End_Date__c,
                            Contract__r.Bryt_Product_Name__c,
                            Contract__r.Billing_Type__c,
                            CreatedBy.FirstName,
                            CreatedBy.LastName,
                            CreatedBy.Name,
                            Fixed_Volume__c,
                            Value__c,
                            msBrytProduct_Name__c,
                            CreatedDate,
                            msBrytTransactionType__c,
                            msBrytIsDeactivated__c,
                            RecordTypeId
                    FROM Pricing_Component__c
                    WHERE Contract__r.Id = :selectedContract
                    AND CreatedDate >= :startDate
                    AND CreatedDate <= :endDatetime
                    AND msBrytIsDeactivated__c = FALSE
                    ORDER BY CreatedDate DESC
            ];

            for (Pricing_Component__c pcItem : pricingComponents) {
                pcItem.Fixed_Volume__c = Math.abs(pcItem.Fixed_Volume__c);
                if(pcItem.CreatedBy.FirstName.contains('Pixos') || pcItem.CreatedBy.LastName.contains('Pixos')) {
                    pcItem.CreatedBy.FirstName = 'System';
                    pcItem.CreatedBy.LastName = '';
                }
            }
            return pricingComponents;

        } else {
            return null;
        }
    }

    @AuraEnabled
    public static List<List<Pricing_Component__c>> getFormattedPricingComponents(List<Pricing_Component__c> getUserDetails) {
        Integer counterRows = 0;
        List<List<Pricing_Component__c>> formattedListPricingComponents = new List<List<Pricing_Component__c>>();
        List<Pricing_Component__c> sublistPricingComponents = new List<Pricing_Component__c>();
        for (Pricing_Component__c pcItem : getUserDetails) {
            sublistPricingComponents.add(pcItem);
            counterRows++;
            if (counterRows == 20) {
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
    @AuraEnabled
    public String getContractName() {
        if (!getUserDetails.isEmpty()) {
            return getUserDetails[0].Contract__r.Name;
        } else {
            return '';
        }
    }
}
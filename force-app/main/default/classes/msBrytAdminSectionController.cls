public without sharing class msBrytAdminSectionController {

    public static final Date TRADES_START_DATE = Date.newInstance(1900, 01, 01);
    public static final Date TRADES_END_DATE = Date.newInstance(9999, 12, 31);
    public static final Id BRYT_CONTRACT_RECORD_TYPE_ID = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
    public static final Id BRYT_CONTRACT_ROLE_RECORD_TYPE_ID = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
    public static final Id BRYT_PRICING_COMPONENT_RECORD_TYPE_ID = Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Bryt_Pricing_Component').getRecordTypeId();
    public static final String BRYT_PROFILE_NAME = 'Bryt Customer Community User';

    public List<Pricing_Component__c> getPricingComponents { get; set; }
    public String username { get; set; }
    public Date endDate { get; set; }
    public Date startDate { get; set; }
    public String contractName { get; set; }

    public msBrytAdminSectionController() {
        username = getUsername();
        endDate = getEndDate();
        startDate = getStartDate();
        contractName = getContractName();

        if (startDate == TRADES_START_DATE) {
            startDate = null;
        }
        if (endDate == TRADES_END_DATE) {
            endDate = null;
        }

        String selectedContract = ApexPages.currentPage().getParameters().get('selectedContract');
        getPricingComponents = queryPricingComponents(selectedContract);
    }

    @AuraEnabled
    public static PricingComponentsWrapper getPricingComponentsWrapper() {
        PricingComponentsWrapper result = new PricingComponentsWrapper();
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {

            result.trades = [
                    SELECT
                            Id,
                            Name,
                            Contract__r.Name,
                            Start_Date__c,
                            End_Date__c,
                            Contract__r.Bryt_Product_Name__c,
                            Contract__r.Billing_Type__c,
                            CreatedBy.FirstName,
                            CreatedBy.LastName,
                            Fixed_Volume__c,
                            Value__c,
                            msBrytProduct_Name__c,
                            CreatedDate,
                            msBrytTransactionType__c,
                            msBrytIsDeactivated__c
                    FROM Pricing_Component__c
                    WHERE RecordTypeId = :BRYT_PRICING_COMPONENT_RECORD_TYPE_ID
                    AND CreatedDate >= :TRADES_START_DATE
                    AND CreatedDate <= :TRADES_END_DATE
                    AND Contract__c IN :userDetails.tpiContracts
                    AND msBrytIsDeactivated__c = FALSE
                    ORDER BY CreatedDate DESC
            ];

            for (Pricing_Component__c pcItem : result.trades) {
                pcItem.Fixed_Volume__c = Math.abs(pcItem.Fixed_Volume__c);
                if(pcItem.CreatedBy.FirstName.contains('Pixos') || pcItem.CreatedBy.LastName.contains('Pixos')) {
                    pcItem.CreatedBy.FirstName = 'System';
                    pcItem.CreatedBy.LastName = '';
                }
            }
            return result;
        } else {
            return new PricingComponentsWrapper();
        }
    }

    public static List<Pricing_Component__c> queryPricingComponents(String contractId) {
        String queryString;
        String startDateStr;
        String endDateStr;
        Date startDate;
        Date endDate;
        Datetime endDatetime;
        Datetime startDatetime;
        try {
            startDateStr = ApexPages.currentPage().getParameters().get('startDate');
            startDate = Date.valueOf(startDateStr);

        } catch (Exception e) {
            // When startDate is not found, set it to wide range.
            startDate = TRADES_START_DATE;

        }
        try {
            endDateStr = ApexPages.currentPage().getParameters().get('endDate');
            endDate = Date.valueOf(endDateStr);

        } catch (Exception e) {
            // When ednDate is not found, set it to wide range.
            endDate = TRADES_END_DATE;
        }
        endDatetime = Datetime.newInstanceGmt(endDate, Time.newInstance(23, 59, 59, 999));
        startDatetime = Datetime.newInstanceGmt(startDate, Time.newInstance(0, 0, 0, 0));

        queryString = 'SELECT CreatedBy.Name,Fixed_Volume__c,Value__c,msBrytProduct_Name__c,CreatedDate,msBrytTransactionType__c ';
        queryString += 'FROM Pricing_Component__c ';
        queryString += 'WHERE msBrytIsDeactivated__c = FALSE ';
        queryString += 'AND RecordTypeId = \'' + BRYT_PRICING_COMPONENT_RECORD_TYPE_ID + '\' ';
        if (contractId != null && contractId != '0') {
            queryString += 'AND Contract__c = \'' + contractId + '\' ';
        }
        queryString += 'AND CreatedDate >= ' + startDatetime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ';
        queryString += 'AND CreatedDate <= ' + endDatetime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ' ';
        queryString += 'ORDER BY CreatedDate DESC ';
        queryString += 'LIMIT 10000 ';

        return Database.query(queryString);
    }

    public static String getUsername() {
        return [SELECT Name FROM User WHERE Id = :UserInfo.getUserId()].Name;
    }

    public static Date getStartDate() {
        String startDateStr;
        Date startDate;
        try {
            startDateStr = ApexPages.currentPage().getParameters().get('startDate');
            startDate = Date.valueOf(startDateStr);

        } catch (Exception e) {
            startDate = TRADES_START_DATE;
        }

        return startDate;
    }

    public static Date getEndDate() {

        String endDateStr;
        Date endDate;
        try {
            endDateStr = ApexPages.currentPage().getParameters().get('endDate');
            endDate = Date.valueOf(endDateStr);
        } catch (Exception e) {
            endDate = TRADES_END_DATE;
        }
        return endDate;
    }

    public static String getContractName() {
        String contractId = ApexPages.currentPage().getParameters().get('selectedContract');
        if (contractId == '0') {
            return 'All';
        } else {
            return [SELECT Name FROM Contract__c WHERE Id = :contractId].Name;
        }

    }

    @AuraEnabled
    public static List<msBrytUtility.PortalUserWrapper> refreshPortalUserWrappers() {
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isTPI || userDetails.isAdmin) {
            List<msBrytUtility.PortalUserWrapper> portalUserWrappers = msBrytUtility.getPortalUserWrappers(userDetails);

            userDetails.portalUserWrappers = portalUserWrappers;
            try {
                Cache.Session.put('local.PortalCache.userDetails', userDetails, 600);
            } catch (Cache.Session.SessionCacheException e) {
                System.debug(e.getMessage());
            }

            return portalUserWrappers;
        } else {
            return new List<msBrytUtility.PortalUserWrapper>();
        }
    }


    public class PricingComponentsWrapper {
        @AuraEnabled public List<Pricing_Component__c> trades { get; set; }
        @AuraEnabled public List<Contract__c> contracts { get; set; }
    }

    public class ContractWrapper {
        @AuraEnabled public Contract__c contract { get; set; }
        @AuraEnabled public List<Bryt_Reference_Capacity__c> referenceCapacities { get; set; }
        @AuraEnabled public List<Contract_Role__c> relatedRoles { get; set; }
        @AuraEnabled public Boolean showContractRoles { get; set; }
    }
}
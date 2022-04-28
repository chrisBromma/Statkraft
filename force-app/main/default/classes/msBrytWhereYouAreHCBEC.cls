/****************************************************************************************************
 * Class msBrytWhereYouAreHCBEC
 *
 *   Create By	 : Fabian Kramer (mindsquare GmbH)
 *   Create Date : 03.01.2019
 *   Description :  -
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Kramer (mindsquare GmbH)	    03.01.2019	Init version.
 *   * Georg Luch                           23.06.2020  Refactoring. Calculation in APEX not in JS
 *****************************************************************************************************/

public with sharing class msBrytWhereYouAreHCBEC {
    public static final Id PricingComponentRecId = Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Bryt_Pricing_Component').getRecordTypeId();
    public static final Integer DEFAULT_NUMBER_OF_SHOWN_MONTHS = 12;

    @AuraEnabled
    public static List<monthWrapper> createMonthWrappers(Id contractId) {
        msBrytUtility.checkObjectAccess(contractId);

        Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>(msBrytUtility.getUserDetails().contracts);
        Contract__c selectedContract = contractMap.get(contractId);
        //Date startDate = Date.today().toStartOfMonth();//selectedContract.Start_Date__c;
        Date startDate = selectedContract.Start_Date__c;
        Date endDate = selectedContract.End_Date__c;

        Map<Date, monthWrapper> dateToProductWrapperMap = new Map<Date, monthWrapper>();

        List<Pricing_Component__c> pricingComponents = [
                SELECT Id, Fixed_Volume__c, Value__c, Start_Date__c, End_Date__c
                FROM Pricing_Component__c
                WHERE Contract__c = :contractId
                AND Start_Date__c <= :endDate
                AND End_Date__c > :startDate
                AND msBrytIsDeactivated__c = FALSE
                AND Fixed_Volume__c != NULL
                AND Value__c != NULL
                AND RecordTypeId = :PricingComponentRecId
        ];

        dateToProductWrapperMap = getProductsFromAPI(contractId, startDate, endDate);
        // This MAP will hold our calculated "Locked-Position" values.
        dateToProductWrapperMap = getReferenceCapacities(contractId, dateToProductWrapperMap, startDate, endDate);
        // For each month ...
        for (Date productStartDate : dateToProductWrapperMap.keySet()) {
            monthWrapper productItem = (monthWrapper) System.JSON.deserializeStrict(JSON.serialize(dateToProductWrapperMap.get(productStartDate)), monthWrapper.class);
            Decimal hoursInMonth = msBrytUtility.getHoursInMonth(productStartDate);
            // Reset the Locked-Position variable:
            Decimal lockedPositionOfMonthM = 0;
            for (Pricing_Component__c pcItem : pricingComponents) {
                if (pcItem.Start_Date__c <= productStartDate && productStartDate < pcItem.End_Date__c) {
                    lockedPositionOfMonthM += pcItem.Fixed_Volume__c * pcItem.Value__c * msBrytUtility.getHoursInMonth(productStartDate);
                }
            }
            // Save Locked-Position for each month in the MAP:
            // LockedPositionForAllGivenMonth.put(startMonthInMAP, LockedPositionOfMonthM); // Result: month, MW * Price * hours
            Decimal marked = lockedPositionOfMonthM;
            if (productItem.traded > 0) {

                lockedPositionOfMonthM = lockedPositionOfMonthM / productItem.traded;
                lockedPositionOfMonthM = lockedPositionOfMonthM / hoursInMonth;
                productItem.locked = lockedPositionOfMonthM.setScale(2);
            }

            if (productItem.offer != null && productItem.locked != null && productItem.traded != null) {
                marked += productItem.available * productItem.offer * hoursInMonth;
                marked = marked / (productItem.total * hoursInMonth);
                productItem.marked = marked.setScale(2);
            }

            productItem.startDate = productStartDate.format();
            productItem.month = productStartDate;
            dateToProductWrapperMap.put(productStartDate, productItem);
        }

        List<monthWrapper>results = new List<monthWrapper>();
        for (monthWrapper entry : dateToProductWrapperMap.values()) {
            if (entry.available != null) {
                results.add(entry);
            }
        }
        return results;
    }

    private static Map<Date, monthWrapper> getProductsFromAPI(Id contractId, Date startDate, Date endDate) {
        Map<Date, monthWrapper> dateToProductWrapperMap = new Map<Date, monthWrapper>();

        Map<Id, Contract__c> userContracts = new Map<Id, Contract__c>(msBrytUtility.getUserDetails().contracts);
        Contract__c contract = userContracts.get(contractId);
        List<String> parameterList = new List<String>();
        if (contract.Bryt_Tradable_Months__c != null) {
            parameterList.add('months=' + contract.Bryt_Tradable_Months__c);
        }
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        String contractStart = ('' + Datetime.newInstanceGmt(contract.Start_Date__c, Time.newInstance(0, 0, 0, 0))).replace(' ', 'T') + 'Z';
        String contractEnd = ('' + Datetime.newInstanceGmt(contract.End_Date__c, Time.newInstance(0, 0, 0, 0))).replace(' ', 'T') + 'Z';
        String endpoint = apiSettings.BrytWhereYouAreEndpoint__c + String.join(parameterList, '&') + '&startTime=' + contractStart + '&endTime=' + contractEnd + '&expiryDays=3';
        HttpResponse response = msUtility.getHttp(endpoint, null, 'GET', apiSettings.BrytApiKey__c);
        List<monthWrapper> productMonthWrappers = (List<monthWrapper>) System.JSON.deserializeStrict(response.getBody(), List<monthWrapper>.class);

        // Fill with nothing :) in order to debug easier API-issues later on ...
        for (Integer i = 0; i <= startDate.monthsBetween(endDate); i++) {
            monthWrapper expiredProductsPrices = new monthWrapper(); // Why 1? Because API does not return prices for expired products yet.
            expiredProductsPrices.available = 0; // Why 2? We are currently receiving NULL instead of 0 as a price.
            expiredProductsPrices.offer = 0; // Why 3?: Offer was never set in this script.
            dateToProductWrapperMap.put(startDate.addMonths(i), expiredProductsPrices);
        }
        for (monthWrapper productItem : productMonthWrappers) {
            if (endDate < Date.valueOf(productItem.startDate)) { // recieved product does not belong to the selected time frame
                continue;
            }

            Date tmpStart = Date.valueOf(productItem.startDate);
            Date tmpEnd = Date.valueOf(productItem.endDate);
            for (Integer i = 0; i <= tmpStart.monthsBetween(tmpEnd); i++) {
                Date key = Date.valueOf(productItem.startDate).addMonths(i);
                monthWrapper currentProduct = dateToProductWrapperMap.get(key);
                if ((currentProduct == null || currentProduct.endDate == null) || (currentProduct != null && Date.valueOf(currentProduct.endDate) > tmpEnd)) {
                    dateToProductWrapperMap.put(key, productItem);
                }
            }
        }

        return dateToProductWrapperMap;
    }

    private static Map<Date, monthWrapper> getReferenceCapacities(String contractId, Map<Date, monthWrapper> dateToProductWrapperMap, Date startDate, Date endDate) {
        // One capacity per month
        List<Bryt_Reference_Capacity__c> referenceCapacities = [
                SELECT Capacity_Off_Peak__c, Month__c, Name, Traded_Off_Peak__c
                FROM Bryt_Reference_Capacity__c
                WHERE Contract__c = :contractId
                AND Month__c >= :startDate
                AND Month__c <= :endDate
                ORDER BY Month__c ASC
        ];

        for (Bryt_Reference_Capacity__c refItem : referenceCapacities) {
            monthWrapper newWrapper = (monthWrapper) System.JSON.deserializeStrict(JSON.serialize(dateToProductWrapperMap.get(Date.valueOf(refItem.Month__c))), monthWrapper.class);
            if (newWrapper == null) {
                continue;
            }

            newWrapper.month = refItem.Month__c;
            newWrapper.startTime2 = newWrapper.month;
            newWrapper.available = refItem.Capacity_Off_Peak__c - refItem.Traded_Off_Peak__c;
            newWrapper.traded = refItem.Traded_Off_Peak__c;
            newWrapper.total = refItem.Capacity_Off_Peak__c;
            dateToProductWrapperMap.put(refItem.Month__c, newWrapper);
        }

        return dateToProductWrapperMap;
    }
    /*
    * Calculates the hours of a given month, taking summer/winter-time changes into account.
    * E.g. There are 23h/24h/ or 25h in some days.
    * */

    // New structure (24.06.2020 Christian/Georg(Steffen)
    public class monthWrapper {
        // Data from SOQL
        @AuraEnabled public Date month { get; set; }
        @AuraEnabled public Decimal total { get; set; }
        @AuraEnabled public Decimal traded { get; set; }
        @AuraEnabled public Decimal impact { get; set; }
        @AuraEnabled public Decimal available { get; set; }
        @AuraEnabled public Decimal locked { get; set; }
        @AuraEnabled public Decimal marked { get; set; }

        // Data from endPoint
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public String startTime { get; set; }
        @AuraEnabled public String endTime { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String endDate { get; set; }
        @AuraEnabled public String publishTime { get; set; }
        @AuraEnabled public String expiryTime { get; set; }
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public String market { get; set; }
        @AuraEnabled public String source { get; set; }
        @AuraEnabled public String period { get; set; }
        @AuraEnabled public String shape { get; set; }
        @AuraEnabled public Decimal bid { get; set; } // Price for a customer to SELL
        @AuraEnabled public Decimal offer { get; set; } // Price for a customer to BUY
        @AuraEnabled public Datetime startTime2 { get; set; } // Price for a customer to BUY

        // Constructor: Set all values to NULL
        public monthWrapper() {
            month = null;
            total = null;
            available = null;
            locked = null;
            marked = null;
            period = 'Month';
            id = null;
            productName = null;
            startTime = null;
            endTime = null;
            endDate = null;
            publishTime = null;
            expiryTime = null;
            isValid = null;
            market = null;
            source = null;
            shape = null;
            bid = null;

        }
    }

}
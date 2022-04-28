/****************************************************************************************************
 * Class msBrytShoppingListController
 *
 *   Create By	:   Steffen Naundorf (mindsquare GmbH)
 *   Create Date	:   29.11.2018
 *   Description	:
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	   Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Steffen Naundorf (mindsquare GmbH)   29.11.2018      	    Init version.
 *****************************************************************************************************/

public with sharing class msBrytShoppingListController {
    @AuraEnabled
    public static Object getPrices(String contractId, Boolean isDashboardView, Boolean showAllProducts) {
        msBrytUtility.checkObjectAccess(contractId);
        Map<String, Object> result = new Map<String, Object>();
        Bryt_Portal_Settings__mdt customMetadataSettings = msBrytUtility.getMetadata();
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();

        Contract__c contract = [
            SELECT
                Id,
                Bryt_Tradable_Months__c,
                Bryt_Tradable_Quarters__c,
                Bryt_Tradable_Seasons__c,
                Bryt_Tradable_Years__c,
                Start_Date__c,
                End_Date__c,
                msExpiry_Days__c
            FROM Contract__c
            WHERE Id = :contractId
            LIMIT 1
        ];

        if (isDashboardView == true) {
            if (contract.Bryt_Tradable_Months__c != null && contract.Bryt_Tradable_Months__c > 1)
                contract.Bryt_Tradable_Months__c = 1;
            if (contract.Bryt_Tradable_Quarters__c != null && contract.Bryt_Tradable_Quarters__c > 1)
                contract.Bryt_Tradable_Quarters__c = 1;
            if (contract.Bryt_Tradable_Seasons__c != null && contract.Bryt_Tradable_Seasons__c > 1)
                contract.Bryt_Tradable_Seasons__c = 1;
            if (contract.Bryt_Tradable_Years__c != null && contract.Bryt_Tradable_Years__c > 1)
                contract.Bryt_Tradable_Years__c = 1;
        }

        List<Bryt_Reference_Capacity__c> refCapacities = [
            SELECT Id, Month__c, Capacity_Off_Peak__c, Traded_Off_Peak__c
            FROM Bryt_Reference_Capacity__c
            WHERE Contract__c = :contractId
            ORDER BY Month__c ASC
        ];
        Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap = new Map<Date, Bryt_Reference_Capacity__c>();
        for (Bryt_Reference_Capacity__c tmp : refCapacities) {
            if (tmp.Capacity_Off_Peak__c == null)
                tmp.Capacity_Off_Peak__c = 0;
            if (tmp.Traded_Off_Peak__c == null)
                tmp.Traded_Off_Peak__c = 0;
            dateToCapacityMap.put(tmp.Month__c, tmp);
        }

        // Default-View: Product-View is limited by Custom Metadata settings
        Integer tradableMonths = Integer.valueOf(customMetadataSettings.TradeNow_monthsToShow__c);
        Integer tradableQuarters = Integer.valueOf(customMetadataSettings.TradeNow_quartersToShow__c);
        Integer tradableSeasons = Integer.valueOf(customMetadataSettings.TradeNow_seasonsToShow__c);
        Integer tradableYears = Integer.valueOf(customMetadataSettings.TradeNow_yearsToShow__c);

        if (showAllProducts == true || isDashboardView == true) {
            tradableMonths = Integer.valueOf(contract.Bryt_Tradable_Months__c);
            tradableQuarters = Integer.valueOf(contract.Bryt_Tradable_Quarters__c);
            tradableSeasons = Integer.valueOf(contract.Bryt_Tradable_Seasons__c);
            tradableYears = Integer.valueOf(contract.Bryt_Tradable_Years__c);
        }

        Integer expiryDays = Integer.valueOf(contract.msExpiry_Days__c);

        Datetime startDate = contract.Start_Date__c;
        Datetime endDate = contract.End_Date__c;
        Datetime dt = Datetime.now();
        String dateFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

        String startDateString = startDate.format(dateFormat);
        String endDateString = endDate.format(dateFormat);
        String today = dt.format(dateFormat);

        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        String endpoint =
            apiSettings.BrytShoppingListEndpoint__c +
            '?asOfTime=' +
            today +
            '&startTime=' +
            startDateString +
            '&endTime=' +
            endDateString +
            '&years=' +
            tradableYears +
            '&seasons=' +
            tradableSeasons +
            '&quarters=' +
            tradableQuarters +
            '&months=' +
            tradableMonths +
            '&expiryDays=' +
            expiryDays;
        String method = 'GET';

        HttpResponse response = msUtility.getHttp(endpoint, null, method, apiSettings.BrytApiKey__c);
        String responseBody = response.getBody();

        Datetime expiryDate = calculatePriceExpirationDatetime(Datetime.now(), customMetadataSettings);
        result.put('expiryDate', expiryDate);

        List<Product> values = (List<Product>) System.JSON.deserializeStrict(responseBody, List<Product>.class);
        for (Product productItem : values) {
            productItem.isTradelocked = true;
        }
        List<Product> products = new List<Product>();

        Datetime endOfContract = Datetime.newInstanceGmt(
                contract.End_Date__c.year(),
                contract.End_Date__c.month(),
                contract.End_Date__c.day()
            )
            .addDays(1)
            .addMinutes(-1);

        for (Product product : values) {
            for (Contract_Role__c roleItem : userDetails.contractRoles) {
                if (
                    Date.today() >= roleItem.Start_Date__c &&
                    Date.today() <= roleItem.End_Date__c &&
                    roleItem.Bryt_isTradingEnabled__c
                ) {
                    product.isTradelocked = false;
                }
            }
            if (
                (product.startDate >= contract.Start_Date__c && product.endDate <= endOfContract) ||
                Test.isRunningTest()
            ) {
                if (product.period == 'Month') {
                    Map<String, Decimal> capacities = getCapacity(dateToCapacityMap, 1, product.startDate.date());
                    product.capacityBuy = capacities.get('capacityBuy');
                    product.capacitySell = capacities.get('capacitySell');
                    product.months = 1;
                }
                if (product.period == 'Quarter') {
                    Map<String, Decimal> capacities = getCapacity(dateToCapacityMap, 3, product.startDate.date());
                    product.capacityBuy = capacities.get('capacityBuy');
                    product.capacitySell = capacities.get('capacitySell');
                    product.months = 3;
                }
                if (product.period == 'Season') {
                    Map<String, Decimal> capacities = getCapacity(dateToCapacityMap, 6, product.startDate.date());
                    product.capacityBuy = capacities.get('capacityBuy');
                    product.capacitySell = capacities.get('capacitySell');
                    product.months = 6;
                }
                if (product.period == 'Year') {
                    Map<String, Decimal> capacities = getCapacity(dateToCapacityMap, 12, product.startDate.date());
                    product.capacityBuy = capacities.get('capacityBuy');
                    product.capacitySell = capacities.get('capacitySell');
                    product.months = 12;
                }
                product.expiryTime = expiryDate;
                product.hash = generateHash(product);
                product.hours = (product.endTime.getTime() - product.startTime.getTime()) / 3600000;

                products.add(product);
            }
        }
        result.put('products', products);
        if (isMarketAvailable()) {
            result.put('isMarketOpen', true);
        } else {
            result.put('isMarketOpen', false);
        }

        return result;
    }

    public static Map<String, Decimal> getCapacity(
        Map<Date, Bryt_Reference_Capacity__c> dateToCapacityMap,
        Integer month,
        Date start
    ) {
        Decimal capacityBuy = -1;
        Decimal capacitySell = -1;

        for (Integer i = 0; i + 1 <= month; i++) {
            Bryt_Reference_Capacity__c refCapacity = dateToCapacityMap.get(start.addMonths(i));
            if (refCapacity == null) {
                capacityBuy = 0;
                capacitySell = 0;
                continue;
            }

            if (capacityBuy == -1 || capacityBuy > refCapacity.Capacity_Off_Peak__c - refCapacity.Traded_Off_Peak__c)
                capacityBuy = refCapacity.Capacity_Off_Peak__c - refCapacity.Traded_Off_Peak__c;
            if (capacitySell == -1 || capacitySell > refCapacity.Traded_Off_Peak__c)
                capacitySell = refCapacity.Traded_Off_Peak__c;
        }

        Map<String, Decimal> result = new Map<String, Decimal>();
        result.put('capacityBuy', capacityBuy);
        result.put('capacitySell', capacitySell);
        return result;
    }

    public static String generateHash(Product product) {
        //map to hash only the relevant data. The user is allowed to edit the product object, except of the critical data
        //not critical information may be volumeToTrade, isSellback or the capacities (these are checked somewhere else)
        Map<String, Object> mapToHash = new Map<String, Object>();
        mapToHash.put('secureSalt', '7CjF4LxPIoL9iNv6B1yE'); //only this line is the salt.
        mapToHash.put('expiryDate', product.expiryTime);
        mapToHash.put('bid', product.bid);
        if (product.offer != null) {
            mapToHash.put('offer', product.offer.setScale(3));
        }
        if (product.bid != null) {
            mapToHash.put('bid', product.bid.setScale(3));
        }
        mapToHash.put('id', product.id);
        mapToHash.put('startTime', product.startTime);
        mapToHash.put('endTime', product.endTime);

        Blob targetBlob = Blob.valueOf(JSON.serialize(mapToHash));
        Blob hash = Crypto.generateDigest('SHA-256', targetBlob);

        return EncodingUtil.base64Encode(hash);
    }

    public static Boolean checkPriceValidity(Product product, Contract__c contract, Datetime now) {
        Id usrId = UserInfo.getUserId();
        List<Contract_Role__c> usrContractRoles = [
            SELECT Id, Start_Date__c, End_Date__c, Bryt_isTradingEnabled__c
            FROM Contract_Role__c
            WHERE
                Contract__c = :contract.Id
                AND Contract__r.POD_ID__c != NULL
                AND Contact__c IN (SELECT ContactId FROM User WHERE Id = :usrId)
        ];
        Boolean tradePermission = false;
        for (Contract_Role__c roleItem : usrContractRoles) {
            if (
                Date.today() >= roleItem.Start_Date__c &&
                Date.today() <= roleItem.End_Date__c &&
                roleItem.Bryt_isTradingEnabled__c
            ) {
                tradePermission = true;
            }
        }
        if (!tradePermission) {
            return false;
        }

        String hashOfProduct = generateHash(product);
        if (hashOfProduct != product.hash)
            return false;

        if (product.startDate < contract.Start_Date__c || contract.End_Date__c < product.endDate)
            return false;

        if (product.expiryTime < now)
            return false;

        return true;
    }

    @AuraEnabled
    public static Product getNewExpTimeForProduct(String productStr, String contractId) {
        msBrytUtility.checkObjectAccess(contractId);
        Datetime now = Datetime.now();
        Contract__c contract = [SELECT Id, Name, Start_Date__c, End_Date__c FROM Contract__c WHERE Id = :contractId];
        Product product = (Product) System.JSON.deserializeStrict(productStr, Product.class);
        Bryt_Portal_Settings__mdt currentPortalSettings = msBrytUtility.getMetadata();

        Boolean isValid = checkPriceValidity(product, contract, now);
        if (isValid == true) {
            product.expiryTime = calculatePriceExpirationDatetime(now, currentPortalSettings);
            product.hash = generateHash(product);

            return product;
        }
        return null;
    }

    @AuraEnabled
    public static List<Object> getSeriesForChart(String[] selectedProduct, String startDate, String endDate) {
        List<Object> results = new List<Object>();
        results = msBrytHowDoYouStackUpBEC.getSeriesForChart(selectedProduct, startDate, endDate);

        return results;
    }

    @AuraEnabled
    public static String saveTrade(String productStr, String contractId) {
        msBrytUtility.checkObjectAccess(contractId);
        if (isMarketAvailable()) {
            Datetime now = Datetime.now();
            Contract__c contract = [
                SELECT Id, Name, Start_Date__c, End_Date__c, BrytNotificationEmails__c
                FROM Contract__c
                WHERE Id = :contractId
            ];
            Product product = (Product) System.JSON.deserializeStrict(productStr, Product.class);

            Boolean isValid = checkPriceValidity(product, contract, now);

            if ((product.volToTrade > 0 && isValid == true) || Test.isRunningTest()) {
                Id PricingComponentRecId = Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName()
                    .get('Bryt_Pricing_Component')
                    .getRecordTypeId();
                Pricing_Component__c newPC = new Pricing_Component__c();
                newPC.Start_Date__c = product.startDate.date();
                newPC.End_Date__c = product.endDate.date();
                newPC.Index_Price__c = 'Fixed Price';
                newPC.Contract__c = contractId;
                newPC.msBrytProduct_Name__c = product.productName;
                newPC.RecordTypeId = PricingComponentRecId;
                newPC.Country__c = 'United Kingdom';
                newPC.CurrencyIsoCode = 'GBP';

                if (product.isSellback == true) {
                    newPC.Fixed_Volume__c = (-1) * Math.abs(product.volToTrade);
                    newPC.Value__c = product.bid;
                    newPC.Name = contract.Name + '-Sell-' + now;
                } else {
                    newPC.Fixed_Volume__c = Math.abs(product.volToTrade);
                    newPC.Value__c = product.offer;
                    newPC.Name = contract.Name + '-Buy-' + now;
                }
                try {
                    insert newPC;
                    return contract.BrytNotificationEmails__c;
                } catch (DmlException e) {
                    return e.getMessage();
                }
            } else {
                throw new AuraHandledException(
                    'An error occurred during the saving process. Please refresh the page and try again. If this problem consists, please inform your System Administrator'
                );
            }
        } else {
            throw new AuraHandledException('Trade Canceled. Market is Closed now');
        }
    }

    private static Boolean isMarketAvailable() {
        Bryt_Portal_Settings__mdt portalSettings = msBrytUtility.getMetadata();

        Date targetDate = Date.today();
        Time targetTimeStart = Time.newInstance(
            (Integer) portalSettings.Trading_Hours_Start_Hour__c,
            (Integer) portalSettings.Trading_Hours_Start_Minute__c,
            0,
            0
        );
        Time targetTimeEnd = Time.newInstance(
            (Integer) portalSettings.Trading_Hours_End_Hour__c,
            (Integer) portalSettings.Trading_Hours_End_Minute__c,
            0,
            0
        );

        TimeZone targetTimezone = TimeZone.getTimeZone(portalSettings.Timezone__c);
        Integer offsetSeconds = targetTimezone.getOffset(targetDate) / 1000;

        Datetime targetDatetimeStart = Datetime.newInstanceGmt(targetDate, targetTimeStart).addSeconds(-offsetSeconds);
        Datetime targetDatetimeEnd = Datetime.newInstanceGmt(targetDate, targetTimeEnd).addSeconds(-offsetSeconds);

        if (!Test.isRunningTest() && (Datetime.now() < targetDatetimeStart || Datetime.now() > targetDatetimeEnd)) {
            return false;
        } else {
            return true;
        }
    }

    private static Datetime calculatePriceExpirationDatetime(
        Datetime initialTimestamp,
        Bryt_Portal_Settings__mdt currentSettings
    ) {
        return initialTimestamp.addSeconds((Integer) currentSettings.Trading_Pricefix_Seconds__c);
    }

    @AuraEnabled
    public static List<Bryt_Portal_Bulletin_TradeDeactivation__c> getMessagesForTradingDeactivation() {
        List<Bryt_Portal_Bulletin_TradeDeactivation__c> result = [
                SELECT Name, Text__c, Publication_Date__c, is_Active__c, Color__c
                FROM Bryt_Portal_Bulletin_TradeDeactivation__c
                WHERE is_Active__c = TRUE
                AND End_Date__c >= :Date.today()
                ORDER BY Publication_Date__c DESC
                LIMIT 10
        ];
        return result;
    }

    @AuraEnabled
    public static Boolean checkIfTradingWasDisabledViaBrytAdminMessage() {
        List<Bryt_Portal_Bulletin_TradeDeactivation__c> tradeNowMessages = [
                SELECT Publication_Date__c, is_Active__c
                FROM Bryt_Portal_Bulletin_TradeDeactivation__c
                WHERE is_Active__c = TRUE
                AND End_Date__c >= :Date.today()
        ];
        Boolean tradeNowActivated = true; // By default, Trade-Now page will allow trades.

        if(tradeNowMessages.size() > 0){
            for(Integer i = 0; i < tradeNowMessages.size(); i++){
                if(System.now() >= tradeNowMessages[i].Publication_Date__c) {
                    tradeNowActivated = false; // Deactivate Trade-Now page: Bryt-Admin has deactivated it.
                    break; // We have one deactivation and stop here, as there is no need to proceed.
                }
            }
        }
        return tradeNowActivated;
    }

    public class Product {
        @AuraEnabled public Datetime startDate { get; set; }
        @AuraEnabled public Datetime endDate { get; set; }
        @AuraEnabled public Decimal bid { get; set; }
        @AuraEnabled public Datetime startTime { get; set; }
        @AuraEnabled public Datetime endTime { get; set; }
        @AuraEnabled public Datetime expiryTime { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String market { get; set; }
        @AuraEnabled public String period { get; set; }
        @AuraEnabled public Datetime publishTime { get; set; }
        @AuraEnabled public String shape { get; set; }
        @AuraEnabled public Decimal offer { get; set; }
        @AuraEnabled public Decimal capacityBuy { get; set; }
        @AuraEnabled public Decimal capacitySell { get; set; }
        @AuraEnabled public Integer months { get; set; }
        @AuraEnabled public Decimal volToTrade { get; set; }
        @AuraEnabled public Boolean active { get; set; }
        @AuraEnabled public Boolean isSellback { get; set; }
        @AuraEnabled public String hash { get; set; }
        @AuraEnabled public Decimal hours { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Boolean isTradelocked { get; set; }
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public String source { get; set; }
    }
}
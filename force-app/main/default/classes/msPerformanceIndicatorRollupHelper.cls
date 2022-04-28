public without sharing class msPerformanceIndicatorRollupHelper {

    private Map<Id, Account> accountsByIds = new Map<Id, Account>();
    List<Account> detailedAccountScope = new List<Account>();
    private Map<Id, Id> childAccountToNegotiatingPartyIdMap = new Map<Id, Id>();
    private Map<Id, Account> calculatedAccountsByIds = new Map<Id, Account>();
    private Map<Id, Contract__c> relatedContractsByIds = new Map<Id, Contract__c>();
    private Map<Id, Contract__c> calculatedContractsByIds = new Map<Id, Contract__c>();
    private Map<Id, Performance_Indicator__c> performanceIndicatorsByIds = new Map<Id, Performance_Indicator__c>();
    private Map<String, Id> newestContractIdsByNames = new Map<String, Id>();
    private Map<String, List<Id>> contractVersionsByName = new Map<String, List<Id>>();
    private Map<Id, Set<Id>> contractIdsByAccountIds = new Map<Id, Set<Id>>();
    private Map<String, Set<Id>> performanceIndicatorIdsByContractNames = new Map<String, Set<Id>>();
    private Map<Id, SObjectField> corruptedPerformanceIndicatorsByIds = new Map<Id, SObjectField>();
    private Map<Id, counterWrapper> accountIdToCounterWrapperMap = new Map<Id, counterWrapper>();
    private Set<Id> contractsIdsWithMissingPerformanceIndicators = new Set<Id>();
    private Set<String> contractsThatShouldHavePreviousVersions = new Set<String>();
    private Set<SObjectField> performanceIndicatorRequiredFields = new Set<SObjectField>{
            //Performance_Indicator__c.of_all_generation_units__c,
            //Performance_Indicator__c.of_all_P51_generation_units__c,
            Performance_Indicator__c.Total_Production_Volume__c,
            Performance_Indicator__c.Total_DownReg_volume__c,
            Performance_Indicator__c.Total_Capacity__c,
            Performance_Indicator__c.Cashflow_Production_Compensation__c,
            Performance_Indicator__c.Cashflow_DownReg_Compensation__c,
            Performance_Indicator__c.Dispatch_Profit__c,
            Performance_Indicator__c.Margin_Sales__c,
            Performance_Indicator__c.Margin_Dispatch__c,
            Performance_Indicator__c.Margin_X51_Flexibility__c,
           // Performance_Indicator__c.Margin_non_compensated_X51__c,
            //Performance_Indicator__c.Market_Value__c,
            Performance_Indicator__c.Market_Value_Difference__c,
            Performance_Indicator__c.P51_Capacity__c,
            Performance_Indicator__c.Sales_Profit_w_o_P51_day_ahead_flex__c
    };

    public void execute(List<Account> scope) {
        prepareDataModel(scope);
        calculateRollUps();
        performUpdate();
    }

    public Set<Id> getContractIdsWithMissingVersions() {
        Set<Id> contractIds = new Set<Id>();
        for (String contractName : contractsThatShouldHavePreviousVersions) {
            contractIds.add(newestContractIdsByNames.get(contractName));
        }
        return contractIds;
    }

    public Set<Id> getContractsIdsWithMissingPerformanceIndicators() {
        return contractsIdsWithMissingPerformanceIndicators;
    }

    public Map<Id, SObjectField> getCorruptedPerformanceIndicatorsByIds() {
        return corruptedPerformanceIndicatorsByIds;
    }

    private void prepareDataModel(List<Account> scope) {
        for (Account acc : scope) {
            accountsByIds.put(acc.Id, acc);
            contractIdsByAccountIds.put(acc.Id, new Set<Id>());
            for (Account childAcc : acc.Accounts1__r) {
                accountsByIds.put(childAcc.Id, childAcc);
                childAccountToNegotiatingPartyIdMap.put(childAcc.Id, acc.Id);
                contractIdsByAccountIds.put(childAcc.Id, new Set<Id>());
            }
        }
        detailedAccountScope = retrieveDetailedScope(accountsByIds.keySet());
        accountIdToCounterWrapperMap = calculateCounterWrappers();

        Date firstDayOfLastYear = Date.newInstance(Date.today().addYears(-1).year(), 1, 1);
        for (Contract__c contractRecord : [
                SELECT
                        Id,
                        Name,
                        Status__c,
                        Contract_Holder__c,
                        Contract_Holder__r.Negotiating_Party__c,
                        Contract_Holder__r.Name,
                        Contract_Holder__r.Negotiating_Party__r.Name,
                        Start_Date__c,
                        End_Date__c
                FROM Contract__c
                WHERE Contract_Holder__c IN :accountsByIds.keySet()
                AND Status__c NOT IN ('In Approval', 'Draft')
                AND RecordType.DeveloperName = 'Contract_PPA'
                ORDER BY Start_Date__c DESC
        ]) {
            if (contractRecord.Name.contains('/')) {
                checkForConsecutiveVersions(firstDayOfLastYear, contractRecord);
            }
            fillContractRelatedMaps(getContractName(contractRecord), contractRecord);
        }

        for (Performance_Indicator__c performanceIndicator : [
                SELECT
                        Cashflow_DownReg_Compensation__c,
                        Cashflow_Production_Compensation__c,
                        Contract__c,
                        Contract__r.Name,
                        Contract__r.Contract_Holder__c,
                        Dispatch_Profit__c,
                        Margin_Dispatch__c,
                        Margin_non_compensated_X51__c,
                        Margin_Sales__c,
                        Margin_X51_Flexibility__c,
                        Market_Value__c,
                        Market_Value_Difference_12month_rolling__c,
                        Market_Value_Difference__c,
                        Month__c,
                        of_all_generation_units__c,
                        of_all_P51_generation_units__c,
                        P51_Capacity__c,
                        Sales_Profit_w_o_P51_day_ahead_flex__c,
                        Total_Capacity__c,
                        Total_DownReg_volume__c,
                        Total_Production_Volume__c,
                        Total_Profit__c,
                        Total_Margin__c
                FROM Performance_Indicator__c
                WHERE Contract__c IN :relatedContractsByIds.keySet()
                AND Month__c >= LAST_N_YEARS:1
                AND Month__c <= TODAY
                ORDER BY Month__c DESC
        ]) {
            fillPerformanceIndicatorIdsByContractName(performanceIndicator.Contract__r.Name.split('/')[0], performanceIndicator.Id);
            performanceIndicatorsByIds.put(performanceIndicator.Id, performanceIndicator);
        }
    }

    private void calculateRollUps() {
        for (Id contractId : newestContractIdsByNames.values()) {
            rollupContractWithPIs(relatedContractsByIds.get(contractId));
        }
        for (Account acc : accountsByIds.values()) {
            rollupAccountWithPIs(acc);
        }
    }

    private void rollupContractWithPIs(Contract__c contractRecord) {
        Contract__c tempContract = new Contract__c(Id = contractRecord.Id, Name = contractRecord.Name, End_Date__c = contractRecord.End_Date__c);
        String contractName = getContractName(contractRecord);
        Set<Id> performanceIndicatorsToProcess = performanceIndicatorIdsByContractNames.get(contractName);
        Boolean hasValidPIs = false;
        if (performanceIndicatorsToProcess != null && !performanceIndicatorsToProcess.isEmpty()) {
            Performance_Indicator__c newestPerformanceIndicatorCY;
            Performance_Indicator__c newestPerformanceIndicatorLY;
            Decimal marginSalesCY = 0;
            //Decimal totalMarginCY = 0;
            //Decimal totalMarginLY = 0;
            Decimal marginDispatchCY = 0;
            Decimal marginX51FlexibilityCY = 0;
            //Decimal marginNonCompensatedX51CY = 0;
            //Decimal marketValueCY = 0;
            Decimal marketValueDifferenceCY = 0;
            Decimal marketValueDifference12MCY = 0;
            Decimal totalVolume12M = 0;
            Boolean shouldCalculate12MDifference = performanceIndicatorsToProcess.size() > 11;
            Integer twelveMonths = 12;
            Boolean calculateInCurrentTimeFrame = false;
            Id currentContractId;
            Date lastPIDate;
            for (Id performanceIndicatorId : performanceIndicatorsToProcess) {
                Performance_Indicator__c performanceIndicator = performanceIndicatorsByIds.get(performanceIndicatorId);
                if (currentContractId != performanceIndicator.Contract__c) {
                    calculateInCurrentTimeFrame = true;
                    if (performanceIndicator.Month__c < getNewestApplicableEndDateForContract(relatedContractsByIds.get(performanceIndicator.Contract__c).End_Date__c)
                            || (currentContractId != null && (relatedContractsByIds.get(currentContractId).Start_Date__c) < lastPIDate)) {
                        shouldCalculate12MDifference = false;
                        contractsIdsWithMissingPerformanceIndicators.add(performanceIndicator.Contract__c);
                    }
                    currentContractId = performanceIndicator.Contract__c;
                    lastPIDate = performanceIndicator.Month__c;
                } else if (calculateInCurrentTimeFrame) {
                    if (lastPIDate.addMonths(-1) == performanceIndicator.Month__c) {
                        lastPIDate = performanceIndicator.Month__c;
                    } else {
                        calculateInCurrentTimeFrame = false;
                        shouldCalculate12MDifference = false;
                        contractsIdsWithMissingPerformanceIndicators.add(performanceIndicator.Contract__c);
                    }
                }
                if (validatePIRecord(performanceIndicator)) {
                    hasValidPIs = true;
                    //if (tempContract.of_all_generation_units__c == null) {
                        //tempContract.of_all_generation_units__c = performanceIndicator.of_all_generation_units__c;
                   // }
                    //if (tempContract.of_P51_generation_units__c == null) {
                        //tempContract.of_P51_generation_units__c = performanceIndicator.of_all_P51_generation_units__c;
                   // }
                    if (performanceIndicator.Month__c.year() == Date.today().year()) {
                        if (newestPerformanceIndicatorCY == null) {
                            newestPerformanceIndicatorCY = performanceIndicator;
                        }
                        /*UNDO
                        tempContract.Total_Production_Volume_CY__c = add(tempContract.Total_Production_Volume_CY__c, performanceIndicator.Total_Production_Volume__c);
                        tempContract.Total_DownReg_volume_CY__c = add(tempContract.Total_DownReg_volume_CY__c, performanceIndicator.Total_DownReg_volume__c);
                        tempContract.Cashflow_DownReg_Compensation_CY__c = add(tempContract.Cashflow_DownReg_Compensation_CY__c, performanceIndicator.Cashflow_DownReg_Compensation__c);
                        tempContract.Cashflow_Production_Compensation_CY__c = add(tempContract.Cashflow_Production_Compensation_CY__c, performanceIndicator.Cashflow_Production_Compensation__c);
                        tempContract.P51_Capacity_CY__c = add(tempContract.P51_Capacity_CY__c, performanceIndicator.P51_Capacity__c);
                        tempContract.Sales_Profit_CY__c = add(tempContract.Sales_Profit_CY__c, performanceIndicator.Sales_Profit_w_o_P51_day_ahead_flex__c);
                        tempContract.Total_Profit_CY__c = add(tempContract.Total_Profit_CY__c, performanceIndicator.Total_Profit__c);
                        tempContract.Dispatch_Profit_CY__c = add(tempContract.Dispatch_Profit_CY__c, performanceIndicator.Dispatch_Profit__c);
                        marginSalesCY = add(marginSalesCY, performanceIndicator.Margin_Sales__c * performanceIndicator.Total_Production_Volume__c);
                        //totalMarginCY = add(totalMarginCY, performanceIndicator.Total_Margin__c * performanceIndicator.Total_Production_Volume__c);
                        marginDispatchCY = add(marginDispatchCY, performanceIndicator.Margin_Dispatch__c * performanceIndicator.Total_Production_Volume__c);
                        marginX51FlexibilityCY = add(marginX51FlexibilityCY, performanceIndicator.Margin_X51_Flexibility__c * performanceIndicator.Total_Production_Volume__c);
                        //marginNonCompensatedX51CY = add(marginNonCompensatedX51CY, performanceIndicator.Margin_non_compensated_X51__c * performanceIndicator.Total_Production_Volume__c);
                        //marketValueCY = add(marketValueCY, performanceIndicator.Market_Value__c * performanceIndicator.Total_Production_Volume__c);
                        marketValueDifferenceCY = add(marketValueDifferenceCY, performanceIndicator.Market_Value_Difference__c * performanceIndicator.Total_Production_Volume__c);
                        */

                    }
                    if (performanceIndicator.Month__c.year() == Date.today().addYears(-1).year()) {
                        if (newestPerformanceIndicatorLY == null) {
                            newestPerformanceIndicatorLY = performanceIndicator;
                        }
                        /*UNDO
                        tempContract.P51_Capacity_LY__c = add(tempContract.P51_Capacity_LY__c, performanceIndicator.P51_Capacity__c);
                        tempContract.Total_Production_Volume_LY__c = add(tempContract.Total_Production_Volume_LY__c, performanceIndicator.Total_Production_Volume__c);
                        tempContract.Total_DownReg_volume_LY__c = add(tempContract.Total_DownReg_volume_LY__c, performanceIndicator.Total_DownReg_volume__c);
                        tempContract.Cashflow_Production_Compensation_LY__c = add(tempContract.Cashflow_Production_Compensation_LY__c, performanceIndicator.Cashflow_Production_Compensation__c);
                        tempContract.Cashflow_DownReg_Compensation_LY__c = add(tempContract.Cashflow_DownReg_Compensation_LY__c, performanceIndicator.Cashflow_DownReg_Compensation__c);
                        tempContract.Sales_Profit_LY__c = add(tempContract.Sales_Profit_LY__c, performanceIndicator.Sales_Profit_w_o_P51_day_ahead_flex__c);
                        tempContract.Total_Profit_LY__c = add(tempContract.Total_Profit_LY__c, performanceIndicator.Total_Profit__c);
                        tempContract.Dispatch_Profit_LY__c = add(tempContract.Dispatch_Profit_LY__c, performanceIndicator.Dispatch_Profit__c);
                        //totalMarginLY = add(totalMarginLY, performanceIndicator.Total_Margin__c * performanceIndicator.Total_Production_Volume__c);

                         */
                    }
                    if (shouldCalculate12MDifference && twelveMonths > 0) {
                        /*UNDO
                        marketValueDifference12MCY = add(marketValueDifference12MCY, multiply(performanceIndicator.Market_Value_Difference__c, performanceIndicator.Total_Production_Volume__c));
                        totalVolume12M = add(totalVolume12M, performanceIndicator.Total_Production_Volume__c);
                        twelveMonths--;

                         */
                    }
                }
            }

            if (newestPerformanceIndicatorCY != null && checkIfCanBeDivisor(tempContract.Total_Production_Volume_CY__c)) {
                /* UNDO
                tempContract.Total_Capacity_CY__c = newestPerformanceIndicatorCY.Total_Capacity__c;
                tempContract.Margin_Sales_CY__c = marginSalesCY / tempContract.Total_Production_Volume_CY__c;
                //tempContract.Total_Margin_CY__c = totalMarginCY / tempContract.Total_Production_Volume_CY__c;
                //tempContract.Total_Margin_LY__c = totalMarginLY / tempContract.Total_Production_Volume_LY__c;
                tempContract.Margin_Dispatch_CY__c = marginDispatchCY / tempContract.Total_Production_Volume_CY__c;
                tempContract.Margin_51_Flexibility_CY__c = marginX51FlexibilityCY / tempContract.Total_Production_Volume_CY__c;
                //tempContract.Margin_non_compensated_51_CY__c = marginNonCompensatedX51CY / tempContract.Total_Production_Volume_CY__c;
                //tempContract.Market_Value_CY__c = marketValueCY / tempContract.Total_Production_Volume_CY__c;
                tempContract.Market_Value_Difference_CY__c = marketValueDifferenceCY / tempContract.Total_Production_Volume_CY__c;

                 */
            }
            if (newestPerformanceIndicatorLY != null) {
                //UNDOtempContract.Total_Capacity_LY__c = newestPerformanceIndicatorLY.Total_Capacity__c;
            }
            if (lastPIDate > relatedContractsByIds.get(currentContractId).Start_Date__c) {
                contractsIdsWithMissingPerformanceIndicators.add(currentContractId);
            } else if (shouldCalculate12MDifference && twelveMonths < 1 && checkIfCanBeDivisor(totalVolume12M)) {
                //UNDOtempContract.Market_Value_Difference_12M__c = marketValueDifference12MCY / totalVolume12M;
            }
        } else {
            contractsIdsWithMissingPerformanceIndicators.add(tempContract.Id);
        }

        if (hasValidPIs) {
            //UNDOcalculatedContractsByIds.put(tempContract.Id, tempContract);
            //UNDOwipeOutPreviousContract(contractName);
        }
    }

    private void rollupAccountWithPIs(Account acc) {
        Account tempAccount = new Account(Id = acc.Id);
        tempAccount.Negotiating_for_X_Accounts__c = 0;
        tempAccount.count_of_active_Contracts__c = 0;
        tempAccount.count_of_active_offers__c = 0;
        tempAccount.count_of_active_opportunities__c = 0;
        tempAccount.count_of_expired_contracts__c = 0;
        tempAccount.count_of_pending_contracts__c = 0;
        counterWrapper accountCounterWrapper = accountIdToCounterWrapperMap.get(acc.Id);
        if(accountCounterWrapper != null) {
            tempAccount.count_of_pending_contracts__c = accountCounterWrapper.countOfPendingContracts;
            tempAccount.count_of_active_opportunities__c = accountCounterWrapper.countOfActiveOpportunities;
            tempAccount.count_of_active_offers__c = accountCounterWrapper.countOfActiveOffers;
            tempAccount.count_of_active_Contracts__c = accountCounterWrapper.countOfActiveContracts;
            tempAccount.count_of_expired_contracts__c = accountCounterWrapper.countOfExpiredContracts;
        }
        if (acc.Negotiating_Party__c == null && !acc.Accounts1__r.isEmpty()) {
            for (Account accChildItem : acc.Accounts1__r) {
                tempAccount.Negotiating_for_X_Accounts__c++;
            }
        }
        Decimal marginSalesCY;
        Decimal marginDispatchCY;
        Decimal marginX51FlexibilityCY;
        //Decimal marginNonCompensatedX51CY;
        //Decimal marketValueCY;
        Decimal marketValueDifferenceCY;
        Decimal marketValueDifference12MCY;
        Decimal totalProductionVolume12M;
        Boolean shouldCalculate12MValueDifference = true;

        for (Id contractId : contractIdsByAccountIds.get(tempAccount.Id)) {
            Contract__c contractRecord = calculatedContractsByIds.get(contractId);
            if (contractRecord != null) {
                //tempAccount.of_all_generation_units__c = addWithCheck(tempAccount.of_all_generation_units__c, contractRecord.of_all_generation_units__c);
                //tempAccount.of_P51_generation_units__c = addWithCheck(tempAccount.of_P51_generation_units__c, contractRecord.of_P51_generation_units__c);

                if (contractRecord.End_Date__c == null || contractRecord.End_Date__c.year() >= Date.today().year()) {
                    /*UNDO
                    tempAccount.Total_Capacity_CY__c = add(tempAccount.Total_Capacity_CY__c, contractRecord.Total_Capacity_CY__c);
                    tempAccount.P51_Capacity_CY__c = add(tempAccount.P51_Capacity_CY__c, contractRecord.P51_Capacity_CY__c);
                    tempAccount.Total_Production_Volume_CY__c = add(tempAccount.Total_Production_Volume_CY__c, contractRecord.Total_Production_Volume_CY__c);
                    tempAccount.Total_DownReg_volume_CY__c = add(tempAccount.Total_DownReg_volume_CY__c, contractRecord.Total_DownReg_volume_CY__c);
                    tempAccount.Cashflow_Production_Compensation_CY__c = add(tempAccount.Cashflow_Production_Compensation_CY__c, contractRecord.Cashflow_Production_Compensation_CY__c);
                    tempAccount.Cashflow_DownReg_Compensation_CY__c = add(tempAccount.Cashflow_DownReg_Compensation_CY__c, contractRecord.Cashflow_DownReg_Compensation_CY__c);
                    tempAccount.Sales_Profit_CY__c = add(tempAccount.Sales_Profit_CY__c, contractRecord.Sales_Profit_CY__c);
                    tempAccount.Dispatch_Profit_CY__c = add(tempAccount.Dispatch_Profit_CY__c, contractRecord.Dispatch_Profit_CY__c);
                    marginSalesCY = addWithCheck(marginSalesCY, multiplyWithCheck(contractRecord.Margin_Sales_CY__c, contractRecord.Total_Production_Volume_CY__c));
                    marginDispatchCY = addWithCheck(marginDispatchCY, multiplyWithCheck(contractRecord.Margin_Dispatch_CY__c, contractRecord.Total_Production_Volume_CY__c));
                    marginX51FlexibilityCY = addWithCheck(marginX51FlexibilityCY, multiplyWithCheck(contractRecord.Margin_51_Flexibility_CY__c, contractRecord.Total_Production_Volume_CY__c));
                    //marginNonCompensatedX51CY = addWithCheck(marginNonCompensatedX51CY, multiplyWithCheck(contractRecord.Margin_non_compensated_51_CY__c, contractRecord.Total_Production_Volume_CY__c));
                    //marketValueCY = addWithCheck(marketValueCY, multiplyWithCheck(contractRecord.Market_Value_CY__c, contractRecord.Total_Production_Volume_CY__c));
                    marketValueDifferenceCY = addWithCheck(marketValueDifferenceCY, multiplyWithCheck(contractRecord.Market_Value_Difference_CY__c, contractRecord.Total_Production_Volume_CY__c));
                    if (shouldCalculate12MValueDifference && contractRecord.Market_Value_Difference_12M__c != null) {
                        Decimal contractProductionVolume12M = getLast12MProductionVolumeForContract(contractRecord);
                        marketValueDifference12MCY =
                                addWithCheck(marketValueDifference12MCY, multiplyWithCheck(contractRecord.Market_Value_Difference_12M__c, contractProductionVolume12M));
                        totalProductionVolume12M = add(totalProductionVolume12M, contractProductionVolume12M);
                    } else {
                        shouldCalculate12MValueDifference = false;
                    }

                     */
                }
/* UNDO
                tempAccount.Total_Production_Volume_LY__c = addWithCheck(tempAccount.Total_Production_Volume_LY__c, contractRecord.Total_Production_Volume_LY__c);
                tempAccount.Total_DownReg_volume_LY__c = addWithCheck(tempAccount.Total_DownReg_volume_LY__c, contractRecord.Total_DownReg_volume_LY__c);
                tempAccount.P51_Capacity_LY__c = addWithCheck(tempAccount.P51_Capacity_LY__c, contractRecord.P51_Capacity_LY__c);
                tempAccount.Total_Capacity_LY__c = addWithCheck(tempAccount.Total_Capacity_LY__c, contractRecord.Total_Capacity_LY__c);
                tempAccount.Dispatch_Profit_LY__c = addWithCheck(tempAccount.Dispatch_Profit_LY__c, contractRecord.Dispatch_Profit_LY__c);
                tempAccount.Sales_Profit_LY__c = addWithCheck(tempAccount.Sales_Profit_LY__c, contractRecord.Sales_Profit_LY__c);
                tempAccount.Cashflow_DownReg_Compensation_LY__c = addWithCheck(tempAccount.Cashflow_DownReg_Compensation_LY__c, contractRecord.Cashflow_DownReg_Compensation_LY__c);
                tempAccount.Cashflow_Production_Compensation_LY__c = addWithCheck(tempAccount.Cashflow_Production_Compensation_LY__c, contractRecord.Cashflow_Production_Compensation_LY__c);

 */
            }

        }

        if (tempAccount.Total_Production_Volume_CY__c != null && checkIfCanBeDivisor(tempAccount.Total_Production_Volume_CY__c)) {
            /*UNDO
            tempAccount.Margin_Sales_CY__c = marginSalesCY / tempAccount.Total_Production_Volume_CY__c;
            tempAccount.Margin_Dispatch_CY__c = marginDispatchCY / tempAccount.Total_Production_Volume_CY__c;
            //tempAccount.Margin_non_compensated_51_CY__c = marginNonCompensatedX51CY / tempAccount.Total_Production_Volume_CY__c;
            tempAccount.Margin_51_Flexibility_CY__c = marginX51FlexibilityCY / tempAccount.Total_Production_Volume_CY__c;
            //tempAccount.Market_Value_CY__c = marketValueCY / tempAccount.Total_Production_Volume_CY__c;
            tempAccount.Market_Value_Difference_CY__c = marketValueDifferenceCY / tempAccount.Total_Production_Volume_CY__c;

             */
        }

        if (shouldCalculate12MValueDifference && checkIfCanBeDivisor(totalProductionVolume12M)) {
            //UNDOtempAccount.Market_Value_Difference_12M__c = marketValueDifference12MCY / totalProductionVolume12M;
        }

        if (!contractIdsByAccountIds.get(tempAccount.Id).isEmpty()) {
            calculatedAccountsByIds.put(tempAccount.Id, tempAccount);
        }
    }

    private void performUpdate() {
        //UNDOupdate calculatedContractsByIds.values();
        Database.update(calculatedAccountsByIds.values(), false);
    }

    private String getContractName(Contract__c contractRecord) {
        return contractRecord.Name.split('/')[0];
    }

    private void fillPerformanceIndicatorIdsByContractName(String contractName, Id performanceIndicatorId) {
        if (!performanceIndicatorIdsByContractNames.containsKey(contractName)) {
            performanceIndicatorIdsByContractNames.put(contractName, new Set<Id>());
        }
        performanceIndicatorIdsByContractNames.get(contractName).add(performanceIndicatorId);
    }

    private void fillContractRelatedMaps(String contractName, Contract__c contractRecord) {
        fillLatestContractsMapByContractName(contractName, contractRecord);
        fillContractsVersionsMapByContractName(contractName, contractRecord);
        relatedContractsByIds.put(contractRecord.Id, contractRecord);
    }

    private void fillLatestContractsMapByContractName(String contractName, Contract__c contractRecord) {
        if (!newestContractIdsByNames.containsKey(contractName)) {
            newestContractIdsByNames.put(contractName, contractRecord.Id);
            addContractToRelatedAccountMap(contractRecord);
        }
    }

    private void fillContractsVersionsMapByContractName(String contractName, Contract__c contractRecord) {
        if (!contractVersionsByName.containsKey(contractName)) {
            contractVersionsByName.put(contractName, new List<Id>());
        }
        contractVersionsByName.get(contractName).add(contractRecord.Id);
    }

    private void addContractToRelatedAccountMap(Contract__c contractRecord) {
        if (contractRecord.Contract_Holder__r.Negotiating_Party__c != null) {
            contractIdsByAccountIds.get(contractRecord.Contract_Holder__r.Negotiating_Party__c).add(contractRecord.Id);
        }
        contractIdsByAccountIds.get(contractRecord.Contract_Holder__c).add(contractRecord.Id);
    }

    private Decimal getLast12MProductionVolumeForContract(Contract__c contractRecord) {
        Integer twelveMonths = 12;
        Decimal totalVolume12M = 0;
        for (Id performanceIndicatorId : performanceIndicatorIdsByContractNames.get(getContractName(contractRecord))) {
            if (twelveMonths < 1) {
                return totalVolume12M;
            }
            Performance_Indicator__c performanceIndicator = performanceIndicatorsByIds.get(performanceIndicatorId);
            totalVolume12M = add(totalVolume12M, performanceIndicator.Total_Production_Volume__c);
            twelveMonths--;
        }
        return totalVolume12M;
    }

    private Decimal add(Decimal fieldValue, Decimal toAdd) {
        if (fieldValue != null && toAdd != null) {
            return fieldValue += toAdd;
        } else if (toAdd == null) {
            return fieldValue;
        } else {
            return toAdd;
        }
    }

    private Decimal addWithCheck(Decimal fieldValue, Decimal toAdd) {
        if (toAdd != null) {
            return add(fieldValue, toAdd);
        }
        return fieldValue;
    }

    private Decimal multiply(Decimal value1, Decimal value2) {
        return value1 * value2;
    }

    private Decimal multiplyWithCheck(Decimal value1, Decimal value2) {
        if (value1 != null && value2 != null) {
            return multiply(value1, value2);
        }
        return null;
    }

    private Boolean checkIfCanBeDivisor(Decimal value) {
        return value != null && value != 0;
    }

    private Boolean validatePIRecord(Performance_Indicator__c performanceIndicator) {
        for (SObjectField field : performanceIndicatorRequiredFields) {
            if (performanceIndicator.get(field) == null) {
                corruptedPerformanceIndicatorsByIds.put(performanceIndicator.Id, field);
                return false;
            }
        }
        return true;
    }

    private void checkForConsecutiveVersions(Date firstDayOfLastYear, Contract__c contractRecord) {
        List<String> contractNameElements = contractRecord.Name.split('/');
        String contractName = contractNameElements[0];
        Integer contractVersion = Integer.valueOf(contractNameElements[1]);
        if (contractNameElements.size() > 1) {
            if (contractVersion > 1 && contractRecord.Start_Date__c > firstDayOfLastYear) {
                contractsThatShouldHavePreviousVersions.add(contractName);
            } else {
                contractsThatShouldHavePreviousVersions.remove(contractName);
            }
        }
    }

    private Date getNewestApplicableEndDateForContract(Date endDate) {
        if (endDate != null && getFirstDayOfMonth(endDate) < getFirstDayOfMonth(Date.today())) {
            return getFirstDayOfMonth(endDate);
        }
        return getFirstDayOfMonth(Date.today());
    }

    private Date getFirstDayOfMonth(Date d) {
        if (d == null) {
            return d;
        }
        return Date.newInstance(d.year(), d.month(), 1);
    }
/*UNDO
    private void wipeOutPreviousContract(String contractName) {
        if (contractVersionsByName.get(contractName).size() > 1) {
            Contract__c contractRecord = relatedContractsByIds.get(contractVersionsByName.get(contractName)[1]);
            contractRecord.of_all_generation_units__c = null;
            contractRecord.of_P51_generation_units__c = null;
            contractRecord.Total_Capacity_CY__c = null;
            contractRecord.Total_Capacity_LY__c = null;
            contractRecord.Total_Production_Volume_CY__c = null;
            contractRecord.Total_Production_Volume_LY__c = null;
            contractRecord.Total_DownReg_volume_CY__c = null;
            contractRecord.Total_DownReg_volume_LY__c = null;
            contractRecord.Cashflow_DownReg_Compensation_CY__c = null;
            contractRecord.Cashflow_DownReg_Compensation_LY__c = null;
            contractRecord.Cashflow_Production_Compensation_CY__c = null;
            contractRecord.Cashflow_Production_Compensation_LY__c = null;
            contractRecord.P51_Capacity_CY__c = null;
            contractRecord.P51_Capacity_LY__c = null;
            contractRecord.Sales_Profit_CY__c = null;
            contractRecord.Sales_Profit_LY__c = null;
            contractRecord.Dispatch_Profit_CY__c = null;
            contractRecord.Dispatch_Profit_LY__c = null;
            contractRecord.Margin_Sales_CY__c = null;
            contractRecord.Margin_Dispatch_CY__c = null;
            contractRecord.Margin_51_Flexibility_CY__c = null;
            contractRecord.Margin_non_compensated_51_CY__c = null;
            contractRecord.Market_Value_CY__c = null;
            contractRecord.Market_Value_Difference_CY__c = null;
            contractRecord.Market_Value_Difference_12M__c = null;
            contractRecord.Total_Margin_CY__c = null;
            contractRecord.Total_Profit_LY__c = null;
            contractRecord.Total_Profit_CY__c = null;
            calculatedContractsByIds.put(contractRecord.Id, contractRecord);
        }
    }

 */
    private List<Account> retrieveDetailedScope(Set<Id> accountIds) {
        return [
                SELECT Id, Negotiating_Party__c,
                (SELECT Id, Negotiating_Party__c FROM Accounts1__r),
                (SELECT Id, Status__c FROM Contracts__r),
                (SELECT Id FROM Offers__r WHERE Status__c NOT IN ('Closed Lost', 'Closed Won')),
                (SELECT Id FROM Opportunities WHERE StageName NOT IN ('Closed Lost', 'Closed Won'))
                FROM Account WHERE Id IN :accountIds
        ];
    }
    private Map<Id,counterWrapper> calculateCounterWrappers() {
        Map<Id,counterWrapper> counterWrappersByAccountIds = new Map<Id, counterWrapper>();
        for(Account accountToCount: detailedAccountScope) {
            counterWrapper accountCounterWrapper = null;
            counterWrapper negotiatingPartyCounterWrapper = null;
            if(counterWrappersByAccountIds.containsKey(accountToCount.Id)) {
                accountCounterWrapper = counterWrappersByAccountIds.get(accountToCount.Id);
            } else {
                accountCounterWrapper = new counterWrapper();
                counterWrappersByAccountIds.put(accountToCount.Id, accountCounterWrapper);
            }
            if(accountToCount.Negotiating_Party__c != null)  {
                if(counterWrappersByAccountIds.containsKey(accountToCount.Negotiating_Party__c)) {
                    negotiatingPartyCounterWrapper = counterWrappersByAccountIds.get(accountToCount.Negotiating_Party__c);
                } else {
                    negotiatingPartyCounterWrapper = new counterWrapper();
                    counterWrappersByAccountIds.put(accountToCount.Negotiating_Party__c, negotiatingPartyCounterWrapper);
                }
            }
            for(Contract__c pendingContract : accountToCount.Contracts__r) {
                switch on pendingContract.Status__c {
                    when 'Draft', 'In Approval' {
                        accountCounterWrapper.countOfPendingContracts++;
                        if(accountToCount.Negotiating_Party__c != null) {
                            negotiatingPartyCounterWrapper.countOfPendingContracts++;
                        }
                    }
                    when 'Expired' {
                        accountCounterWrapper.countOfExpiredContracts++;
                        if(accountToCount.Negotiating_Party__c != null) {
                            negotiatingPartyCounterWrapper.countOfExpiredContracts++;
                        }
                    }
                    when 'Active' {
                        accountCounterWrapper.countOfActiveContracts++;
                        if(accountToCount.Negotiating_Party__c != null) {
                            negotiatingPartyCounterWrapper.countOfActiveContracts++;
                        }
                    }
                }
            }
            for(Offer__c activeOffer : accountToCount.Offers__r) {
                accountCounterWrapper.countOfActiveOffers++;
                if(accountToCount.Negotiating_Party__c != null) {
                    negotiatingPartyCounterWrapper.countOfActiveOffers++;
                }
            }
            for(Opportunity activeOpportunity : accountToCount.Opportunities) {
                accountCounterWrapper.countOfActiveOpportunities++;
                if(accountToCount.Negotiating_Party__c != null) {
                    negotiatingPartyCounterWrapper.countOfActiveOpportunities++;
                }
            }
        }
        return counterWrappersByAccountIds;
    }

    private class counterWrapper {
        Integer countOfPendingContracts;
        Integer countOfActiveOffers;
        Integer countOfActiveOpportunities;
        Integer countOfExpiredContracts;
        Integer countOfActiveContracts;

        counterWrapper() {
            countOfActiveOffers = 0;
            countOfActiveOpportunities = 0;
            countOfPendingContracts = 0;
            countOfExpiredContracts = 0;
            countOfActiveContracts = 0;
        }
    }
}
/****************************************************************************************************
* Class msSubmeterController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   27.09.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)        27.09.2018      	    Init version.
*   * Christian Gottlieb (mindsquare GmbH)      10.05.2019              V2 for New Core Model
*   * Christian Gottlieb (mindsquare GmbH)      29.05.2019              Redone to fit new Submeter Component
*   * Steffen Naundorf (mindsquare GmbH)        01.04.2020              Refactored validity logic, everything in backend
*****************************************************************************************************/

public without sharing class msSubmeterController {
    private static List<FeatureEnablement__c> featureEnablements;
    private static List<PortalSettings__c> portalSettings = [SELECT Id, Integer__c FROM PortalSettings__c WHERE Name = 'Submeter - Edit last x months'];

    @AuraEnabled
    public static SubmeterResultWrapper addSubmeter(List<Id> meterIds, List<SubmeterSeries> updateSeries, String mode, Id meterId, String yearString) {
        for (String tempMeterId : meterIds) {
            msUtility.checkObjectAccess(tempMeterId, 'Meter__c');
        }

        BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Correction');
        Map<String, Object> logData = new Map<String, Object>();

        Map<Id, Map<Date, MonthValidity>> monthsValidityMap = getMonthsValidity(meterIds);
        System.HttpResponse resultCorrection;
        SubmeterResultWrapper result;

        List<Meter2GenerationUnitRelationship__c> generationUnitRelationships = [
                SELECT Id, Meter__c, Generator_Unit__c, Generator_Unit__r.Portfolio_ID__c, Meter__r.Portfolio_ID__c, Meter__r.Parent_Meter__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Meter__c IN :meterIds OR Meter__r.Parent_Meter__c IN :meterIds
        ];

        Set<String> genUnitPortfoilioIds = new Set<String>();
        Map<String, Id> portfolioIdToMeterIdMap = new Map<String, Id>();
        for (Meter2GenerationUnitRelationship__c genUnitRelItem : generationUnitRelationships) {
            genUnitPortfoilioIds.add(genUnitRelItem.Generator_Unit__r.Portfolio_ID__c);
            portfolioIdToMeterIdMap.put(genUnitRelItem.Generator_Unit__r.Portfolio_ID__c, genUnitRelItem.Meter__c);
            if (genUnitRelItem.Meter__r.Parent_Meter__c != null) {
                portfolioIdToMeterIdMap.put(genUnitRelItem.Generator_Unit__r.Portfolio_ID__c, genUnitRelItem.Meter__r.Parent_Meter__c);
            }
        }
        try {
            User userContact = [SELECT Contact.Name FROM User WHERE Id = :UserInfo.getUserId()];
            String contactName = userContact.Contact.Name;
            Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
            List<TimeSeries> newValues = new List<TimeSeries>();

            Datetime now = Datetime.now();
            String timeNow = '' + now;
            timeNow = timeNow.replace(' ', 'T') + 'Z';
            TimeSeries tmp = new TimeSeries();
            TimeEntry updateEntry = new TimeEntry();
            for (SubmeterSeries genUnitSeries : updateSeries) {
                Id tempMeterId = portfolioIdToMeterIdMap.get(genUnitSeries.portfolioId.replace('/', ''));

                if (genUnitPortfoilioIds.contains(genUnitSeries.portfolioId.replace('/', ''))) {
                    tmp = new TimeSeries();
                    tmp.name = genUnitSeries.portfolioId + apiSettings.Submeter_Timeseries_Path__c;
                    tmp.values = new List<TimeEntry>();
                    for (SubmeterEntry monthEntry : genUnitSeries.values) {
                        Datetime startDatetime = msUtility.parseUtcDateTime(monthEntry.startDate);
                        Date startDate = Date.newInstance(startDatetime.year(), startDatetime.month(), 1);
                        if (monthsValidityMap.get(tempMeterId).get(startDate).isDisabled == false
                                && monthEntry.value != 'null'
                                && monthEntry.value != null) {
                            updateEntry = new TimeEntry();
                            updateEntry.timeDate = monthEntry.startDate;
                            updateEntry.value = monthEntry.value;
                            updateEntry.metadata = new TimeChangeData();
                            updateEntry.metadata.modifiedUser = contactName;
                            updateEntry.metadata.modifiedDate = timeNow;
                            tmp.values.add(updateEntry);
                        }
                    }
                    if (tmp.values.size() != 0) {
                        newValues.add(tmp);
                    }
                }
            }

            String endpointCorrection = apiSettings.Submeter_Endpoint_Write__c;
            String bodyCorrection = JSON.serialize(newValues).replaceAll('timeDate', 'time');
            resultCorrection = msUtility.getHttp(endpointCorrection, bodyCorrection, 'POST');
            logEvent.MeterId__c = meterIds[0];
            logData.put('updateSeries', updateSeries);
            logData.put('mode', mode);
            logData.put('meterId', meterIds);
            logData.put('endpoint', endpointCorrection);
            logData.put('body', bodyCorrection);
            logData.put('method', 'POST');
            logData.put('status', resultCorrection.getStatusCode());
            if (resultCorrection.getStatusCode() != 200) {
                logEvent.IsError__c = true;
                logData.put('resultBody', resultCorrection.getBody());
            }

            result = retrieveSubmeter(meterId, yearString);

            if (resultCorrection.getStatusCode() == 200) {
                Set<Generation_Unit__c> generationUnits = new Set<Generation_Unit__c>();
                for (Meter2GenerationUnitRelationship__c tmpM2GR : generationUnitRelationships) {
                    Generation_Unit__c tmpGU = new Generation_Unit__c();
                    tmpGU.Id = tmpM2GR.Generator_Unit__c;
                    if (mode == 'yearly') {
                        tmpGU.LastSubmeterValuesYearly__c = now;
                    } else {
                        tmpGU.LastSubmeterValuesMonthly__c = now;
                    }
                    generationUnits.add(tmpGU);
                }
                update new List<Generation_Unit__c>(generationUnits);
            }
        } catch (Exception e) {
            logEvent = msUtility.handleException(logEvent, e);
        }

        logEvent.DataJson__c = JSON.serialize(logData);
        msUtility.publishEvent(logEvent);
        return result;
    }

    @AuraEnabled
    public static SubmeterResultWrapper retrieveSubmeter(Id meterId, String yearString) {
        msUtility.checkObjectAccess(meterId, 'Meter__c');
        SubmeterResultWrapper resultWrapper = new SubmeterResultWrapper();

        Integer year = Integer.valueOf(yearString);
        Map<Date, MonthValidity> monthsValidityMap = getMonthsValidity(new List<Id>{
                meterId
        }).get(meterId);
        Set<Date> startDates = monthsValidityMap.keySet();
        Set<Integer> years = new Set<Integer>();
        for (Date startDate : startDates) {
            years.add(startDate.year());
        }
        resultWrapper.years = new List<Integer>(years);
        if (resultWrapper.years.contains(year) == false) {
            year = resultWrapper.years[0];
        }

        List<Meter2GenerationUnitRelationship__c> generationUnitRelationships = getGenUnitRelationships(new Set<Id>{
                meterId
        }, year);

        Map<String, String>portfolioIdToGenUnitName = new Map<String, String>();
        Map<String, String>portfolioIdToManufacturerNumber = new Map<String, String>();

        msUtility.FeatureSetting meterFeatureSetting = msUtility.getMeterFeatures(new Meter__c(Id = meterId));
        if (meterFeatureSetting.submeterView) {
            Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
            Set<String> portfolioIdStrings = new Set<String>();

            for (Meter2GenerationUnitRelationship__c relItem : generationUnitRelationships) {
                portfolioIdStrings.add('"/' + relItem.Generator_Unit__r.Portfolio_ID__c + apiSettings.Submeter_Timeseries_Path__c + '"');
                portfolioIdToGenUnitName.put(relItem.Generator_Unit__r.Portfolio_ID__c, relItem.Generator_Unit__r.Name);
                portfolioIdToManufacturerNumber.put(relItem.Generator_Unit__r.Portfolio_ID__c, relItem.Generator_Unit__r.Manufacturer_Number__c);
            }
            List<String>portfolioIdStringsList = new List<String>();
            portfolioIdStringsList.addAll(portfolioIdStrings);

            String genUnitIdsBodyCall = String.join(portfolioIdStringsList, ',');

            String endpoint = apiSettings.Submeter_Endpoint_Read__c;
            String body = '{"names": [' + genUnitIdsBodyCall + '],' +
                    '"begin": "' + getTimeDateTimeStartOfMonth(year, 1) + '",' +
                    '"end": "' + getTimeDateTimeEndOfMonth(year, 12) + '"}';
            System.HttpResponse resultDefault = msUtility.getHttp(endpoint, body, 'POST');
            if (resultDefault.getStatusCode() != 200) {
                BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Read');
                Map<String, Object> logData = new Map<String, Object>();
                logEvent.IsError__c = true;
                logEvent.MeterId__c = meterId;
                logData.put('year', year);
                logData.put('endpoint', endpoint);
                logData.put('body', body);
                logData.put('method', 'POST');
                logData.put('statusCode', resultDefault.getStatusCode());
                logData.put('resultBody', resultDefault.getBody());
                logEvent.DataJson__c = JSON.serialize(logData);

                msUtility.publishEvent(logEvent);
                return null;
            }

            String resultBody = resultDefault.getBody().replaceAll('time', 'timeDate');
            List<TimeSeries> listTimeseriesDefault = (List<TimeSeries>) System.JSON.deserializeStrict(resultBody, List<TimeSeries>.class);

            List<TimeEntry> defaultValues = new List<TimeEntry>();
            List<SubmeterSeries> results = new List<SubmeterSeries>();
            List<SubmeterEntry> values = new List<SubmeterEntry>();
            SubmeterEntry tmp = new SubmeterEntry();
            Map<String, SubmeterEntry> mapOfMonthlyEntries = new Map<String, SubmeterEntry>();
            Map<String, Datetime> mapOfMonthlyEntryUpdateTime = new Map<String, Datetime>();
            Datetime updateTime = null;
            SubmeterSeries tmpSeries = new SubmeterSeries();

            for (Integer i = 0; i < listTimeseriesDefault.size(); i++) {
                defaultValues = listTimeseriesDefault[i].values;
                values = new List<SubmeterEntry>();

                mapOfMonthlyEntries = new Map<String, msSubmeterController.SubmeterEntry>();
                mapOfMonthlyEntryUpdateTime = new Map<String, Datetime>();
                for (Integer k = 1; k < (12 + 1); k++) {
                    tmp = new SubmeterEntry();
                    tmp.startDate = getTimeDateTimeStartOfMonth(year, k);
                    tmp.endDate = getTimeDateTimeEndOfMonth(year, k);
                    Datetime startDatetime = msUtility.parseUtcDateTime(tmp.startDate);
                    Date startDate = Date.newInstance(startDatetime.year(), startDatetime.month(), 1);
                    tmp.disabled = monthsValidityMap.get(startDate).isDisabled;
                    mapOfMonthlyEntries.put(tmp.startDate, tmp);
                    mapOfMonthlyEntryUpdateTime.put(tmp.startDate, msUtility.parseUtcDateTime('1986-04-26T01:23:00Z'));
                }
                for (Integer j = 0; j < defaultValues.size(); j++) {

                    tmp = new SubmeterEntry();
                    if (defaultValues[j].timeDate != null && defaultValues[j].value != 'NaN') {
                        tmp.startDate = defaultValues[j].timeDate + 'Z';
                        tmp.endDate = defaultValues[j].timeDate + 'Z';
                        tmp.value = defaultValues[j].value;
                        Datetime startDatetime = msUtility.parseUtcDateTime(tmp.startDate);
                        Date startDate = Date.newInstance(startDatetime.year(), startDatetime.month(), 1);
                        tmp.disabled = monthsValidityMap.get(startDate).isDisabled;
                        updateTime = msUtility.parseUtcDateTime(defaultValues[j].metadata.modifiedDate);

                        if ((mapOfMonthlyEntryUpdateTime.keySet().contains(tmp.startDate)
                                && mapOfMonthlyEntryUpdateTime.get(tmp.startDate) < updateTime)
                                || !mapOfMonthlyEntryUpdateTime.keySet().contains(tmp.startDate)) {

                            mapOfMonthlyEntries.put(tmp.startDate, tmp);
                            mapOfMonthlyEntryUpdateTime.put(tmp.startDate, updateTime);
                        }
                    }
                }
                tmpSeries = new SubmeterSeries();
                tmpSeries.values = new List<SubmeterEntry>();
                tmpSeries.name = portfolioIdToGenUnitName.get(listTimeseriesDefault[i].name.remove(apiSettings.Submeter_Timeseries_Path__c).remove('/'));
                tmpSeries.serialNumber = portfolioIdToManufacturerNumber.get(listTimeseriesDefault[i].name.remove(apiSettings.Submeter_Timeseries_Path__c).remove('/'));
                tmpSeries.portfolioId = listTimeseriesDefault[i].name.replace(apiSettings.Submeter_Timeseries_Path__c, '');
                for (String monthlyIndex : mapOfMonthlyEntries.keySet()) {
                    tmpSeries.values.add(mapOfMonthlyEntries.get(monthlyIndex));
                }
                results.add(tmpSeries);
            }
            resultWrapper.values = results;

            return resultWrapper;
        } else {
            return null;
        }
    }


    @AuraEnabled
    public static Map<String, List<SubmeterSeries>> retrieveSubmeterForCSV(List<Id> meterIds, String yearString) {
        for (Id meterId : meterIds) {
            msUtility.checkObjectAccess(meterId, 'Meter__c');
        }

        Map<Id, Map<Date, MonthValidity>> monthsValidityMap = getMonthsValidity(meterIds);
        Map<String, List<SubmeterSeries>> results = new Map<String, List<SubmeterSeries>>();
        Integer year = Integer.valueOf(yearString);

        List<Meter2GenerationUnitRelationship__c> generationUnitRelationships = getGenUnitRelationships(new Set<Id>(meterIds), year);
        Map<String, Meter2GenerationUnitRelationship__c> portfolioIdToGenUnitRel = new Map<String, Meter2GenerationUnitRelationship__c>();
        Set<String> portfolioIdStrings = new Set<String>();

        Map<String, String> portfolioIdToManufacturerNumber = new Map<String, String>();
        Map<String, Id> portfolioIdToMeterIdMap = new Map<String, Id>();
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        for (Meter2GenerationUnitRelationship__c relItem : generationUnitRelationships) {
            if (relItem.Generator_Unit__r.Portfolio_ID__c != null) {
                portfolioIdStrings.add('"/' + relItem.Generator_Unit__r.Portfolio_ID__c + apiSettings.Submeter_Timeseries_Path__c + '"');
                portfolioIdToGenUnitRel.put(relItem.Generator_Unit__r.Portfolio_ID__c, relItem);
                portfolioIdToManufacturerNumber.put(relItem.Generator_Unit__r.Portfolio_ID__c, relItem.Generator_Unit__r.Manufacturer_Number__c);
            }
            portfolioIdToMeterIdMap.put(relItem.Generator_Unit__r.Portfolio_ID__c, relItem.Meter__c);
            if (relItem.Meter__r.Parent_Meter__c != null) {
                portfolioIdToMeterIdMap.put(relItem.Generator_Unit__r.Portfolio_ID__c, relItem.Meter__r.Parent_Meter__c);
            }
        }

        List<String>portfolioIdStringsList = new List<String>();
        portfolioIdStringsList.addAll(portfolioIdStrings);

        String genUnitIdsBodyCall = String.join(portfolioIdStringsList, ',');

        String endpoint = apiSettings.Submeter_Endpoint_Read__c;
        String body = '{"names": [' + genUnitIdsBodyCall + '],' +
                '"begin": "' + getTimeDateTimeStartOfMonth(year, 1) + '",' +
                '"end": "' + getTimeDateTimeEndOfMonth(year, 12) + '"}';
        System.HttpResponse resultDefault = msUtility.getHttp(endpoint, body, 'POST');
        if (resultDefault.getStatusCode() != 200) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Read CSV');
            Map<String, Object> logData = new Map<String, Object>();
            logEvent.IsError__c = true;
            logEvent.MeterId__c = meterIds[0];
            logData.put('year', year);
            logData.put('endpoint', endpoint);
            logData.put('body', body);
            logData.put('method', 'POST');
            logData.put('statusCode', resultDefault.getStatusCode());
            logData.put('resultBody', resultDefault.getBody());
            logEvent.DataJson__c = JSON.serialize(logData);

            msUtility.publishEvent(logEvent);
            return null;
        }

        String resultBody = resultDefault.getBody().replaceAll('time', 'timeDate');
        List<TimeSeries> listTimeseriesDefault = (List<TimeSeries>) System.JSON.deserializeStrict(resultBody, List<TimeSeries>.class);

        List<TimeEntry> defaultValues = new List<TimeEntry>();
        List<SubmeterEntry> values = new List<SubmeterEntry>();
        SubmeterEntry tmp = new SubmeterEntry();
        Map<String, SubmeterEntry> mapOfMonthlyEntries = new Map<String, SubmeterEntry>();
        Map<String, Datetime> mapOfMonthlyEntryUpdateTime = new Map<String, Datetime>();
        Datetime updateTime = null;
        SubmeterSeries tmpSeries = new SubmeterSeries();

        for (Integer i = 0; i < listTimeseriesDefault.size(); i++) {
            String portfolioId = listTimeseriesDefault[i].name.remove(apiSettings.Submeter_Timeseries_Path__c).remove('/');
            Meter2GenerationUnitRelationship__c m2gRel = portfolioIdToGenUnitRel.get(portfolioId);
            Id meterId = portfolioIdToMeterIdMap.get(portfolioId);

            defaultValues = listTimeseriesDefault[i].values;
            values = new List<SubmeterEntry>();
            mapOfMonthlyEntries = new Map<String, msSubmeterController.SubmeterEntry>();
            mapOfMonthlyEntryUpdateTime = new Map<String, Datetime>();

            for (Integer k = 1; k < (12 + 1); k++) {
                tmp = new SubmeterEntry();
                tmp.startDate = getTimeDateTimeStartOfMonth(year, k);
                tmp.endDate = getTimeDateTimeEndOfMonth(year, k);
                tmp.value = '';
                Datetime startDatetime = msUtility.parseUtcDateTime(tmp.startDate);
                Date startDate = Date.newInstance(startDatetime.year(), startDatetime.month(), 1);
                System.debug(meterId);
                System.debug(monthsValidityMap.get(meterId));
                System.debug(startDate);
                System.debug('FIND ME: ' + startDate + ' ' + portfolioId + ' ' + monthsValidityMap.get(meterId).get(startDate).isDisabled);
                tmp.disabled = monthsValidityMap.get(meterId).get(startDate).isDisabled;
                mapOfMonthlyEntries.put(tmp.startDate, tmp);
                mapOfMonthlyEntryUpdateTime.put(tmp.startDate, msUtility.parseUtcDateTime('1986-04-26T01:23:00Z'));
            }
            for (Integer j = 0; j < defaultValues.size(); j++) {
                tmp = new SubmeterEntry();
                if (defaultValues[j].timeDate != null && defaultValues[j].value != 'NaN') {
                    tmp.startDate = defaultValues[j].timeDate + 'Z';
                    tmp.endDate = defaultValues[j].timeDate + 'Z';
                    tmp.value = defaultValues[j].value;
                    Datetime startDatetime = msUtility.parseUtcDateTime(tmp.startDate);
                    Date startDate = Date.newInstance(startDatetime.year(), startDatetime.month(), 1);
                    System.debug('FIND ME2: ' + tmp.startDate + ' ' + portfolioId + ' ' + monthsValidityMap.get(meterId).get(startDate).isDisabled);
                    tmp.disabled = monthsValidityMap.get(meterId).get(startDate).isDisabled;
                    updateTime = msUtility.parseUtcDateTime(defaultValues[j].metadata.modifiedDate);

                    if ((mapOfMonthlyEntryUpdateTime.keySet().contains(tmp.startDate)
                            && mapOfMonthlyEntryUpdateTime.get(tmp.startDate) < updateTime)
                            || !mapOfMonthlyEntryUpdateTime.keySet().contains(tmp.startDate)) {

                        mapOfMonthlyEntries.put(tmp.startDate, tmp);
                        mapOfMonthlyEntryUpdateTime.put(tmp.startDate, updateTime);
                    }
                }
            }

            if (m2gRel != null) {
                tmpSeries = new SubmeterSeries();
                tmpSeries.values = new List<SubmeterEntry>();
                tmpSeries.name = m2gRel.Generator_Unit__r.Name;
                tmpSeries.portfolioId = listTimeseriesDefault[i].name.replace(apiSettings.Submeter_Timeseries_Path__c, '').replace('/', '');
                tmpSeries.serialNumber = portfolioIdToManufacturerNumber.get(listTimeseriesDefault[i].name.remove(apiSettings.Submeter_Timeseries_Path__c).remove('/'));
                for (String monthlyIndex : mapOfMonthlyEntries.keySet()) {
                    tmpSeries.values.add(mapOfMonthlyEntries.get(monthlyIndex));
                }

                String meterName = m2gRel.Meter__r.Name;
                if (m2gRel.Meter__r.Parent_Meter__c != null) {
                    meterName = m2gRel.Meter__r.Parent_Meter__r.Name;
                }

                List<SubmeterSeries> seriesOfMeter = results.get(meterName);
                if (seriesOfMeter == null) {
                    seriesOfMeter = new List<SubmeterSeries>();
                }
                seriesOfMeter.add(tmpSeries);

                results.put(meterName, seriesOfMeter);
            }
        }
        return results;
    }

    public static Map<Id, Map<Date, MonthValidity>> getMonthsValidity(List<Id> meterIds) {
        Date today = Date.today();
        if (featureEnablements == null) {
            featureEnablements = [
                    SELECT Meter__c, Contract__c, Feature__c, Start__c, End__c, Valid_from__c, Valid_to__c, Meter__r.Parent_Meter__c
                    FROM FeatureEnablement__c
                    WHERE Valid_from__c <= :today
                    AND Valid_to__c >= :today
                    AND Feature__c = 'submeter_edit_monthly'
                    AND (Meter__c IN :meterIds OR Meter__r.Parent_Meter__c IN :meterIds)
                    AND (Contact__c = NULL OR Contact__c = :msUtility.getUserDetails().contact.Id)
            ];
        }
        Integer enableXMonth = -1;
        if (portalSettings.size() > 0 && portalSettings[0].Integer__c != null) {
            enableXMonth = -1 * Integer.valueOf(portalSettings[0].Integer__c);
        }

        msUtility.UserDetails portalUserSession = msUtility.getUserDetails();
        Date thisYearStart = Date.newInstance(today.year(), 1, 1);
        Date lastYearStart = Date.newInstance(today.addYears(-1).year(), 1, 1);

        List<MeterRegistration__c> meterRegistrations = portalUserSession.meterRegistrations;
        Set<Id> contractIds = new Set<Id>();

        for (MeterRegistration__c regItem : meterRegistrations) {
            contractIds.add(regItem.Contract__c);
        }

        Map<Id, Contract__c> contractMap = msSubmeterUtility.getSubMeterContracts(contractIds);

        Map<String, msUtility.FeatureSetting> featureSettingMap = msUtility.getFeatureSettings();
        Map<Id, Map<Date, MonthValidity>> result = new Map<Id, Map<Date, MonthValidity>>();

        for (MeterRegistration__c tempRegistration : meterRegistrations) {

            Map<Date, MonthValidity> monthValidityMap = result.get(tempRegistration.Meter__c);
            if (monthValidityMap == null) {
                monthValidityMap = new Map<Date, MonthValidity>();
                for (Integer i = 0; i < 24; i++) {
                    Date startDateOfMonth = lastYearStart.addMonths(i);
                    monthValidityMap.put(startDateOfMonth, new MonthValidity(startDateOfMonth));
                }
            }

            if (meterIds.contains(tempRegistration.Meter__c) || meterIds.contains(tempRegistration.Meter__r.Parent_Meter__c)) {
                Contract__c relevantContract = contractMap.get(tempRegistration.Contract__c);
                msUtility.FeatureSetting featureSetting = featureSettingMap.get(tempRegistration.Contract__r.Global_Portal_Market__c);


                for (Date startDateOfMonth : monthValidityMap.keySet()) {
                    MonthValidity monthlyValidityItem = monthValidityMap.get(startDateOfMonth);
                    for (FeatureEnablement__c featureEnablement : featureEnablements) {
                        if (featureEnablement.Start__c <= startDateOfMonth
                                && featureEnablement.End__c >= startDateOfMonth
                                && (featureEnablement.Meter__c == tempRegistration.Meter__c
                                || featureEnablement.Meter__r.Parent_Meter__c == tempRegistration.Meter__r.Parent_Meter__c)) {
                            monthlyValidityItem.isDisabled = false;
                        }
                    }

                    if (tempRegistration.Valid_from__c <= startDateOfMonth
                            && (tempRegistration.Valid_to__c >= startDateOfMonth || tempRegistration.Valid_to__c == null)
                            && (relevantContract.KeepPortalAccessUntil__c == null
                            || relevantContract.KeepPortalAccessUntil__c >= today)) {
                        for (Pricing_Component__c pcItemToCheck : relevantContract.Pricing_Components__r) {
                            if (msSubmeterUtility.isMeterBillingTypePricingComponent(pcItemToCheck)
                                    && pcItemToCheck.Start_Date__c <= startDateOfMonth
                                    && pcItemToCheck.End_Date__c >= startDateOfMonth) {
                                if (startDateOfMonth < thisYearStart
                                        && featureSetting.submeterEditYearly
                                        && (pcItemToCheck.Meter_Billing_Type__c == 'Sub-Meter Yearly'
                                        || pcItemToCheck.Meter_Billing_Type__c == 'Sub-Meter Monthly')
                                        && featureSetting.submeterEditYearlyEnabled) {
                                    monthlyValidityItem.isDisabled = false;

                                }
                                if (startDateOfMonth < today.toStartOfMonth()
                                        && featureSetting.submeterEditMonthly
                                        && startDateOfMonth >= today.toStartOfMonth().addMonths(enableXMonth)
                                        && pcItemToCheck.Meter_Billing_Type__c == 'Sub-Meter Monthly'
                                        && featureSetting.submeterEditMonthlyEnabled) {
                                    monthlyValidityItem.isDisabled = false;
                                }
                            }
                        }
                    }
                }
            }
            result.put(tempRegistration.Meter__c, monthValidityMap);
            if(tempRegistration.Meter__r.Parent_Meter__c != null) {
                Map<Date, MonthValidity> parentMonthValidityMap = result.get(tempRegistration.Meter__r.Parent_Meter__c);
                if(parentMonthValidityMap == null) {
                    parentMonthValidityMap = new Map<Date, MonthValidity>();
                    for (Integer i = 0; i < 24; i++) {
                        Date startDateOfMonth = lastYearStart.addMonths(i);
                        parentMonthValidityMap.put(startDateOfMonth, new MonthValidity(startDateOfMonth));
                        parentMonthValidityMap.get(startDateOfMonth).isDisabled = monthValidityMap.get(startDateOfMonth).isDisabled;
                    }
                } else {
                    for (Integer i = 0; i < 24; i++) {
                        Date startDateOfMonth = lastYearStart.addMonths(i);
                        if(!monthValidityMap.get(startDateOfMonth).isDisabled) {
                            parentMonthValidityMap.get(startDateOfMonth).isDisabled = monthValidityMap.get(startDateOfMonth).isDisabled;
                        }
                    }
                }
                result.put(tempRegistration.Meter__r.Parent_Meter__c, parentMonthValidityMap);
            }
        }
        return result;
    }




    public static String getTimeDateTimeStartOfMonth(Integer year, Integer month) {
        Datetime timeDate = Datetime.newInstanceGmt(year, month, 1, 0, 0, 0);
        return ('' + timeDate).replace(' ', 'T') + 'Z';
    }
    public static String getTimeDateTimeEndOfMonth(Integer year, Integer month) {
        Datetime timeDate = Datetime.newInstanceGmt(year, month, 1, 0, 0, 0).addMonths(1).addSeconds(-1);
        return ('' + timeDate).replace(' ', 'T') + 'Z';
    }
    private static List<Meter2GenerationUnitRelationship__c> getGenUnitRelationships(Set<Id> meterIds, Integer year) {
        Date startDate = Date.newInstance(year, 1, 1);
        Date endDate = Date.newInstance(year, 12, 31);

        return [
                SELECT
                        Generator_Unit__r.Portfolio_ID__c,
                        Generator_Unit__r.Name,
                        Generator_Unit__r.Manufacturer_Number__c,
                        Meter__c, Meter__r.Name,
                        Meter__r.Parent_Meter__c,
                        Meter__r.Parent_Meter__r.Name
                FROM Meter2GenerationUnitRelationship__c
                WHERE (Meter__c IN :meterIds OR Meter__r.Parent_Meter__c IN :meterIds)
                AND Valid_from__c <= :endDate
                AND (Valid_to__c = NULL OR Valid_to__c >= :startDate)
        ];
    }
    public class TimeSeries {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public List<TimeEntry> values { get; set; }
    }
    public class TimeEntry {
        @AuraEnabled public String timeDate { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public TimeChangeData metadata { get; set; }
    }
    public class TimeChangeData {
        @AuraEnabled public String modifiedUser { get; set; }
        @AuraEnabled public String modifiedDate { get; set; }
    }

    public class SubmeterSeries {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String serialNumber { get; set; }
        @AuraEnabled public String portfolioId { get; set; }
        @AuraEnabled public List<SubmeterEntry> values { get; set; }
    }
    public class SubmeterEntry {
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String endDate { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Boolean disabled { get; set; }
    }
    public class MonthValidity {
        @AuraEnabled public Date startOfMonth { get; set; }
        @AuraEnabled public Boolean isDisabled { get; set; }
        public MonthValidity(Date startDate) {
            startOfMonth = startDate;
            isDisabled = true;
        }
    }
    public class SubmeterResultWrapper {
        @AuraEnabled public List<SubmeterSeries> values { get; set; }
        @AuraEnabled public List<Integer> years { get; set; }
        @AuraEnabled public Map<String, String> labels { get; set; }

        public SubmeterResultWrapper() {
            labels = new Map<String, String>{
                    'msDatepickerYear' => Label.msDatepickerYear,
                    'msSubmeterMonth' => Label.msSubmeterMonth,
                    'msSubmeterTableEEGPlantKey' => Label.msSubmeterTableEEGPlantKey,
                    'mMasterDataTableManufacturer4' => Label.mMasterDataTableManufacturer4,
                    'msSubmeterTableSum' => Label.msSubmeterTableSum,
                    'msSubmeterCSVName' => Label.msSubmeterCSVName,
                    'msSubmeterCSVType' => Label.msSubmeterCSVType,
                    'msSubmeterMonth' => Label.msSubmeterMonth,
                    'msSubmeterTableEEGPlantKey' => Label.msSubmeterTableEEGPlantKey,
                    'mMasterDataTableManufacturer4' => Label.mMasterDataTableManufacturer4,
                    'msSubmeterMonth' => Label.msSubmeterMonth,
                    'msSubmeterTableSum' => Label.msSubmeterTableSum,
                    'msToastError' => Label.msToastError,
                    'msToastSuccess' => Label.msToastSuccess
            };
        }
    }
}
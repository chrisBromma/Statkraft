/****************************************************************************************************
* Class msNonavailabilitiesController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   24.08.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   24.08.2018      	    Init version.
*****************************************************************************************************/

public with sharing class msNonavailabilitiesController {

    @AuraEnabled
    public static OutagesWrapper getDowntimes(Id meterId) {
        msUtility.checkObjectAccess(meterId, 'Meter__c');
        msUtility.checkFeatureAccess(meterId, 'isDowntime');

        OutagesWrapper result = new OutagesWrapper();
        result.generationUnits = getGenUnits(meterId);

        Datetime now = Datetime.now();
        Integer lastXDays = 21;
        List<PortalSettings__c> setting = [SELECT Integer__c FROM PortalSettings__c WHERE Name = 'Outages - Show last x days'];
        if (setting.size() > 0 && setting[0].Integer__c != null) {
            lastXDays = setting[0].Integer__c.intValue();
        }
        Datetime startTime = now.date().addDays(-1 * lastXDays);

        Meter__c meter = [SELECT Id, Name, Country__c, RecordType.DeveloperName, Portfolio_ID__c FROM Meter__c WHERE Id = :meterId];
        msUtility.FeatureSetting featureSetting = msUtility.getMeterFeatures(meter);
        if (featureSetting.isDowntime == false) {
            throw new AuraHandledException('Operation is not allowed for this meter ' + meter.Portfolio_ID__c);
        }

        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        String endpoint = apiSettings.Downtimes_Endpoint__c + '?entityId=' + meter.Portfolio_ID__c + '&startDate=' + msUtility.utcDateToString(startTime);
        HttpResponse response = msUtility.getHttp(endpoint, null, 'GET');
        if (response.getStatusCode() != 200) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Read CSV');
            Map<String, Object> logData = new Map<String, Object>();
            logEvent.IsError__c = true;
            logEvent.MeterId__c = meterId;
            logData.put('endpoint', endpoint);
            logData.put('method', 'GET');
            logData.put('statusCode', response.getStatusCode());
            logData.put('resultBody', response.getBody());
            logEvent.DataJson__c = JSON.serialize(logData);

            msUtility.publishEvent(logEvent);
            return null;
        }

        String body = response.getBody();
        List<Outage> outages = (List<Outage>) JSON.deserialize(body, List<Outage>.class);

        Map<String, String> outageValueToLabelMap = new Map<String, String>();
        for (PicklistEntry outageEntry : getOutageReasonPicklistEntries()) {
            outageValueToLabelMap.put(outageEntry.value, outageEntry.label);
        }
        for (Outage outageItem : outages) {
            outageItem.beforeStart = outageItem.startDate > now;
            outageItem.beforeEnd = outageItem.endDate > now;
            outageItem.isCurrent = outageItem.startDate < now && outageItem.endDate > now;
            if (outageValueToLabelMap.keySet().contains(outageItem.reason)) {
                outageItem.reasonLabel = outageValueToLabelMap.get(outageItem.reason);
            } else {
                outageItem.reasonLabel = outageItem.reason;
            }

            if (outageItem.generators != null && outageItem.generators.size() > 0) {
                outageItem.affectedArea = 'Single_units';
                outageItem.availableGenerators = result.generationUnits.size() - outageItem.generators.size();
            } else if (outageItem.level > 0) {
                outageItem.affectedArea = 'Partial';
                outageItem.availableGenerators = 0;
            } else {
                outageItem.affectedArea = 'Entire_plant';
                outageItem.availableGenerators = 0;
            }
        }
        result.outages = outages;
        result.outageReasonOptions = getOutageReasons(meterId);
        return result;
    }

    public static List<Generation_Unit__c> getGenUnits(Id meterId) {
        Date today = Date.today();
        List<Meter2GenerationUnitRelationship__c> meter2GenerationUnitRelationships = [
                SELECT Id, Generator_Unit__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE (Meter__c = :meterId
                OR Meter__r.Parent_Meter__c = :meterId)
                AND Valid_from__c <= :today AND (Valid_to__c = NULL OR Valid_to__c >= :today)
        ];

        List<Id> generatorUnitIds = new List<Id>();
        for (Meter2GenerationUnitRelationship__c tmpRel : meter2GenerationUnitRelationships) {
            generatorUnitIds.add(tmpRel.Generator_Unit__c);
        }

        List<Generation_Unit__c> generationUnits = [
                SELECT Id, Name, Annual_Production__c,
                        GPS_Location__Latitude__s, GPS_Location__Longitude__s,
                        Installed_Capacity__c, Solar_Manufacturer__c, Commissioning_Date__c,
                        Portfolio_ID__c, Description__c, Technology__c, Generator_Type__r.Manufacturer__r.Name,
                        Generator_Type__r.Type__c, Manufacturer_Number__c
                FROM Generation_Unit__c
                WHERE Id IN:generatorUnitIds
        ];

        return generationUnits;
    }

    @AuraEnabled
    public static void upsertDowntime(Id meterId, Datetime startDate, Datetime endDate, String outageType,
            String reason, String generators, Decimal level, String downtimeId, String comment) {
        msUtility.checkObjectAccess(meterId, 'Meter__c');
        msUtility.checkFeatureAccess(meterId, 'isDowntime');

        HttpResponse response;
        BackendMonitoring__e logEvent = msUtility.getEvent('Outage upsert');
        Map<String, Object> logData = new Map<String, Object>();

        Meter__c meter = [SELECT Id, Name, Country__c, RecordType.DeveloperName, Portfolio_ID__c, Installed_Capacity__c FROM Meter__c WHERE Id = :meterId];
        msUtility.FeatureSetting featureSetting = msUtility.getMeterFeatures(meter);
        if (featureSetting.isDowntime == false) {
            throw new AuraHandledException('Operation is not allowed for this meter ' + meter.Portfolio_ID__c);
        }

        //converting Time entered by user to the timezone of the plant
        try {
            List<GeneratorOutage> generatorObjects = (List<GeneratorOutage>) System.JSON.deserializeStrict(generators, List<GeneratorOutage>.Class);

            Integer targetTimeZoneOffsetMinutesStart = TimeZone.getTimeZone(featureSetting.timezone).getOffset(startDate) / 1000;
            Integer myserverTimeZoneOffsetMinutesStart = TimeZone.getTimeZone(UserInfo.getTimeZone().getID()).getOffset(startDate) / 1000;
            Integer targetTimeZoneOffsetMinutesEnd = TimeZone.getTimeZone(featureSetting.timezone).getOffset(endDate) / 1000;
            Integer myserverTimeZoneOffsetMinutesEnd = TimeZone.getTimeZone(UserInfo.getTimeZone().getID()).getOffset(endDate) / 1000;
            startDate = startDate.addSeconds((-1 * targetTimeZoneOffsetMinutesStart) + myserverTimeZoneOffsetMinutesStart);
            endDate = endDate.addSeconds((-1 * targetTimeZoneOffsetMinutesEnd) + myserverTimeZoneOffsetMinutesEnd);
            Datetime now = Datetime.now();
            now = now.addMinutes(-2);

            if (endDate < now || endDate < startDate) {
                throw new AuraHandledException('Timeframe is not valid');
            }

            Outage outage = new Outage();
            outage.id = downtimeId;
            outage.country = featureSetting.market;
            outage.entityName = meter.Name;
            outage.entityId = meter.Portfolio_ID__c;
            outage.entityType = 'Asset';
            outage.outageStatus = 'Open';
            outage.startDate = startDate;
            outage.endDate = endDate;
            outage.generators = generatorObjects;
            outage.reason = reason;
            outage.comment = comment;
            outage.outageType = outageType;
            outage.changeUser = UserInfo.getName();
            outage.changeTime = Datetime.now();

            // Calculate level in case of generator-level outage
            level = getLevel(generatorObjects, level, meter);

            Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
            String endpoint = apiSettings.Downtimes_Endpoint__c;
            if (downtimeId == null) {
                outage.level = level;
                String body = JSON.serialize(outage);
                response = msUtility.getHttp(endpoint, body, 'POST');
            } else {
                if (outage.startDate > now) {
                    outage.level = level;
                    String body = JSON.serialize(outage);
                    response = msUtility.getHttp(endpoint, body, 'PUT');
                } else {
                    List<Outage> outages = splitOutage(JSON.serialize(outage), now);
                    OutagesWrapper originalOutages = getDowntimes(meterId);
                    outages[1].level = level;
                    for (Outage tmpOutage : originalOutages.outages) {
                        if (tmpOutage.id == outage.id) {
                            outages[0].level = tmpOutage.level;
                        }
                    }

                    response = msUtility.getHttp(endpoint, JSON.serialize(outages[0]), 'PUT');
                    response = msUtility.getHttp(endpoint, JSON.serialize(outages[1]), 'POST');
                }
            }

            logEvent.MeterId__c = meterId;
            logData.put('endpoint', endpoint);
            logData.put('method', 'GET');
            logData.put('statusCode', response.getStatusCode());
            logData.put('resultBody', response.getBody());
            logData.put('startDate', startDate);
            logData.put('endDate', endDate);
            logData.put('outageType', outageType);
            logData.put('reason', reason);
            logData.put('generators', generators);
            logData.put('level', level);
            logData.put('downtimeId', downtimeId);
            if (response.getStatusCode() != 200) {
                logEvent.IsError__c = true;
            }
            logEvent.DataJson__c = JSON.serialize(logData);

        } catch (Exception e) {
            logEvent = msUtility.handleException(logEvent, e);
        }
        msUtility.publishEvent(logEvent);

        if (response.getStatus() == 'OK') {
            return;
        } else {
            throw new AuraHandledException('Error: ' + response.getStatus() + '\n' + response.getBody());
        }
    }

    @AuraEnabled
    public static OutagesWrapper deleteDowntimeApex(Id meterId, String downtimeId) {
        msUtility.checkObjectAccess(meterId, 'Meter__c');
        msUtility.checkFeatureAccess(meterId, 'isDowntime');

        OutagesWrapper result;
        HttpResponse response;
        BackendMonitoring__e logEvent = msUtility.getEvent('Outage upsert');
        Map<String, Object> logData = new Map<String, Object>();


        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        response = msUtility.getHttp(apiSettings.Downtimes_Endpoint__c + '/' + downtimeId, null, 'DELETE');

        logData.put('meterId', meterId);
        logData.put('downtimeId', downtimeId);
        logData.put('statusCode', response.getStatusCode());
        logData.put('resultBody', response.getBody());
        logEvent.DataJson__c = JSON.serialize(logData);
        if (response.getStatusCode() != 200) {
            logEvent.IsError__c = true;
        }

        msUtility.publishEvent(logEvent);

        if (response.getStatus() == 'OK') {
            result = getDowntimes(meterId);
        }
        return result;
    }

    public static List<OutageReasonWrapper> getOutageReasons(Id meterId) {
        List<PicklistEntry> entriesList = getOutageReasonPicklistEntries();
        Set<String> validEntriesAPI = getValidOutageAPIValues(meterId);
        List<OutageReasonWrapper> outageReasons = new List<OutageReasonWrapper>();
        for (PicklistEntry entryItem : entriesList) {
            if (validEntriesAPI.contains(entryItem.value)) {
                OutageReasonWrapper reasonWrapper = new OutageReasonWrapper();
                reasonWrapper.label = entryItem.label;
                reasonWrapper.value = entryItem.value;
                outageReasons.add(reasonWrapper);
            }
        }
        return outageReasons;
    }
    private static List<PicklistEntry> getOutageReasonPicklistEntries() {
        Schema.DescribeFieldResult F = msUserNotificationSetting__c.Dummy_field_for_Outage_Apex_Code__c.getDescribe();
        Schema.SObjectField T = F.getSobjectField();
        return T.getDescribe().getPicklistValues();
    }
    private static Set<String> getValidOutageAPIValues(Id meterId) {
        Map<String, Schema.SObjectField> fieldMap = Outage_Reason__mdt.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());

        List<Outage_Reason__mdt> outageReasons =
                Database.query('SELECT ' + String.join(fieldNames, ',') +
                        ' FROM Outage_Reason__mdt');
        
        String market = msUtility.getMeterFeatures(new Meter__c(Id = meterId)).market;
        Set<String> validEntries = new Set<String>();
        for (Outage_Reason__mdt reasonItem : outageReasons) {
            if ((Boolean) reasonItem.get(market + '__c')) {
                validEntries.add(reasonItem.DeveloperName);
            }
        }
        return validEntries;
    }


    public static List<Outage> splitOutage(String outageIn, Datetime now) {
        Outage outageFirst = new Outage();
        Outage outageSecond = new Outage();
        outageFirst = (Outage) JSON.deserialize(outageIn, Outage.class);
        outageSecond = (Outage) JSON.deserialize(outageIn, Outage.class);


        outageFirst.endDate = now;
        outageSecond.startDate = now;
        outageSecond.id = null;

        List<Outage> outages = new List<Outage>();
        outages.add(outageFirst);
        outages.add(outageSecond);

        return outages;
    }


    public static Decimal getLevel(List<GeneratorOutage> generators, Decimal level, Meter__c meter) {
        if (generators.size() > 0) {
            Decimal genCapacity = 0;
            for (msNonavailabilitiesController.GeneratorOutage g : generators) {
                System.debug(g);
                genCapacity = genCapacity + g.capacity;
            }
            System.debug(level);
            System.debug(genCapacity);
            System.debug(meter.Installed_Capacity__c - genCapacity);
            return meter.Installed_Capacity__c - genCapacity;
        } else {
            return level;
        }
    }

    public class GeneratorOutage {
        public GeneratorOutage() {
        }
        public GeneratorOutage(Id id, String name, Decimal cap) {
            this.generatorId = id;
            this.generatorName = name;
            this.capacity = cap;
        }

        @AuraEnabled public Id generatorId { get; set; }
        @AuraEnabled public String generatorName { get; set; }
        @AuraEnabled public Decimal capacity { get; set; }
    }
    public class Outage {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String entityName { get; set; }
        @AuraEnabled public String entityId { get; set; }
        @AuraEnabled public String entityType { get; set; }
        @AuraEnabled public String outageStatus { get; set; }
        @AuraEnabled public Datetime startDate { get; set; }
        @AuraEnabled public Datetime endDate { get; set; }
        @AuraEnabled public Decimal level { get; set; }
        @AuraEnabled public List<GeneratorOutage> generators { get; set; }
        @AuraEnabled public String reason { get; set; }
        @AuraEnabled public String comment { get; set; }
        @AuraEnabled public String reasonLabel { get; set; }
        @AuraEnabled public String outageType { get; set; }
        @AuraEnabled public String changeUser { get; set; }
        @AuraEnabled public Datetime changeTime { get; set; }
        @AuraEnabled public Boolean beforeStart { get; set; }
        @AuraEnabled public Boolean beforeEnd { get; set; }
        @AuraEnabled public Boolean isCurrent { get; set; }
        @AuraEnabled public Integer availableGenerators { get; set; }
        @AuraEnabled public String affectedArea { get; set; }
    }
    public class OutagesWrapper {
        @AuraEnabled public List<Outage> outages { get; set; }
        @AuraEnabled public List<Generation_Unit__c> generationUnits { get; set; }
        @AuraEnabled public Map<String, String> labels { get; set; }
        @AuraEnabled public List<OutageReasonWrapper> outageReasonOptions { get; set; }

        public OutagesWrapper() {
            labels = new Map<String, String>{
                    'msDowntimesFormTypeOptions' => Label.msDowntimesFormTypeOptions,
                    'msDowntimesFormReasonOptions' => Label.msDowntimesFormReasonOptions,
                    'msDowntimesFormUnitOptions' => Label.msDowntimesFormUnitOptions,
                    'msDowntimesTableCreationDate' => Label.msDowntimesTableCreationDate,
                    'msDowntimesTableUser' => Label.msDowntimesTableUser,
                    'msDowntimesTableBeginning' => Label.msDowntimesTableBeginning,
                    'msDowntimesTableEnd' => Label.msDowntimesTableEnd,
                    'msDowntimesTableReason' => Label.msDowntimesTableReason,
                    'msDowntimesTableLevel' => Label.msDowntimesTableLevel,
                    'msDowntimesTableGenerators' => Label.msDowntimesTableGenerators,
                    'msDowntimesComment' => Label.msDowntimesComment
            };
        }
    }
    public class OutageReasonWrapper {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
    }
}
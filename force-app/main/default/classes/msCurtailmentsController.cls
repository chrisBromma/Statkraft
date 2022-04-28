/****************************************************************************************************
* Class msCurtailmentsController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   04.09.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)    04.09.2018      	Init version.
*   * Maciej Dudek                          10.07.2019          Added imgURL property and getSeries() method to
*                                                               embed chart image on Visualforce Page pdf
*   * Christian Gottlieb (mindsquare GmbH)  27.09.2019          Runs on new Curtailments API
*   * Lukasz Bak (mindsquare GmbH)          14.10.2019          Values and dates display format depending on locale
*****************************************************************************************************/

public without sharing class msCurtailmentsController {

    public Curtailment curtailment { get; set; }
    public String imgURL { get; set; }

    public void getCurtailment() {
        String plantId = ApexPages.currentPage().getParameters().get('plantid');
        String downregulationType = Boolean.valueOf(ApexPages.currentPage().getParameters().get('isMrl'))
                                ? DownregulationType.Mrl.name() : DownregulationType.Downreg.name();
        ApexPages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=Curtailments.pdf');

        Meter__c meter = [SELECT Name, Installed_Capacity__c, Portfolio_ID__c FROM Meter__c WHERE Id = :plantId];

        String startDate = '"' + ApexPages.currentPage().getParameters().get('startDate') + '"';
        String endDate = '"' + ApexPages.currentPage().getParameters().get('endDate') + '"';
        Datetime convertedStartDate;
        Datetime convertedEndDate;
        try {
            convertedStartDate = (Datetime) JSON.deserialize(startDate, Datetime.class);
            convertedEndDate = (Datetime) JSON.deserialize(endDate, Datetime.class);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid start/end date');
        }

        imgURL = ApexPages.currentPage().getParameters().get('imgURL');
        Statkraft_TimeSeries_Settings__mdt settings = getTimeSeriesSettings(meter.Portfolio_ID__c);
        TimeZone plantTimeZone = TimeZone.getTimeZone(settings.Timezone__c);
        Integer plantTimeOffset = plantTimeZone.getOffset(convertedStartDate) / 1000;

        String curtailmentsJson = retrieveCurtailments(plantId, downregulationType, convertedStartDate, convertedEndDate);
        List<Curtailment> curtailments = (List<Curtailment>) JSON.deserialize(curtailmentsJson, List<Curtailment>.class);
        if (curtailments.size() > 0) {
            curtailments[0].value = Decimal.valueOf(parseDouble(curtailments[0].value)).setScale(2);
            curtailments[0].installedCapacityTotal = formatValueStringIntoUserLocaleFormatString(String.valueOf(meter.Installed_Capacity__c), 3);
            curtailments[0].startDate = curtailments[0].startDate.addSeconds(plantTimeOffset);
            curtailments[0].endDate = curtailments[0].endDate.addSeconds(plantTimeOffset);
            if (curtailments[0].steps.size() > 0) {
                for (CurtailmentStep step : curtailments[0].steps) {
                    step.value = Decimal.valueOf(parseDouble(step.value)).setScale(2);
                    step.startDate = step.startDate.addSeconds(plantTimeOffset);
                }
            }

            curtailment = curtailments[0];
        }
    }

    @AuraEnabled
    public static String getCurtailments(String plantId, Boolean isMrl) {
        msUtility.checkObjectAccess(plantId, 'Meter__c');
        msUtility.checkFeatureAccess(plantId, 'isDownregulationView');

        Integer lastXMonth = 3;
        List<PortalSettings__c> setting2 = [SELECT Integer__c FROM PortalSettings__c WHERE Name = 'Curtailments - Show last x month'];
        if (setting2.size() > 0) {
            lastXMonth = setting2[0].Integer__c.intValue();
        }
        lastXMonth = -1 * lastXMonth;

        Datetime now = Datetime.now();
        Datetime endTime = now.day() > 6 ? now.date().toStartOfMonth().addDays(-1) : now.date().toStartOfMonth().addMonths(-1).addDays(-1);
        endTime = endTime.addDays(1).addSeconds(-1);

        Datetime startTime = now.date().toStartOfMonth().addMonths(lastXMonth).addDays(-1);
        String downregulationType = isMrl ? DownregulationType.Mrl.name() : DownregulationType.Downreg.name();
        return retrieveCurtailments(plantId, downregulationType, startTime, endTime);
    }

    public static String retrieveCurtailments(String plantId, String downRegType, Datetime startTime, Datetime endTime) {
        Datetime now = Datetime.now();
        Meter__c meter = [SELECT Portfolio_ID__c, Name, Installed_Capacity__c FROM Meter__c WHERE Id = :plantId];
        String portfolioId = meter.Portfolio_ID__c;

        List<FeatureEnablement__c> featureEnablements = [
                SELECT Meter__c, Contract__c, Feature__c, Start__c, End__c, Valid_from__c, Valid_to__c
                FROM FeatureEnablement__c
                WHERE Valid_from__c <= :Date.today()
                AND Valid_to__c >= :Date.today()
                AND Feature__c = 'curtailment_allow_edit'
                AND (Meter__c = :plantId OR Meter__r.Parent_Meter__c = :plantId)
                AND (Contact__c = null OR Contact__c = :msUtility.getUserDetails().contact.Id)
        ];
        System.debug(featureEnablements);

        Boolean canEdit = false;
        List<PortalSettings__c> settingAllowUpdate = [SELECT Checkbox__c FROM PortalSettings__c WHERE Name = 'Curtailments - Allow Update' LIMIT 1];
        if (!settingAllowUpdate.isEmpty()) {
            canEdit = settingAllowUpdate[0].Checkbox__c;
        }

        Integer editLastXMonth = 1;
        List<PortalSettings__c> settingUpdateRange = [SELECT Integer__c FROM PortalSettings__c WHERE Name = 'Curtailments - Edit last x month' LIMIT 1];
        if (!settingUpdateRange.isEmpty()) {
            editLastXMonth = settingUpdateRange[0].Integer__c.intValue();
        }
        editLastXMonth = -1 * editLastXMonth;
        Datetime editTime = now.date().toStartOfMonth().addMonths(editLastXMonth);

        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
        String endpoint = ApiSettings.Curtailments_Endpoint_Read__c;

        endpoint += '?meteringPoint=' + portfolioId;
        endpoint += '&startTime=' + startTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        endpoint += '&endTime=' + endTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        if(downRegType != null){
            endpoint += '&downregulationType=' + downRegType;
        }
        System.HttpResponse response = msUtility.getHttp(endpoint, null, 'GET');
        if (response.getStatusCode() != 200) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Read CSV');
            Map<String, Object> logData = new Map<String, Object>();
            logEvent.IsError__c = true;
            logEvent.MeterId__c = plantId;
            logData.put('startTime', startTime);
            logData.put('endTime', endTime);
            logData.put('endpoint', endpoint);
            logData.put('method', 'GET');
            logData.put('statusCode', response.getStatusCode());
            logData.put('resultBody', response.getBody());
            logEvent.DataJson__c = JSON.serialize(logData);

            msUtility.publishEvent(logEvent);
            return null;
        }
        List<DownregulationBackend> downregulations = (List<DownregulationBackend>) JSON.deserialize(response.getBody(), List<DownregulationBackend>.class);

        List<Curtailment> curtailmentList = new List<Curtailment>();

        for (DownregulationBackend downregItem : downregulations) {
            if (downregItem.meteringPoint == meter.Portfolio_ID__c) {
                Curtailment curtailment = new Curtailment();
                curtailment.plantName = meter.Name;
                curtailment.startDate = downregItem.startTime;
                curtailment.endDate = downregItem.endTime.addSeconds(900);
                curtailment.valid = downregItem.allowEditing == true ? true : downregItem.isValid;
                curtailment.modifiedDate = downregItem.lastModifiedTime;
                curtailment.modifiedUser = downregItem.lastModifiedUser;
                curtailment.installedCapacityTotal = String.valueOf(meter.Installed_Capacity__c);
                curtailment.edited = false;
                curtailment.type = downregItem.type;
                if(curtailment.type == DownregulationType.Mrl.name())
                {
                    curtailment.ARP = downregItem.monthlyPrice;
                }
                Decimal aggregatedLoss = 0;
                Boolean isEditingAllowed = downregItem.allowEditing == null ? false : downregItem.allowEditing;
                curtailment.canEdit = (isEditingAllowed || (canEdit && curtailment.endDate > editTime));
                if (curtailment.canEdit == false) { // for closed curtailments, we check against feature enablement
                    for (FeatureEnablement__c tmpFeatureEnablement : featureEnablements) {
                        if (curtailment.endDate.date() >= tmpFeatureEnablement.Start__c && curtailment.endDate.date() <= tmpFeatureEnablement.End__c) {
                            curtailment.canEdit = true;
                            curtailment.valid = true;
                            break;
                        }
                    }
                }

                for (DownregulationPoint pointItem : downregItem.points) {
                    if ((pointItem.correctedLevel != null && String.valueOf(pointItem.correctedLevel) != 'NaN')
                            || (pointItem.originalLevel != null && String.valueOf(pointItem.originalLevel) != 'NaN')) {

                        CurtailmentStep newStep = new CurtailmentStep();
                        newStep.metering = parseDouble(pointItem.metering);
                        newStep.startDate = pointItem.ts;

                        if (pointItem.correctedLevel == null || String.valueOf(pointItem.correctedLevel) == 'NaN') {
                            newStep.value = parseDouble(pointItem.originalLevel);
                            aggregatedLoss += Decimal.valueOf(newStep.value);
                        }
                        else {
                            if (pointItem.correctedLevel != pointItem.originalLevel) {
                                curtailment.edited = true;
                            }
                            newStep.value = parseDouble(pointItem.correctedLevel);
                            aggregatedLoss += Decimal.valueOf(newStep.value);
                        }

                        if (pointItem.originalLevel == null || String.valueOf(pointItem.originalLevel) == 'NaN') {
                            newStep.valueOriginal = parseDouble(pointItem.originalLevel);
                        }

                        curtailment.steps.add(newStep);
                    }
                    else if ((pointItem.originalLevel == null || String.valueOf(pointItem.originalLevel) == 'NaN')
                            && (pointItem.correctedLevel == null || String.valueOf(pointItem.correctedLevel )== 'NaN')) {

                        CurtailmentStep newStep = new CurtailmentStep();
                        newStep.metering = parseDouble(pointItem.metering);
                        newStep.startDate = pointItem.ts;
                        newStep.value = 0;

                        if (downregItem.points.indexOf(pointItem) == 0) {
                            curtailment.preStep = newStep;
                        } else if(downregItem.points.indexOf(pointItem) == downregItem.points.size() - 1){
                            curtailment.postStep = newStep;
                        }else{
                            curtailment.steps.add(newStep);
                        }
                    }
                }
                curtailment.value = (aggregatedLoss / 4);
                curtailmentList.add(curtailment);
            }
        }
        return JSON.serialize(curtailmentList);
    }

    @AuraEnabled
    public static void setCurtailment(String plantId, String valuesJSON, Datetime startDate) {

        try{
            msUtility.checkObjectAccess(plantId, 'Meter__c');
            msUtility.checkFeatureAccess(plantId, 'isDownregulationView');
            msUtility.checkFeatureAccess(plantId, 'isDownregulationEdit');

            Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
            String endpoint = ApiSettings.Curtailments_Endpoint_Write__c;
            String portfolioId = [SELECT Portfolio_ID__c, Name FROM Meter__c WHERE Id = :plantId LIMIT 1].Portfolio_ID__c;

            System.HttpResponse result;
            String userContactName = [SELECT Contact.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.Name;

            List<CurtailmentStep> values = (List<CurtailmentStep>) JSON.deserialize(valuesJSON, List<CurtailmentStep>.class);
            DownregulationBackend toSave = new DownregulationBackend();
            toSave.meteringPoint = portfolioId;
            toSave.lastModifiedUser = userContactName;
            toSave.lastModifiedTime = Datetime.now();
            for (CurtailmentStep stepItem : values) {
                if (toSave.startTime == null) {
                    toSave.startTime = stepItem.startDate;
                } else if (toSave.startTime > stepItem.startDate) {
                    toSave.startTime = stepItem.startDate;
                }

                if (toSave.endTime == null) {
                    toSave.endTime = stepItem.startDate;
                } else if (toSave.endTime < stepItem.startDate) {
                    toSave.endTime = stepItem.startDate;
                }

                DownregulationPoint newPoint = new DownregulationPoint();
                newPoint.originalLevel = parseDouble(stepItem.valueOriginal);
                newPoint.correctedLevel = parseDouble(stepItem.value);
                newPoint.ts = stepItem.startDate;
                toSave.points.add(newPoint);
            }
            String body = JSON.serialize(toSave, true);
            result = msUtility.getHttp(endpoint, body, 'POST');

            BackendMonitoring__e logEvent = msUtility.getEvent('Curtailments Correction');
            logEvent.MeterId__c = plantId;
            Map<String, Object> logData = new Map<String, Object>();
            logData.put('valuesJSON', valuesJSON);
            logData.put('startDate', startDate);
            logData.put('statusCode', result.getStatusCode());
            if (result.getStatusCode() != 200) {
                logData.put('resultBody', result.getBody());
                logEvent.IsError__c = true;
            }
            logEvent.DataJson__c = JSON.serialize(logData);
            msUtility.publishEvent(logEvent);

        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Object> getSeries(String plantId, String startDate, String endDate) {
        msUtility.checkObjectAccess(plantId, 'Meter__c');
        msUtility.checkFeatureAccess(plantId, 'isDownregulationView');
        return msCurtailmentsChartController.getSeries(plantId, startDate, endDate);
    }

    private static String formatValueStringIntoUserLocaleFormatString(String value, Integer decimalPlaces) {
        return Decimal.valueOf(value).setScale(decimalPlaces).format();
    }

    public static Double parseDouble(Double value){
        return value == null || String.valueOf(value) == 'NaN' ? 0 : value;
    }

    public String getLocaleDateFormatString() {
        String formatString = '';
        String userLocale = UserInfo.getLocale();
        System.debug(userLocale);
        switch on userLocale {
            when 'de_DE', 'de_DE_EURO' {
                formatString = 'dd.MM.yyyy\',\' HH:mm';
            }
            when 'en_GB' {
                formatString = 'dd/MM/yyyy\',\' HH:mm';
            }
            when 'fr_FR', 'fr_FR_EURO' {
                formatString = 'dd/MM/yyyy \'à\' HH:mm';
            }
            when else {
                formatString = 'dd/MM/yyyy HH:mm';
            }
        }
        System.debug(formatString);
        return formatString;
    }

    private static Statkraft_TimeSeries_Settings__mdt getTimeSeriesSettings(String portfolioId) {
        String metadataName = portfolioId.substring(0, portfolioId.indexOf('_', 3));
        Map<String, Statkraft_TimeSeries_Settings__mdt> settings = msUtility.getAllTimeSeriesSettings();
        if (settings.get(metadataName) == null) {
            throw new AuraHandledException('Timeseries not found -> prefix: ' + metadataName);
        }
        return settings.get(metadataName);
    }

    public class TimeEntry {
        @AuraEnabled public Datetime timeDate { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public TimeChangeData metadata { get; set; }
    }
    public class TimeChangeData {
        @AuraEnabled public String modifiedUser { get; set; }
        @AuraEnabled public Datetime modifiedDate { get; set; }
    }
    public class TimeSeries {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public List<TimeEntry> values { get; set; }
    }
    public class Curtailment {
        @AuraEnabled public Datetime startDate { get; set; }
        @AuraEnabled public Datetime endDate { get; set; }
        @AuraEnabled public Double value { get; set; }
        @AuraEnabled public Boolean edited { get; set; }
        @AuraEnabled public Boolean canEdit { get; set; }
        @AuraEnabled public String plantName { get; set; }
        @AuraEnabled public Boolean valid { get; set; }
        @AuraEnabled public String installedCapacityTotal { get; set; }
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public Double ARP { get; set; }

        @AuraEnabled public String modifiedUser { get; set; }
        @AuraEnabled public Datetime modifiedDate { get; set; }
        @AuraEnabled public List<CurtailmentStep> steps { get; set; }
        @AuraEnabled public CurtailmentStep preStep { get; set; }
        @AuraEnabled public CurtailmentStep postStep { get; set; }

        public Curtailment() {
            steps = new List<CurtailmentStep>();
        }
    }
    public class CurtailmentStep {
        @AuraEnabled public Datetime startDate { get; set; }
        @AuraEnabled public Double value { get; set; }
        @AuraEnabled public Double valueOriginal { get; set; }
        @AuraEnabled public Double metering { get; set; }
    }
    public class DownregulationBackend {
        @AuraEnabled public String meteringPoint { get; set; }
        @AuraEnabled public Datetime startTime { get; set; }
        @AuraEnabled public Datetime endTime { get; set; }
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public Boolean allowEditing { get; set; }
        @AuraEnabled public Boolean isValidOverride { get; set; } // not used in portal
        @AuraEnabled public Boolean exported { get; set; } // not used in portal
        @AuraEnabled public String lastModifiedUser { get; set; }
        @AuraEnabled public Datetime lastModifiedTime { get; set; }
        @AuraEnabled public List<DownregulationPoint> points { get; set; }
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public Double monthlyPrice { get; set; }
        @AuraEnabled public String createUser {get; set;}
        @AuraEnabled public Datetime createTime {get; set;}

        public DownregulationBackend() {
            points = new List<DownregulationPoint>();
        }
    }
    public class DownregulationPoint {
        @AuraEnabled public Datetime ts { get; set; }
        @AuraEnabled public Double originalLevel { get; set; }
        @AuraEnabled public Double correctedLevel { get; set; }
        @AuraEnabled public Double metering { get; set; }
    }

    public enum DownregulationType{
        Downreg,
        Mrl
    }
}
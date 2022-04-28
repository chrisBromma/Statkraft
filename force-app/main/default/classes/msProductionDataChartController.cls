/****************************************************************************************************
* Class msProductionDataChartController
*
*   Create By	:   Macjei Dudek (mindsquare GmbH)
*   Create Date	:
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Maciej Dudek (mindsquare GmbH)        -      	                Init version.
*   * Lukasz Bak (mindsquare GmbH)          -      	                Updated for new UK requirements
*   * Christian Gottlieb (mindsquare GmbH)  01.10.2019              Updated for new Overview Chart requirements
*   * Lukasz Bak (mindsquare GmbH)  10.02.2020                      Changed default date range displayed on mobiles
*   * Lukasz Bak (mindsquare GmbH)  21.02.2020                      Timeseries settings fetched from Custom Metadata
*                                                                   instead of Custom Setting
*****************************************************************************************************/

public with sharing class msProductionDataChartController {

    private static final String UKFLEX_CASHFLOWS_CHART = 'chart_pnl';
    private static final String UKFLEX_METERING_CHART = 'chart_prod';
    private static final String DEFAULT_PRODUCTION_CHART = 'default';
    private static final String PORTFOLIO_CHART = 'overview';
    private static final String PORTFOLIO_CASHFLOWS_CHART = 'cashflows_overview';
    private static final String POST = 'POST';
    private static final Integer DEFAULT_DAY_SPAN = 7;
    private static final String DEFAULT_INSTANCE = 'dus';
    private static final String UK_INSTANCE = 'lon';
    private static final String TIMESTAMP = 'ts';
    private static final String FORECAST = 'forecast';
    private static final String METERING = 'metering';
    private static final String SETTLEMENT = 'settlement';
    private static final String AVAILABILITIES = 'availability';
    private static final String EMS_AVAILABILITIES = 'ems_availability';
    private static final String DOWNREGUALATION = 'downregulation';
    private static final String MRL_DOWNREGULATION = 'mrl_downregulation';
    private static final String PRODUCTION = 'production';
    private static final String SCHEDULE = 'schedule';
    private static final String CASHOUT = 'cashout';
    private static final String FEES_POWER = 'fees_power';
    private static final String OPEX = 'opex';
    private static final String CASHOUT_BUY = 'cashout_buy';
    private static final String CASHOUT_SELL = 'cashout_sell';
    private static final String INTRADAY_BUY = 'intraday_buy';
    private static final String INTRADAY_SELL = 'intraday_sell';
    private static final String DAYAHEAD_BUY = 'dayahead_buy';
    private static final String DAYAHEAD_SELL = 'dayahead_sell';
    private static final String CUM_TOTAL = 'cum_total';
    private static final String GAS = 'gas';
    private static final String FEES_GAS = 'fees_gas';
    private static final String EUA = 'eua';
    private static final String NAME = 'name';
    private static final String DATA = 'data';
    private static final String BM_BUY = 'bm_buy';
    private static final String BM_SELL = 'bm_sell';
    private static final String ANCILLARY_SERVICES = 'ancillary_services';
    private static final String DS3 = 'ds3';
    private static final String TRADED_VOLUME = 'volume';

    private static final String RAW_SCH = 'raw_sch';
    private static final String RAW_AVC = 'raw_avc';
    private static final String GENERATION = 'generation';
    private static Map<String, String> timeSeriesLabels;
    private static Map<String, Integer> defaultStartDaySpanByChartType;
    private static Map<String, Integer> defaultEndDaySpanByChartType;

    static {
        setDefaultDatesSpanByChartType();
        timeSeriesLabels = new Map<String, String>();
        timeSeriesLabels.put(TIMESTAMP, Label.msDownregulationsTableTime);
        timeSeriesLabels.put(FORECAST, Label.msChartForecast);
        timeSeriesLabels.put(METERING, Label.msChartMetering);
        timeSeriesLabels.put(SETTLEMENT, Label.msChartSettlement);
        timeSeriesLabels.put(AVAILABILITIES, Label.msChartAvailability);
        timeSeriesLabels.put(EMS_AVAILABILITIES, Label.msChartsOperatorAvailability);
        timeSeriesLabels.put(DOWNREGUALATION, Label.msChartDownregulation);
        timeSeriesLabels.put(MRL_DOWNREGULATION, Label.msChartMrlDownregulation);
        timeSeriesLabels.put(PRODUCTION, Label.msChartProduction);
        timeSeriesLabels.put(SCHEDULE, Label.msChartSchedule);
        timeSeriesLabels.put(CASHOUT, Label.msChartCashout);
        timeSeriesLabels.put(FEES_POWER, Label.msChartFeesPower);
        timeSeriesLabels.put(OPEX, Label.msChartOpex);
        timeSeriesLabels.put(CASHOUT_BUY, Label.msChartCashoutBuy);
        timeSeriesLabels.put(CASHOUT_SELL, Label.msChartCashoutSell);
        timeSeriesLabels.put(INTRADAY_BUY, Label.msChartIntradayBuy);
        timeSeriesLabels.put(INTRADAY_SELL, Label.msChartIntradaySell);
        timeSeriesLabels.put(DAYAHEAD_BUY, Label.msChartDayaheadBuy);
        timeSeriesLabels.put(DAYAHEAD_SELL, Label.msChartDayaheadSell);
        timeSeriesLabels.put(CUM_TOTAL, Label.msChartCumTotal);
        timeSeriesLabels.put(GAS, Label.msChartGas);
        timeSeriesLabels.put(FEES_GAS, Label.msChartFeesGas);
        timeSeriesLabels.put(EUA, Label.msChartEua);
        timeSeriesLabels.put(BM_BUY, Label.msChartBmBuy);
        timeSeriesLabels.put(BM_SELL, Label.msChartBmSell);
        timeSeriesLabels.put(ANCILLARY_SERVICES, Label.msChartAncillaryServices);
        timeSeriesLabels.put(RAW_SCH, Label.msChartSchedule);
        timeSeriesLabels.put(RAW_AVC, Label.msChartAvailability);
        timeSeriesLabels.put(GENERATION, Label.msChartMetering);
        timeSeriesLabels.put(DS3, Label.msChartsDs3);
        timeSeriesLabels.put(TRADED_VOLUME, Label.portalChartsTradedVolume);
    }

    @AuraEnabled
    public static ChartResult getChartResult(List<String> plantIds, DateTime startDate, DateTime endDate, String chartType, String unitType) {

        List<Meter__c> plantList = [
                SELECT Id, Portfolio_ID__c, Name, Main_Technology__c
                FROM Meter__c
                WHERE Id IN :plantIds
                AND Parent_Meter__c = NULL
        ];

        Statkraft_TimeSeries_Settings__mdt settings = getTimeSeriesSettings(plantList);
        if(String.isBlank(unitType))
        {
            // Setting the default unit type if unit type is not chosen by user
            unitType = settings.Unit_Type__c;
        }

        Date seriesStartDate = startDate != null ? startDate.date() : null;
        Date seriesEndDate = endDate != null ? endDate.date() : null;

        ChartResult result = new ChartResult();
        result.title = getTitle(plantList);
        result.plotLine = Datetime.now().getTime();
        result.unitType = unitType;
        result.series = getSeries(plantList, seriesStartDate, seriesEndDate, settings, chartType, unitType);

        if(chartType == DEFAULT_PRODUCTION_CHART) {
            result.downregulations = getDowntimeData(plantList[0], seriesStartDate, seriesEndDate, settings);
        }
        return result;
    }

    @AuraEnabled
    public static List<msUtility.LabelValuePair> getUnitTypeOptions(){
        return msUtility.getPickListValues(Statkraft_TimeSeries_Settings__mdt.Unit_Type__c);
    }

    private static Statkraft_TimeSeries_Settings__mdt getTimeSeriesSettings(List<Meter__c> plantList) {
        Meter__c meter = getMeter(plantList);
        if (meter.Portfolio_ID__c == null) {
            throw new AuraHandledException('Selected Plant does not have a defined Portfolio Id to retrieve a Timeseries');
        }
        meter.Portfolio_ID__c = meter.Portfolio_ID__c.toLowerCase();
        String market = msUtility.getUserDetails().plantFeatures.get(meter.Id).market;
        Statkraft_TimeSeries_Settings__mdt settings = msUtility.getAllTimeSeriesSettings().get(market);
        if (settings == null)
        {
            throw new AuraHandledException('Timeseries settings not found for -> Market: ' + market);
        }
        return settings;
    }

    private static Meter__c getMeter(List<Meter__c> plants) {
        if (plants.isEmpty()) {
            return new Meter__c();
        }
        return plants[0];
    }

    private static String getTitle(List<Meter__c> plants) {
        if (plants.size() == 1) {
            return plants[0].Name;
        } else {
            return Label.msChartOverview;
        }
    }

    private static String getSeries(List<Meter__c> plantList, Date startDate, Date endDate, Statkraft_TimeSeries_Settings__mdt settings, String chartType, String unitType) {
        Integer startDaySpan = defaultStartDaySpanByChartType.containsKey(chartType) ? defaultStartDaySpanByChartType.get(chartType) : -1 * DEFAULT_DAY_SPAN;
        Integer endDaySpan = defaultEndDaySpanByChartType.containsKey(chartType) ? defaultEndDaySpanByChartType.get(chartType) : DEFAULT_DAY_SPAN;
        String startDateTime = setDate(startDate, startDaySpan, true);
        String endDateTime = setDate(endDate, endDaySpan, false);
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();

        String endPoint = apiSettings.Charting_Endpoint_Read__c;
        String apiKey = apiSettings.Statkraft_API_Key__c;

        Map<String,String> seriesNameByPath = getPathsMap(plantList, chartType, settings); //key = Path ; value = series Name
        String body = '';
        switch on (chartType) {
            when 'chart_pnl', 'cashflows_overview' {
                body = getUKFlexCashflowsRequestBody(startDateTime, endDateTime, seriesNameByPath, settings);
            }
            when 'chart_prod' {
                body = getUKFlexMeteringRequestBody(startDateTime, endDateTime, seriesNameByPath, settings, unitType);
            }
            when 'overview' {
                body = getOverviewChartRequestBody(startDateTime, endDateTime, seriesNameByPath, settings, unitType);
            }
            when else {
                body = getRequestBody(startDateTime, endDateTime, seriesNameByPath, settings, unitType);
            }
        }
        System.debug(body);
        HttpResponse response = msUtility.getHttp(endPoint, body, POST, apiKey);

        if (chartType == UKFLEX_CASHFLOWS_CHART || chartType == PORTFOLIO_CASHFLOWS_CHART ||chartType == UKFLEX_METERING_CHART) {
            return addUKFlexLabels(response.getBody());
        } else {
            return addSeriesLabels(response.getBody());
        }
    }

    private static String getDowntimeData(Meter__c plant, Date startDate, Date endDate, Statkraft_TimeSeries_Settings__mdt settings) {
        String startDateTime = setDate(startDate, -1 * DEFAULT_DAY_SPAN, true);
        String endDateTime = setDate(endDate, DEFAULT_DAY_SPAN, false);
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        String endPoint = apiSettings.Charting_Endpoint_Read__c;
        String apiKey = apiSettings.Statkraft_API_Key__c;
        List<String> paths = new List<String>{'/' + plant.Portfolio_ID__c + settings.DownregulationsTimeseries__c};
        String body = getDowntimeRequestBody(startDateTime, endDateTime, paths);
        HttpResponse response = msUtility.getHttp(endPoint, body, POST, apiKey);
        System.debug(response.getBody());
        return addSeriesLabels(response.getBody());
    }

    private static String setDate(Date inputDate, Integer daySpan, Boolean isStartDate) {
        inputDate = inputDate != null ? inputDate : Date.today().addDays(daySpan);
        //adding 1 day to end date to cover last interval of the day
        Date resultDate  = isStartDate ? inputDate : inputDate.addDays(1);
        DateTime localDateTime = Datetime.newInstance(resultDate, Time.newInstance(0, 0, 0, 0));
        return msUtility.utcDateToString(localDateTime);
    }

    private static Map<String,String> getPathsMap(List<Meter__c> plants, String chartType, Statkraft_TimeSeries_Settings__mdt settings) {
        Map<String,String> seriesNameByPath = new Map<String, String>();
        for (Meter__c plant : plants) {

            if(plant.Portfolio_ID__c == null){
                continue;
            }

            msUtility.checkObjectAccess(plant.Id, 'Meter__c');
            plant.Portfolio_ID__c = plant.Portfolio_ID__c.trim().toLowerCase();
            if(chartType == DEFAULT_PRODUCTION_CHART){ // non-UKFlex chart
                for (String series : settings.Paths__c.split(',')) {
                    series = series.trim();
                    String path = '/' + plant.Portfolio_ID__c + series;
                    String seriesName = series.contains('/availability/power/ems/default') ? 'ems_availability' : series.split('/')[1];
                    seriesNameByPath.put(path, seriesName);
                }
            } else {
                switch on chartType {
                    when 'chart_prod' {
                        for (String series : settings.Paths__c.split(',')) {
                            series = series.trim();
                            String path = '/' + plant.Portfolio_ID__c+ series;
                            seriesNameByPath.put(path, series.split('/')[1]);
                        }
                    }
                    when 'chart_pnl', 'cashflows_overview' {
                        try{
                            msUtility.checkFeatureAccess(plant.Id, 'cashflowCharts');
                        }
                        catch(AuraHandledException ex){
                            continue;
                        }

                        for (String series : settings.CashflowPaths__c.split(',')) {
                            series = series.trim();
                            String path = '/' + plant.Portfolio_ID__c + settings.CashflowFolder__c + series;
                            seriesNameByPath.put(path, series.split('/')[1]);
                        }
                        if (plant.Main_Technology__c == 'Thermal' || plant.Main_Technology__c == 'Gas Peaker') {
                            for (String series : settings.ThermalCashflowPaths__c.split(',')) {
                                series = series.trim();
                                String path = '/' + plant.Portfolio_ID__c + settings.CashflowFolder__c + series;
                                seriesNameByPath.put(path, series.split('/')[1]);
                            }
                        }
                    }
                    when 'overview' {
                        for (String series : settings.PathsOverview__c.split(',')) {
                            series = series.trim();
                            String path = '/' + plant.Portfolio_ID__c + series;
                            seriesNameByPath.put(path, series.split('/')[1]);
                        }
                    }
                }
            }
        }
        return seriesNameByPath;
    }

    private static String getRequestBody(String startDate, String endDate, Map<String, String> seriesNameByPath, Statkraft_TimeSeries_Settings__mdt settings, String unitType) {
        Map<String, Object> paramsToValues = new Map<String, Object>();
        paramsToValues.put('paths', seriesNameByPath.keySet());
        paramsToValues.put('seriesNames', seriesNameByPath);
        paramsToValues.put('begin', startDate);
        paramsToValues.put('end', endDate);
        paramsToValues.put('catalogInstance', DEFAULT_INSTANCE);
        paramsToValues.put('ignoreMissingSeries', true);
        paramsToValues.put('unit', unitType);
        paramsToValues.put('resolution', settings.Resolution__c);
        paramsToValues.put('roundingDecimals', settings.RoundingDecimals__c == null ? null :settings.RoundingDecimals__c.intValue());
        return JSON.serialize(paramsToValues);
    }

    private static String getDowntimeRequestBody(String startDate, String endDate, List<String> paths) {
        Map<String, Object> paramsToValues = new Map<String, Object>();
        paramsToValues.put('paths', paths);
        paramsToValues.put('begin', startDate);
        paramsToValues.put('end', endDate);
        paramsToValues.put('catalogInstance', DEFAULT_INSTANCE);
        paramsToValues.put('ignoreMissingSeries', true);
        return JSON.serialize(paramsToValues);
    }

    private static String getUKFlexCashflowsRequestBody(String startDate, String endDate, Map<String, String> seriesNameByPath, Statkraft_TimeSeries_Settings__mdt settings) {
        Map<String, Object> paramsToValues = new Map<String, Object>();
        paramsToValues.put('seriesNames', seriesNameByPath);
        paramsToValues.put('paths', seriesNameByPath.keySet());
        paramsToValues.put('begin', startDate);
        paramsToValues.put('end', endDate);
        paramsToValues.put('catalogInstance', UK_INSTANCE);
        paramsToValues.put('ignoreMissingSeries', true);
        paramsToValues.put('returnColumns', true);
        paramsToValues.put('roundingDecimals', settings.RoundingDecimals__c == null ? null :settings.RoundingDecimals__c.intValue());
        return JSON.serialize(paramsToValues);
    }

    private static String getUKFlexMeteringRequestBody(String startDate, String endDate, Map<String,String> seriesNameByPath, Statkraft_TimeSeries_Settings__mdt settings, String unitType) {
        Map<String, Object> paramsToValues = new Map<String, Object>();
        paramsToValues.put('seriesNames', seriesNameByPath);
        paramsToValues.put('paths', seriesNameByPath.keySet());
        paramsToValues.put('begin', startDate);
        paramsToValues.put('end', endDate);
        paramsToValues.put('catalogInstance', DEFAULT_INSTANCE);
        paramsToValues.put('ignoreMissingSeries', true);
        paramsToValues.put('returnColumns', true);
        paramsToValues.put('unit', unitType);
        paramsToValues.put('resolution', settings.Resolution__c);
        paramsToValues.put('roundingDecimals', settings.RoundingDecimals__c == null ? null :settings.RoundingDecimals__c.intValue());
        return JSON.serialize(paramsToValues);
    }

    private static String getOverviewChartRequestBody(String startDate, String endDate, Map<String,String> seriesNameByPath, Statkraft_TimeSeries_Settings__mdt settings, String unitType) {
        Map<String, Object> paramsToValues = new Map<String, Object>();
        paramsToValues.put('seriesNames', seriesNameByPath);
        paramsToValues.put('paths', seriesNameByPath.keySet());
        paramsToValues.put('begin', startDate);
        paramsToValues.put('end', endDate);
        paramsToValues.put('catalogInstance', DEFAULT_INSTANCE);
        paramsToValues.put('ignoreMissingSeries', true);
        paramsToValues.put('unit', unitType);
        paramsToValues.put('resolution', settings.Resolution__c);
        paramsToValues.put('roundingDecimals', settings.RoundingDecimals__c == null ? null :settings.RoundingDecimals__c.intValue());
        return JSON.serialize(paramsToValues);
    }

    private static String addSeriesLabels(String responseBody) {
        Series series = (Series) JSON.deserialize(responseBody, Series.class);
        Series seriesWithHeaders = new Series();
        if(series.rows.size() > 0){
            List<String> headers = getHeaders(series.rows[0]);
            List<List<String>> rows = new List<List<String>>();
            rows.addAll(series.rows);
            rows[0] = headers;
            seriesWithHeaders.rows = rows;
        }

        return JSON.serialize(seriesWithHeaders);
    }

    private static String addUKFlexLabels(String responseBody){
        Series series = (Series) JSON.deserialize(responseBody, Series.class);
        Series seriesWithHeaders = new Series();
        List<List<String>> columns = new List<List<String>>();
        columns.addAll(series.columns);
        for (List<String> seriesItem : columns){
            seriesItem[0] = timeSeriesLabels.get(seriesItem[0]);
        }
        seriesWithHeaders.columns = columns;
        return JSON.serialize(seriesWithHeaders);
    }

    private static List<String> getHeaders(List<String> timeSeriesHeaders) {
        List<String> headers = new List<String>();
        for(String tsHeader : timeSeriesHeaders) {
            String tsKey;
            List<String> tsHeaderSplit = tsHeader.split('/');
            if(tsHeaderSplit.size() < 3) {
                tsKey = tsHeaderSplit[0];
            }
            else {
                tsKey = tsHeaderSplit[2];
            }
            String headerLabel = timeSeriesLabels.get(tsKey);
            headers.add(headerLabel);
        }
        return headers;
    }

    private static void setDefaultDatesSpanByChartType(){
        defaultStartDaySpanByChartType = new Map<String, Integer>{
                UKFLEX_METERING_CHART => -6, UKFLEX_CASHFLOWS_CHART => -6, PORTFOLIO_CHART => -6, PORTFOLIO_CASHFLOWS_CHART => -6, DEFAULT_PRODUCTION_CHART => -7
        };
        defaultEndDaySpanByChartType = new Map<String, Integer>{
                UKFLEX_METERING_CHART => 1, UKFLEX_CASHFLOWS_CHART => 1, PORTFOLIO_CHART => 1, PORTFOLIO_CASHFLOWS_CHART => 1, DEFAULT_PRODUCTION_CHART => 7
        };
    }

    public class ChartResult {
        @AuraEnabled public String series { get; set; }
        @AuraEnabled public String downregulations { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public Long plotLine { get; set; }
        @AuraEnabled public Map<String, String> seriesLabels { get; set; }
        @AuraEnabled public List<msUtility.LabelValuePair> unitTypeOptions { get; set; }
        @AuraEnabled public String unitType { get; set; }

        public ChartResult(){
            this.seriesLabels = timeSeriesLabels;
            unitTypeOptions = getUnitTypeOptions();
        }
    }

    public class Series {
        public List<List<String>> rows;
        public List<List<String>> columns;
    }
}
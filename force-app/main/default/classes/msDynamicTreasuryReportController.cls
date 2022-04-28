/**
* Created by Steffen Naundorf on 15.06.2021.
*/

public without sharing class msDynamicTreasuryReportController {

    @AuraEnabled
    public static ReportSetup getReports() {
        ReportSetup result= new ReportSetup();
        result.reportMap= new Map<String, List<Report>>();

        List<Report> reports = [SELECT Id, Name, FolderName, Format From Report WHERE Format = 'Tabular'];

        for (Report report : reports) {
            List<Report> reportsOfFolder = result.reportMap.get(report.FolderName);
            if (reportsOfFolder == null)reportsOfFolder = new List<Report>();

            reportsOfFolder.add(report);
            result.reportMap.put(report.FolderName, reportsOfFolder);
        }


        result.currencies= [SELECT Id, IsoCode FROM CurrencyType];
        return result;
    }

    @AuraEnabled
    public static List<Reports.ReportDetailRow> getRows(String reportId, Reports.ReportResults results) {
        Integer identifierIndex = 0;
        String identifierField;
        List<Reports.ReportDetailRow> reportRows = new List<Reports.ReportDetailRow>();
        Map<String, Reports.ReportFactWithDetails>factWithDetails = (Map<String, Reports.ReportFactWithDetails>) results.getFactMap();
        List<Reports.ReportDetailRow> rows = factWithDetails.get('T!T').getRows();

        if (results.getAllData() == true) {
            return rows;
        }

        Map<String, Reports.DetailColumn> metadata = results.getReportExtendedMetadata().getDetailColumnInfo();
        List<Reports.DetailColumn> columns = metadata.values();

        for (Integer i = 0; i < columns.size(); i++) {
            Object value = rows[0].getDataCells()[i].getValue();
            try {
                Id tempId = Id.valueOf(String.valueOf(value));
                identifierIndex = i;
                identifierField = tempId.getSobjectType() + '.Id';
                break;
            } catch (Exception e) {
                //dies silently
            }
        }

        List<String> ids = new List<String>();

        while (results.getAllData() == false) {
            Map<String, Reports.ReportFactWithDetails>factWithDetails2 = (Map<String, Reports.ReportFactWithDetails>) results.getFactMap();
            List<Reports.ReportDetailRow> rows2 = factWithDetails2.get('T!T').getRows();
            reportRows.addAll(rows2);

            for (Reports.ReportDetailRow row : rows2) {
                String id = '\'' + (String) row.getDataCells()[identifierIndex].getValue() + '\'';
                ids.add(id);
            }
            String concatedIds = String.join(ids, ',');

            try {
                Reports.ReportFilter RF = new Reports.ReportFilter('CUST_ID', 'notEqual', concatedIds);
                Reports.ReportMetadata RM = results.getReportMetadata();
                List<Reports.ReportFilter>allfilters = new List<Reports.ReportFilter>{
                        RF
                };

                allfilters.addAll(RM.getReportFilters());
                RM.setReportFilters(allfilters);

                results = Reports.ReportManager.runReport(reportId, RM, true);
            } catch (Exception e) {
                Reports.ReportFilter RF2 = new Reports.ReportFilter(identifierField, 'notEqual', concatedIds);
                Reports.ReportMetadata RM2 = results.getReportMetadata();
                List<Reports.ReportFilter>allfilters = new List<Reports.ReportFilter>{
                        RF2
                };

                allfilters.addAll(RM2.getReportFilters());
                for (Integer i=0;i<allfilters.size();i++) {
                    if(allfilters[i].getColumn()=='CUST_ID'){
                        allfilters.remove(i);
                    }
                }
                RM2.setReportFilters(allfilters);

                results = Reports.ReportManager.runReport(reportId, RM2, true);
            }

            if (results.getAllData() == true) {
                factWithDetails2 = (Map<String, Reports.ReportFactWithDetails>) results.getFactMap();
                rows2 = factWithDetails2.get('T!T').getRows();
                reportRows.addAll(rows2);
            }
        }

        return reportRows;
    }

    @AuraEnabled
    public static ReportWrapper getReportMetadata(String reportId, String targetCurrency, Date conversionDate) {
        Map<String, DatedConversionRate> conversionRateMap = getConversionRates(conversionDate);

        ReportWrapper result = new ReportWrapper();
        result.head = new List<HeaderCell>();
        result.data = new List<List<DataCell>>();

        Reports.reportResults results = Reports.ReportManager.runReport(reportId, true);

        //Get Columns
        Map<String, Reports.DetailColumn> metadata = results.getReportExtendedMetadata().getDetailColumnInfo();
        List<Reports.DetailColumn> columns = metadata.values();
        Map<String, Integer> fieldToIndex = new Map<String, Integer>();
        for (Integer i = 0; i < columns.size(); i++) {
            fieldToIndex.put(columns[i].getName(), i);
        }

        //Get Data
        List<Reports.ReportDetailRow>rows = getRows(reportId, results);
        for (Integer i = 0; i < rows.size(); i++) {
            Reports.ReportDetailRow row = rows[i];
            List<DataCell> dataRow = new List<DataCell>();
            List<Reports.ReportDataCell> cells = row.getDataCells();
            for (Integer j = 0; j < cells.size(); j++) {
                Object value = cells[j].getValue();
                if (value != null && String.valueOf(value).contains('##Convert##')) {
                    String requestLine = String.valueOf(value).remove('##Convert##');
                    List<String> requests = requestLine.split(',');
                    for (Integer r = 0; r < requests.size(); r++) {
                        Integer baseFieldIndex = fieldToIndex.get(requests[r]);
                        if (baseFieldIndex == null) {
                            continue;
                        }
                        Reports.DetailColumn tempColumn = columns[baseFieldIndex];
                        if (i == 0) {
                            HeaderCell tempHead = new HeaderCell();
                            //tempHead.dataType = tempColumn.getDataType().name();
                            tempHead.label = tempColumn.getLabel() + ' in ' + targetCurrency ;
                            tempHead.name = tempColumn.getName();
                            result.head.add(tempHead);
                        }

                        DataCell tempCell = new DataCell();
                        tempCell.fieldLabel = tempColumn.getLabel() + ' in ' + targetCurrency ;
                        tempCell.fieldName = tempColumn.getName();

                        Reports.ReportCurrency tempCurrency = (Reports.ReportCurrency) row.getDataCells()[baseFieldIndex].getValue();
                        if(tempCurrency!=null){
                            Double newValue = convertValue(tempCurrency, targetCurrency, conversionRateMap);
                            tempCell.value = newValue;
                            tempCell.valueLabel = targetCurrency + ' ' + newValue.format();
                        }else{
                            tempCell.value = null;
                            tempCell.valueLabel = '';
                        }
                        dataRow.add(tempCell);
                    }
                } else {
                    Reports.DetailColumn tempColumn = columns[j];
                    if (i == 0) {
                        HeaderCell tempHead = new HeaderCell();
                        tempHead.label = tempColumn.getLabel();
                        tempHead.name = tempColumn.getName();
                        result.head.add(tempHead);
                    }

                    DataCell tempCell = new DataCell();
                    tempCell.fieldLabel = tempColumn.getLabel();
                    tempCell.fieldName = tempColumn.getName();
                    tempCell.valueLabel = cells[j].getLabel();
                    tempCell.value = cells[j].getValue();
                    dataRow.add(tempCell);
                }
            }
            result.data.add(dataRow);
        }

        return result;
    }

    public static Double convertValue(Reports.ReportCurrency baseValue, String targetCurrency, Map<String, DatedConversionRate> conversionRateMap) {
        Double value = baseValue.getAmount();
        String baseCurrency = baseValue.getCurrencyCode();
        value = value / conversionRateMap.get(baseCurrency).ConversionRate;
        value = value * conversionRateMap.get(targetCurrency).ConversionRate;

        return value;
    }
    public static String getChildObject(Reports.reportResults results) {
        PageReference pageRef = new PageReference('/apex/getSessionID');
        String html = pageRef.getContent().toString();
        String sessionId = html.substring(html.indexOf('####') + 4, html.lastIndexOf('####'));

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v39.0/analytics/report-types/' + results.getReportMetadata().getReportType().getType());
        request.setMethod('GET');
        request.setHeader('Authorization', 'OAuth ' + sessionId);
        request.setHeader('Cookie', 'sid=' + UserInfo.getSessionId());
        HttpResponse response = http.send(request);

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object>reportMetadata = (Map<String, Object>) responseMap.get('reportMetadata');
        List<Object>detailColumns = (List<Object>) reportMetadata.get('detailColumns');
        String childField = (String) detailColumns[detailColumns.size() - 1];
        if (childField.indexOf('.') != -1) {
            childField = childField.substring(0, childField.indexOf('.'));
        }

        return childField;
    }

    public static Map<String, DatedConversionRate> getConversionRates(Date conversionDate) {
        List<DatedConversionRate> conversionRates = [
                SELECT ID, ConversionRate, IsoCode, StartDate, NextStartDate
                FROM DatedConversionRate
                WHERE StartDate <= :conversionDate AND NextStartDate > :conversionDate
        ];

        Map<String, DatedConversionRate>conversionRateMap = new Map<String, DatedConversionRate>();
        for (DatedConversionRate tempRate : conversionRates) {
            conversionRateMap.put(tempRate.IsoCode, tempRate);
        }
        return conversionRateMap;
    }

    public class DataCell {
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String valueLabel { get; set; }
        @AuraEnabled public Object value { get; set; }
    }
    public class HeaderCell {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer index { get; set; }
    }
    public class ReportWrapper {
        @AuraEnabled public List<List<DataCell>> data { get; set; }
        @AuraEnabled public List<HeaderCell> head { get; set; }
    }
    public class ReportSetup {
        @AuraEnabled public Map<String, List<Report>> reportMap { get; set; }
        @AuraEnabled public List<CurrencyType> currencies { get; set; }
    }
}
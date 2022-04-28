/****************************************************************************************************
* Class msCurtailmentsChartController
*
*   Create By	:   Frank Nehler
*   Create Date	:   12.09.2018
*   Description	:	-
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler (mindsquare GmbH)            12.09.2018          Init version.
*****************************************************************************************************/

public with sharing class msCurtailmentsChartController {

    @AuraEnabled
    public static List<Object> getSeries(String plantId, String startDate, String endDate) {
        msUtility.checkObjectAccess(plantId, 'Meter__c');

        Datetime convertedStartDate = msUtility.parseUtcDateTime(startDate);
        Datetime convertedEndDate= msUtility.parseUtcDateTime(endDate);

//        Long dt1Long = convertedStartDate.getTime();
//        Long dt2Long = convertedEndDate.getTime();
//        Long milliseconds = dt2Long - dt1Long;
//        Long minutes = milliseconds / 60000;
        Integer timeRangeExtensionInMinutes = 15;

//        convertedStartDate= convertedStartDate.addMinutes(Integer.valueOf(minutes)*-1);
        convertedStartDate= convertedStartDate.addMinutes(timeRangeExtensionInMinutes*-1);
//        convertedEndDate= convertedEndDate.addMinutes(Integer.valueOf(minutes));
        convertedEndDate= convertedEndDate.addMinutes(timeRangeExtensionInMinutes);

        // security check if user really has access to plants
        //Todo needs to be enabled
        /*Boolean checkEnt = msUtility.checkObjectAccess(plantId, 'Entity__c');
        if (!checkEnt) {
            return null;
        }*/

        Meter__c meter = [SELECT Id, Portfolio_ID__c FROM Meter__c WHERE Id = :plantId];
        String portfolioId=meter.Portfolio_ID__c;
        Integer index = meter.Portfolio_ID__c.indexOf('_', 3);
        String customMetadataName = meter.Portfolio_ID__c.substring(0, index);
        Statkraft_TimeSeries_Settings__mdt settings = msUtility.getAllTimeSeriesSettings().get(customMetadataName);
        if(settings == null){
            throw new AuraHandledException('Timeseries not found -> prefix: ' + customMetadataName);
        }
        TimeZone plantTimeZone = TimeZone.getTimeZone(settings.Timezone__c);
        List<String> pathList = new List<String>();
        pathList = settings.PathsCurtailments__c.split(',');
        String unit = settings.Unit_Type__c;
        String resolution = settings.Resolution__c;



        String body = getRequestBody(portfolioId, convertedStartDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC'), convertedEndDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'UTC'), pathList, unit, resolution);
        String endpoint = msUtility.getMetadata().Time_Series_Endpoint_Read__c;
        String method = 'POST';
        String content = msUtility.getHttp(endpoint, body, method).getBody();
        System.debug('CONTENT: ' + content);
        return formatData(content, plantTimeZone);
    }

    public static String getRequestBody(String portfolioId, String startDate, String endDate, List<String> pathList, String unit, String resolution) {
        String names = '';
        for (String path : pathList) {
            names += '"/' + portfolioId + path + '",';
        }
        names = names.removeEnd(',');
        String body = '{"names": [' + names + '],' +
                '"begin": "' + startDate + '",' +
                '"end": "' + endDate + '",' +
                '"resolution": "' + resolution + '",' +
                '"unit": "' + unit + '"}';
        return body;
    }

    public static List<Object> formatData(String data, TimeZone plantTimeZone) {
        List<Object> seriesList = (List<Object>) JSON.deserializeUntyped(data);
        List<Object> formatedSeries = new List<Object>();
        String name = '';

        for (Object serie : seriesList) {
            List<Object> dataList = new List<Object>();
            Map<String, Object> tempMap = new Map<String, Object>();
            Map<String, Object> serieMap = (Map<String, Object>) serie;

            //format the name of the serie
            name = (String) serieMap.get('name');
            Integer index1 = name.indexOf('/', 1) + 1;
            Integer index2 = name.indexOf('/', index1);
            name = name.substring(index1, index2);
            if (name == 'downregulation') {
                name = Label.msCurtailmentsChartLoss;
                tempMap.put('color', '#F8CAB3');
                tempMap.put('index', 1);

            } else {
                name = Label.msCurtailmentsChartProduced;
                tempMap.put('color', '#D0E7BD');
                tempMap.put('index', 2);
            }

            tempMap.put('name', name);

            //format the values for highchart
            List<Object> values = (List<Object>) serieMap.get('values');

            for (Object value : values) {
                //get time and format to epoch timestamp
                Map<String, Object> valueMap = (Map<String, Object>) value;
                List<Object> tempList = new List<Object>();
                Datetime valueTime = (Datetime) JSON.deserialize('"' + (String) valueMap.get('time') + '"', Datetime.class);
                Long timeDifference = plantTimeZone.getOffset(valueTime); //the difference from GMT timezone
                Long timeStamp = valueTime.getTime() + timeDifference;

                //get value and round to 3 decimal places
                Decimal timeValue = 0;
                if (valueMap.get('value') != 'NaN') {
                    timeValue = (Decimal) valueMap.get('value');
                    timeValue = timeValue.setScale(3);
                }

                tempList.add(timeStamp);
                tempList.add(timeValue);
                dataList.add(tempList);
            }
            tempMap.put('data', dataList);


            formatedSeries.add(tempMap);
        }
        return formatedSeries;
    }

    @AuraEnabled
    public static String getImage(String svgString, String meterId) {
        msUtility.checkObjectAccess(meterId, 'Meter__c');

        String response = '';

        try {
            svgString = svgString.substring(svgString.indexOf(',') + 1, svgString.length());
            Blob fileContent = EncodingUtil.base64Decode(svgString);
            Attachment chartImg = new Attachment();

            // aktuell eine Beispiel Id, hier muss noch über js die entsprechende id übergeben werden
            chartImg.ParentId = meterId;
            chartImg.ContentType = 'image/png';
            chartImg.Name = 'Test.png';
            chartImg.Body = fileContent;
            insert chartImg;
            response += 'The id of the inserted file: ' + chartImg.Id;
        } catch (Exception e) {
            response = e.getMessage();
        }
        return response;
    }
}
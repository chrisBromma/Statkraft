/****************************************************************************************************
 * Class msPP1PP2Controller
 *
 *   Create By      :   Fabian Kramer (mindsquare GmbH)
 *   Create Date    :   11.03.2019
 *   Description    :   Get information for API regarding the PP1 and PP1 Status. This information is used in the frontend in the eponymous page the generate a table
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                            Date               Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Kramer (mindsquare GmbH)      02.04.2019          Replace mock with real api data
 *   * Fabian Kramer (mindsquare GmbH)      11.03.2019          Init version.
 *   * Dennis Grzyb (ms)                    22.04.2021          Comment out code due to dead references to old code and no possibility to get it tested    
 *****************************************************************************************************/

public with sharing class msPP1PP2Controller {


    public static void forCoverage(){
        return;
    }

    /**
    * Get object of pp1 and pp2 object from api and transform it to List of Objects (day, pp1,pp2)
    */
    /*
    @AuraEnabled
    public static List<ppResult> callApi() {

       
        
       
         date newDate = date.today();
        String endDate = String.valueOf(newDate + 1) + 'T23:00:00Z';
        String startDate = String.valueOf(newDate - 30) + 'T23:00:00Z';

        String endpoint = 'https://apigw.statkraft.com/de/salesforce/v1/timeseries/read';
        String body = '{"names": [ "/gd_fr_rte/peak_period/capacity/rte/pp1","/gd_fr_rte/peak_period/capacity/rte/pp2"],"begin": "' + startDate + '","end": "' + endDate + '"}';
        String method = 'POST';

        //Map<String, String> tokenValues = msUtility.getApiToken();
        Statkraft_API_Values__c ApiSettings = Statkraft_API_Values__c.getValues('Prod');
        String apiKey = ApiSettings.api_key__c;

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('content-type', 'application/json');
        req.setHeader('api-key', apiKey);

        String authorization = tokenValues.get('tokenType') + ' ' + tokenValues.get('token');
        req.setHeader('Authorization', authorization); 
        if (body != null)
            req.setBody(body);
        res = http.send(req);
        String apiResult = res.getBody();

        while (apiResult.contains('"time"')) {
            apiResult = apiResult.replace('time', 'timeDate');
        }

        List<ppObject> objectList = (List<ppObject>) System.JSON.deserializeStrict(apiResult, List<ppObject>.Class);
        List<ppResult> resultList = new List<ppResult>();
        for (Integer i = 0; i < objectList[0].values.size() - 1; i++) {
            if (objectList[0].values[i].timeDate == objectList[1].values[i].timeDate) {
                ppResult resultEntry = new ppResult();
                resultEntry.day = objectList[0].values[i].timeDate;
                resultEntry.pp1 = objectList[0].values[i].value;
                resultEntry.pp2 = objectList[1].values[i].value;
                resultList.add(resultEntry);
            }
        }
        return resultList;
    } */

/*
    public static List<Object> callMock(String startDate, String endDate, String contactId) {

        String apiCallString = '';

        Integer numberOfEntries = 30;

        List <String> dates = new List<String>();
        for (Integer i = -1; i < numberOfEntries; i++) {
            date d = date.today();
            date d1 = date.today() - i;
            String d2 = string.valueOf(d1);
            String line = '{"date": "' + d2 + '", "pp1": "yes", "pp2": "no"}';
            apiCallString = apiCallString + line;
            if (i < numberOfEntries - 1) {
                apiCallString = apiCallString + ',';
            }
        }

        //System.debug(apiCallString);

        String apiCallPlaceholder = '[' + apiCallString + ']';
        //String apiCallPlaceholder = '[{"date": "2019-01-01", "pp1": "yes", "pp2": "no"}, {"date": "2019-01-02", "pp1": "yes", "pp2": "not published"},{"date": "2019-01-03", "pp1": "yes", "pp2": "not published"},{"date": "2019-01-04", "pp1": "yes", "pp2": "not published"}]';

        List<Object> result = (List<Object>) JSON.deserializeUntyped(apiCallPlaceholder);

        return result;

    }

    public class ppResult {
        @AuraEnabled Public String day { get; set; }
        @AuraEnabled Public String pp1 { get; set; }
        @AuraEnabled Public String pp2 { get; set; }
    }
    public class ppObject {
        @AuraEnabled Public String name { get; set; }
        @AuraEnabled Public List<ppStatus> values { get; set; }
    }
    public class ppStatus {
        @AuraEnabled Public String timeDate { get; set; }
        @AuraEnabled Public String value { get; set; }
    }*/
}
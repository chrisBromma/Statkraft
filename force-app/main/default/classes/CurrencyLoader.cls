global without sharing class CurrencyLoader extends BatchJobBase implements Queueable, Database.AllowsCallouts, Database.RaisesPlatformEvents {
    private static CurrencyType corporateCurrency;
    private static Map<String, CurrencyType> currencies = new Map<String, CurrencyType>();
    private static List<DatedConversionRate> currenciesDated = new List<DatedConversionRate>();
    private static List<CurrencyType> currenciesUpdate = new List<CurrencyType>();
    private static String token;
    private static BatchJobBase batchJobBase;

    global void execute(QueueableContext ctx) {
        System.attachFinalizer(this);
        super.startLogging(ctx?.getJobId());
        batchJobBase = new BatchJobBase();

        run(ctx?.getJobId());
    }

    @Future(Callout=true)
    public static void run(Id asynchJobId) {
        Datetime startDate = Datetime.now();
        run(asynchJobId, startDate);
    }

    public static void run(Id asynchJobId, Datetime startDate) {
        if (startDate == null) {
            startDate = Datetime.now();
        }
        BatchJobLogger.log(null, asynchJobId, 'Information', 'Start Conversion for: ' + startDate, 'EXECUTE');
        Logger.info('Start Conversion for: ' + startDate);

        try {
            token = getApiToken();
        } catch (Exception e) {
            Logger.error(e.getMessage());
            System.debug(e.getMessage());
        }

        getCurrencies();

        for (CurrencyType tempCurrency : currencies.values()) {
            try {
                Double conversionRate = getExchangeRate(asynchJobId, tempCurrency.IsoCode, startDate);
                DatedConversionRate newRate = new DatedConversionRate();
                newRate.IsoCode = tempCurrency.IsoCode;
                newRate.StartDate = startDate.date();
                newRate.ConversionRate = conversionRate;
                currenciesDated.add(newRate);

                CurrencyType newCurrency = new CurrencyType();
                newCurrency.Id = tempCurrency.Id;
                newCurrency.ConversionRate = conversionRate;
                currenciesUpdate.add(newCurrency);
            } catch (Exception e) {
                if (e.getMessage() != 'No Value') {
                    BatchJobLogger.log(null, asynchJobId, 'Error', e.getMessage(), 'EXECUTE');
                    Logger.error(e.getMessage());
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                }
            }
        }

        if (currenciesDated.size() != 0) {
            try {
                updateDatedCurrencies(asynchJobId);
            } catch (Exception e) {
                BatchJobLogger.log(null, asynchJobId, 'Error', e.getMessage(), 'EXECUTE');
                Logger.error(e.getMessage());
                System.debug(e.getMessage());
            }
        }

        if (currenciesUpdate.size() != 0) {
            try {
                updateCurrencies(asynchJobId);
            } catch (Exception e) {
                BatchJobLogger.log(null, asynchJobId, 'Error', e.getMessage(), 'EXECUTE');
                Logger.error(e.getMessage());
                System.debug(e.getMessage());
            }
        }
        Logger.saveLog('Currency Loader');
    }

    public static String getApiToken() {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        String body =
                'grant_type=client_credentials&client_id=' +
                        ApiSettings.BlueSeaClientID__c +
                        '&client_secret=' +
                        EncodingUtil.urlEncode(ApiSettings.BlueSeaClientSecret__c, 'UTF-8') +
                        '&resource=' +
                        EncodingUtil.urlEncode(ApiSettings.BlueSeaResource__c, 'UTF-8');

        request.setEndpoint(ApiSettings.Statkraft_Token_Endpoint__c);
        request.setMethod('POST');
        request.setHeader('content-type', 'application/X-www-form-urlencoded');
        request.setBody(body);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200) {
            Logger.error('Get API Token');
            Logger.error('Request: ' + request.toString());
            Logger.error('Response Code: ' + response.getStatusCode());
            Logger.error('Response Body: ' + response.getBody());
        }

        Map<String, Object> tokenMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (String) tokenMap.get('access_token');
    }

    public static Double getExchangeRate(Id asynchJobId, String isoCode, Datetime startDate) {
        Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
        Http http = new Http();
        String endpoint = ApiSettings.BlueSeaEndpoint__c;

        //Set IsoCode
        String isoCodeParameter = 'FX_RATE%2FSPOT%2FFX%2F_%2FMID%2FECB%2FEUR%2F' + isoCode + '%2FB';
        endpoint += isoCodeParameter;

        //Set Date
        String timeParameter =
                '/timeseries?PeriodStart=' +
                        startDate.format('yyyy-MM-dd') +
                        '&PeriodEnd=' +
                        startDate.addDays(1).format('yyyy-MM-dd');
        endpoint += timeParameter;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('content-type', 'application/json');
        request.setHeader('accept', 'application/json');
        request.setHeader('api-key', ApiSettings.BlueSeaApiKey__c);
        request.setTimeout(60000);
        request.setHeader('Authorization', 'Bearer ' + token);

        Logger.info('Get Conversion Rate for: ' + isoCode);
        Logger.info('Request: ' + request.toString());
        HttpResponse response = http.send(request);
        Logger.info('Response Code: ' + response.getStatusCode());
        Logger.info('Response Body: ' + response.getBody());

        String resultBody = response.getBody();
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(resultBody);
        List<Object> resultList = (List<Object>) resultMap.get('values');

        if (response.getStatusCode() != 200) {
            Logger.error('HTTP Request failed');
        } else if (resultList[0] == 'NaN') {
            BatchJobLogger.log(null, asynchJobId, 'Information', 'No exchange rate retrieved', 'EXECUTE');
            Logger.warn('No Value received');
            throw new IllegalArgumentException('No Value');
        } else {
            Logger.info('Exchange rate received');
        }

        return Double.valueOf(resultList[0]);
    }

    public static void updateDatedCurrencies(Id asynchJobId) {
        String sessionId = getSessionId();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v51.0/composite/sobjects');
        request.setMethod('POST');
        request.setBody('{"records":' + JSON.serialize(currenciesDated) + '}');
        request.setHeader('Authorization', 'OAuth ' + sessionId);
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = http.send(request);

        log(asynchJobId, 'Update Dated Conversion Rates', request, response);
    }

    public static void updateCurrencies(Id asynchJobId) {
        String sessionId = getSessionId();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v51.0/composite/sobjects');
        request.setMethod('PATCH');
        request.setBody('{"records":' + JSON.serialize(currenciesUpdate) + '}');
        request.setHeader('Authorization', 'OAuth ' + sessionId);
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = http.send(request);

        log(asynchJobId, 'Update Conversion Rates', request, response);
    }

    public static String getSessionId() {
        PageReference pageRef = new PageReference('/apex/getSessionID');
        String sessionId;
        if (!Test.isRunningTest()) {
            String html = pageRef.getContent().toString();
            sessionId = html.substring(html.indexOf('####') + 4, html.lastIndexOf('####'));
        } else {
            sessionId = UserInfo.getSessionId();
        }
        return sessionId;
    }

    public static void getCurrencies() {
        List<CurrencyType> currencyTypes = [
                SELECT Id, ConversionRate, DecimalPlaces, IsActive, IsCorporate, IsoCode
                FROM CurrencyType
        ];

        for (CurrencyType tempCurreny : currencyTypes) {
            if (tempCurreny.IsCorporate == true) {
                corporateCurrency = tempCurreny;
            } else {
                currencies.put(tempCurreny.IsoCode, tempCurreny);
            }
        }
    }

    private static Boolean isError(HttpResponse response) {
        Boolean isError = false;

        try {
            if (response.getStatusCode() != 200) {
                isError = true;
            } else {
                List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
                for (Object tempResult : results) {
                    Map<String, Object> tempResponse = (Map<String, Object>) tempResult;
                    if (tempResponse.get('success') != true) {
                        isError = true;
                    }
                }
            }
        } catch (Exception e) {
            Logger.error(e.getMessage());
            System.debug(e.getMessage());
            isError = true;
        }

        return isError;
    }

    private static void log(Id asynchJobId, String method, HttpRequest request, HttpResponse response) {
        if (isError(response) == true) {
            BatchJobLogger.log(null, asynchJobId, 'Information', 'Update failed: ' + method, 'EXECUTE');

            Logger.error(method);
            Logger.error('Request: ' + request.toString());
            Logger.error('Response Code: ' + response.getStatusCode());
            Logger.error('Response Body: ' + response.getBody());
        } else {
            Logger.info(method);
            Logger.info('Request: ' + request.toString());
            Logger.info('Response Code: ' + response.getStatusCode());
            Logger.info('Response Body: ' + response.getBody());
        }
    }
}
/****************************************************************************************************
* Class msBrytShoppingListControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   09.01.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   09.01.2019      	    Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msBrytShoppingListControllerTest {

    private static Integer thisYear = Date.today().year();

    @TestSetup
    private static void createTestData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void testGetPrices() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder().setBody('[' +
                '{"id":"UKPower-2020-Jul-Base",' +
                '"productName":"Jul 20",' +
                '"startTime":"2020-06-30T22:00:00Z",' +
                '"endTime":"2020-07-31T22:00:00Z",' +
                '"startDate":"2020-07-01T00:00:00",' +
                '"endDate":"2020-08-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Month",' +
                '"shape":"Base","bid":27.070685,' +
                '"offer":29.070685},' +
                '{"id":"UKPower-2020-Aug-Base",' +
                '"productName":"Aug 20",' +
                '"startTime":"2020-07-31T22:00:00Z",' +
                '"endTime":"2020-08-31T22:00:00Z",' +
                '"startDate":"2020-08-01T00:00:00",' +
                '"endDate":"2020-09-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Month",' +
                '"shape":"Base",' +
                '"bid":27.45,' +
                '"offer":29.45},' +
                '{"id":"UKPower-2020-Sep-Base",' +
                '"productName":"Sep 20",' +
                '"startTime":"2020-08-31T22:00:00Z",' +
                '"endTime":"2020-09-30T22:00:00Z",' +
                '"startDate":"2020-09-01T00:00:00",' +
                '"endDate":"2020-10-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Month",' +
                '"shape":"Base",' +
                '"bid":31.0,' +
                '"offer":33.0},' +
                '{"id":"UKPower-2020-Q3-Base",' +
                '"productName":"Q3 20",' +
                '"startTime":"2020-06-30T22:00:00Z",' +
                '"endTime":"2020-09-30T22:00:00Z",' +
                '"startDate":"2020-07-01T00:00:00",' +
                '"endDate":"2020-10-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Quarter",' +
                '"shape":"Base",' +
                '"bid":28.506895,' +
                '"offer":30.506895},' +
                '{"id":"UKPower-2020-Q4-Base",' +
                '"productName":"Q4 20",' +
                '"startTime":"2020-09-30T22:00:00Z",' +
                '"endTime":"2020-12-31T23:00:00Z",' +
                '"startDate":"2020-10-01T00:00:00",' +
                '"endDate":"2021-01-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Quarter",' +
                '"shape":"Base",' +
                '"bid":39.246004,' +
                '"offer":41.246004},' +
                '{"id":"UKPower-2021-Q1-Base",' +
                '"productName":"Q1 21",' +
                '"startTime":"2020-12-31T23:00:00Z",' +
                '"endTime":"2021-03-31T22:00:00Z",' +
                '"startDate":"2021-01-01T00:00:00",' +
                '"endDate":"2021-04-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Quarter",' +
                '"shape":"Base",' +
                '"bid":43.821717,' +
                '"offer":45.821717},' +
                '{"id":"UKPower-2020-Winter-Base",' +
                '"productName":"Winter 20",' +
                '"startTime":"2020-09-30T22:00:00Z",' +
                '"endTime":"2021-03-31T22:00:00Z",' +
                '"startDate":"2020-10-01T00:00:00",' +
                '"endDate":"2021-04-01T00:00:00",' +
                '"publishTime":"2020-06-17T09:25:47",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Season",' +
                '"shape":"Base",' +
                '"bid":41.533860,' +
                '"offer":43.533860},' +
                '{"id":"UKPower-2021-Base",' +
                '"productName":"2021",' +
                '"startTime":"2020-12-31T23:00:00Z",' +
                '"endTime":"2021-12-31T23:00:00Z",' +
                '"startDate":"2021-01-01T00:00:00",' +
                '"endDate":"2022-01-01T00:00:00",' +
                '"publishTime":"2020-06-10T10:57:00",' +
                '"expiryTime":"2020-06-17T15:35:10+02:00",' +
                '"isValid":false,' +
                '"market":"UKPower",' +
                '"source":"curve",' +
                '"period":"Year",' +
                '"shape":"Base",' +
                '"bid":40.117301,' +
                '"offer":42.117301}]').build();
        endpointToResponseMap.put(msUtility.getMetadata().BrytShoppingListEndpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Boolean isDashboardView = true;
        Test.startTest();

        System.runAs(testUser) {
            msBrytShoppingListController.getPrices(msBrytUtility.getUserDetails().contracts[0].Id, isDashboardView, TRUE);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGetSeriesForChart() {
        Map<String, HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"meteringPoint": "mt_de_bwp_westerhausen","startTime": "2019-08-01T07:45:00Z","endTime": "2019-08-01T07:45:00Z","isValid": true,"lastModifiedUser": "Michael","lastModifiedTime": "2019-09-19T07:40:27","points": [{"ts": "2019-08-01T07:30:00Z","originalLevel": null,"correctedLevel": null,"metering":21.001},{"ts": "2019-08-01T07:45:00Z","originalLevel": 20.0,"correctedLevel": 25.0,"metering":45.14},{"ts": "2019-08-01T08:00:00Z","originalLevel": null,"correctedLevel": null,"metering":25.45}]}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().Time_Series_Endpoint_Read__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));

        String [] selectedProduct = new String []{
                'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19', 'Apr 19', 'May 19', 'Jun 19'
        };
        String startDate = String.valueOf(thisYear) + '-01-01T16:14:33+00:00';
        String endDate = String.valueOf(thisYear) + '-01-15T16:14:33+00:00';
        Test.startTest();
        msBrytShoppingListController.getSeriesForChart(selectedProduct, startDate, endDate);
        Test.stopTest();
    }

    @IsTest
    private static void testSaveTrade() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        String productStrBuy = '{"id":"UKPower-2019-Mar-Base","productName":"Mar 19","startTime":"' + thisYear + '-03-01T00:00:00Z","endTime":"' + thisYear + '-03-31T23:00:00Z","startDate":"' + thisYear + '-03-01T00:00:00","endDate":"' + thisYear + '-04-01T00:00:00","publishTime":"' + thisYear + '-04-11T09:26:52.9004231Z","expiryTime":"' + thisYear + '-12-31T09:41:52.9004231Z","market":"UKPower","period":"Month","shape":"Base","bid":38.097,"offer":33.452,"volToTrade": 1, "hash":"B2Mp7f/e9wTUnHsyJsJB9BDYv2DfxVGB7M5Zl7vs53o=", "isSellback":false}';
        String productStrSell = '{"id":"UKPower-2019-Mar-Base","productName":"Mar 19","startTime":"' + thisYear + '-03-01T00:00:00Z","endTime":"' + thisYear + '-03-31T23:00:00Z","startDate":"' + thisYear + '-03-01T00:00:00","endDate":"' + thisYear + '-04-01T00:00:00","publishTime":"' + thisYear + '-04-11T09:26:52.9004231Z","expiryTime":"' + thisYear + '-12-31T09:41:52.9004231Z","market":"UKPower","period":"Month","shape":"Base","bid":38.097,"offer":33.452,"volToTrade": 1, "hash":"B2Mp7f/e9wTUnHsyJsJB9BDYv2DfxVGB7M5Zl7vs53o=", "isSellback":true}';

        Test.startTest();
        System.runAs(testUser) {
            Contract__c c = msBrytUtility.getUserDetails().contracts[0];
            msBrytShoppingListController.saveTrade(productStrBuy, c.Id);
            msBrytShoppingListController.saveTrade(productStrSell, c.Id);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGetCapacity() {

        Bryt_Reference_Capacity__c rf = [SELECT Name, Capacity_Off_Peak__c, Traded_Off_Peak__c FROM Bryt_Reference_Capacity__c LIMIT 1];
        Map<Date, Bryt_Reference_Capacity__c> rfMap = new Map<Date, Bryt_Reference_Capacity__c>();
        Date newDate = Date.newInstance(thisYear, 1, 1);
        rfMap.put(newDate, rf);
        Integer month = 12;
        Date start = Date.newInstance(thisYear, 1, 1);
        Test.startTest();
        msBrytShoppingListController.getCapacity(rfMap, month, start);
        Test.stopTest();
    }

    @IsTest
    public static void testGenerateHash() {
        msBrytShoppingListController.Product product = createProduct();
        Test.startTest();
        msBrytShoppingListController.generateHash(product);
        Test.stopTest();
    }

    @IsTest
    public static void testCheckPriceValidityFalse() {

        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        msBrytShoppingListController.Product product = createProduct();
        Datetime now = Datetime.now();
        Test.startTest();
        System.runAs(testUser) {
            Contract__c c = msBrytUtility.getUserDetails().contracts[0];
            msBrytShoppingListController.checkPriceValidity(product, c, now);
        }
        Test.stopTest();
    }

    @IsTest
    public static void testGetNewExpTimeForProduct() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];

        String productStr = '{"id":"UKPower-2019-Mar-Base","productName":"Mar 19","startTime":"' + thisYear + '-03-01T00:00:00Z","endTime":"' + thisYear + '-03-31T23:00:00Z","startDate":"' + thisYear + '-03-01T00:00:00","endDate":"' + thisYear + '-04-01T00:00:00","publishTime":"' + thisYear + '-04-11T09:26:52.9004231Z","expiryTime":"' + thisYear + '-12-31T09:41:52.9004231Z","market":"UKPower","period":"Month","shape":"Base","bid":38.097,"offer":33.452,"hash":"B2Mp7f/e9wTUnHsyJsJB9BDYv2DfxVGB7M5Zl7vs53o="}';
        Test.startTest();
        System.runAs(testUser) {
            Contract__c c = msBrytUtility.getUserDetails().contracts[0];
            msBrytShoppingListController.getNewExpTimeForProduct(productStr, c.Id);
        }
        Test.stopTest();
    }

    private static msBrytShoppingListController.Product createProduct() {

        msBrytShoppingListController.Product product = new msBrytShoppingListController.Product();
        product.bid = 100;
        product.offer = 50;
        product.id = '123123';
        product.startTime = Datetime.newInstance(thisYear, 1, 2);
        product.endTime = Datetime.newInstance(thisYear, 12, 30);
        product.startDate = Date.newInstance(thisYear, 1, 2);
        product.endDate = Date.newInstance(thisYear, 12, 30);
        product.market = 'UK';
        product.period = 'month';
        product.publishTime = Datetime.newInstance(thisYear, 1, 1);
        product.shape = '';
        product.capacityBuy = 100.00;
        product.capacitySell = 50.00;
        product.months = 1;
        product.volToTrade = 1.00;
        product.active = true;
        product.isSellback = false;
        product.hash = 'k1OSMhAr321WZ5s/W//IrWD72IFC1rgW8CCUWIzNA0U=';
        product.hours = 0.00;
        product.productName = 'Jan 19';
        product.isTradelocked = false;
        product.expiryTime = Datetime.now().addMonths(+1);
        return product;
    }
}
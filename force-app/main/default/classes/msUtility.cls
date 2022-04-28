/****************************************************************************************************
 * Class msUtility
 *
 *   Create By	:   Frank Nehler (mindsquare GmbH)
 *   Create Date	:   23.08.2018
 *   Description	:	Central class for all major operations and data initialization of the my.Statkraft
 *                   community.
 *
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	        Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Frank Nehler                              23.08.2018          Init version.
 *   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	Version 1 for deploy to Prod
 *   * Christian Gottlieb (mindsquare GmbH)      TBA                 Version 2 that works on the New Core Model
 *****************************************************************************************************/
public without sharing class msUtility {
    //TODO: msUtility should rather contain all Record Type Id definitions. Other regular classes should always reference here.
    public static final Id UK_RETAIL_CONTRACT_REC_TYPE_ID = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
        .get('UK_Retail_Portal_Contract')
        .getRecordTypeId();
    public static final String MERCHANT_PPA_CONTRACT_TYPE = 'Merchant PPA';

    //Contract Product types
    public static final List<String> FLEX_MARKET_PRODUCT_TYPES = new List<String>{
        'Flex Optimization GB',
        'Flex Optimization NI'
    };
    public static final String IRELAND_FLEX_PRODUCT_TYPE = 'Flex Optimization IRE';
    public static final String LONG_TERM_PPA_PRODUCT_TYPE = 'Long Term PPA';
    public static final String SHORT_TERM_PPA_PRODUCT_TYPE = 'Short Term PPA';
    public static final String NFPA_AUCTION_PRODUCT_TYPE = 'NFPA Auction';

    //Contract Roles
    public static final String CUSTOMER_PORTAL_CONTRACT_ROLE = 'Customer Portal';
    public static final String CONTRACTUAL_CONTACT_CONTRACT_ROLE = 'Contractual contact';
    public static final String COMMERCIAL_CONTACT_CONTRACT_ROLE = 'Commercial Contact';
    public static final String TECHNICAL_CONTACT_CONTRACT_ROLE = 'Technical Contact';

    //Site Roles
    public static final String BTR_SITE_ROLE = 'BTR';
    public static final String MAIL_RECIPIENT_CONTRACT_ROLE = 'Mail recipient';
    public static final String PAYMENT_RECIPIENT_CONTRACT_ROLE = 'Payment recipient';

    //Queue Names
    public static final String SALES_COORDINATORS_EEG_QUEUE_API_NAME = 'Sales_Coordinators_EEG';

    //Case related
    public static final Id CASE_STANDARD_REC_TYPE_ID = Application.RecordTypes.byDeveloperName('Case', 'Standard').Id;
    public static final Id CASE_MASTERDATA_CHANGEREQ_REC_TYPE_ID = Application.RecordTypes.byDeveloperName('Case', 'Customer_Portal_Master_Data_Change_Request_Case').Id;
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CASE_REASON_MASTER_DATA_CHANGE = 'Master Data Change';

    public static Map<String, Boolean> submeterSettingsMap;
    public static String environment;

    // Solar Onboarding private variables
    private static Solar_Onboarding_Settings__mdt solarOnboardingSettings;

    //Other private variables
    private static Statkraft_API_Settings__mdt metaDataSettings;
    private static msPortalSystemSetting__mdt portalSettings;
    private static Map<String, Statkraft_TimeSeries_Settings__mdt> timeSeriesSettingByName;
    private static Id pixosServiceUserId;
    private static Id systemUserId;

    // Solar Onboarding constants
    public static final Id ACCOUNT_SYS_OPERATOR_REC_TYPE_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('System_Operator')
        .getRecordTypeId();
    public static final Id METER_EXP_METER_REC_TYPE_ID = SObjectType.Meter__c.getRecordTypeInfosByDeveloperName()
        .get('Export_Meter')
        .getRecordTypeId();
    public static final Id GU_SOLAR_REC_TYPE_ID = SObjectType.Generation_Unit__c.getRecordTypeInfosByDeveloperName()
        .get('Solar')
        .getRecordTypeId();
    public static final Id PRICING_CMP_FIXED_FEE = SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName()
        .get('Fixed_Fee')
        .getRecordTypeId();
    public static final Id SITE_ROLE_CONTACT_REC_TYPE_ID = SObjectType.Site_Role__c.getRecordTypeInfosByDeveloperName()
        .get('Site_Role_Contact')
        .getRecordTypeId();
    public static final String FRAMEWORK_AGREEMENT_CONTRACT_TYPE = 'Framework Agreement';
    public static final String WHITE_LBL_PROD_TYPE = 'White Label';

    public static Boolean throwFakeException = true;

    public static HttpResponse getHttp(String endpoint, String body, String method) {
        Statkraft_API_Settings__mdt ApiSettings = getMetadata();
        Map<String, String> tokenValues = getApiToken();
        return getHttp(endpoint, body, method, ApiSettings.Statkraft_API_Key__c, tokenValues);
    }
    public static HttpResponse getHttp(String endpoint, String body, String method, String apiKey) {
        Map<String, String> tokenValues = getApiToken();
        return getHttp(endpoint, body, method, apiKey, tokenValues);
    }
    public static HttpResponse getHttp(
        String endpoint,
        String body,
        String method,
        String apiKey,
        Map<String, String> tokenValues
    ) {
        // Check if we are in Maintenance-Mode (PIM-834)
        // If true, all endpoint calls will be deactivated (return null)
        Boolean checkMaintenanceModeTrueFalse = msUtility.getPortalSettings().MaintenanceMode__c;
        if (checkMaintenanceModeTrueFalse == true) {
            // We are in maintenance mode
            return null;
        } else {
            // We are NOT in maintenance mode, continue as expected.
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();

            req.setEndpoint(endpoint);
            req.setMethod(method);
            req.setHeader('content-type', 'application/json');
            req.setHeader('api-key', apiKey);
            req.setTimeout(60000);

            String authorization = tokenValues.get('tokenType') + ' ' + tokenValues.get('token');
            req.setHeader('Authorization', authorization);
            if (body != null) {
                req.setBody(body);
            }
            System.debug('Endpoint: ' + endpoint);
            System.debug('Method: ' + method);
            System.debug('ApiKey: ' + apiKey);
            System.debug('Body: ' + body);
            System.debug('------');
            res = http.send(req);

            System.debug('Status: ' + res.getStatusCode());
            System.debug('Response1: ' + res.getBody());

            return res;
        }
    }
    private static Map<String, String> getApiToken() {
        Datetime now = Datetime.now();
        String cachedTokenString = (String) Cache.Org.get('local.PortalCache.apiToken');
        if (cachedTokenString == null || environment != null) {
            cachedTokenString = '{}';
        }
        System.debug(cachedTokenString);
        Map<String, Object> tokenMap = (Map<String, Object>) JSON.deserializeUntyped(cachedTokenString);
        String expireString = (String) tokenMap.get('expires_on');

        if (expireString == null || (now.addMinutes(45) > Datetime.newInstance(Long.valueOf(expireString) * 1000))) {
            Statkraft_API_Settings__mdt ApiSettings = msUtility.getMetadata();
            HttpRequest req = new HttpRequest();
            Http http = new Http();

            req.setEndpoint(ApiSettings.Statkraft_Token_Endpoint__c);
            req.setMethod('POST');
            req.setHeader('content-type', 'application/X-www-form-urlencoded');
            String body =
                'grant_type=client_credentials&client_id=' +
                ApiSettings.Statkraft_Token_Client_Id__c +
                '&client_secret=' +
                EncodingUtil.urlEncode(ApiSettings.Statkraft_Token_Client_Secret__c, 'UTF-8');
            req.setBody(body);
            HttpResponse res = http.send(req);

            if (environment == null) {
                Cache.Org.put('local.PortalCache.apiToken', res.getBody(), 3000);
            }

            tokenMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        }

        Map<String, String> tokenValues = new Map<String, String>{
            'tokenType' => (String) tokenMap.get('token_type'),
            'token' => (String) tokenMap.get('access_token')
        };
        return tokenValues;
    }

    public static Statkraft_API_Settings__mdt getMetadata() {
        if (metaDataSettings == null) {
            String metaDataName = getEnvironment();

            Map<String, Schema.SObjectField> fieldMap = Statkraft_API_Settings__mdt.SObjectType.getDescribe()
                .fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());

            Statkraft_API_Settings__mdt apiSettings = Database.query(
                'SELECT ' +
                String.join(fieldNames, ',') +
                ' FROM Statkraft_API_Settings__mdt WHERE DeveloperName =\'' +
                metaDataName +
                '\''
            );
            metaDataSettings = apiSettings;
        }
        return metaDataSettings;
    }
    public static msPortalSystemSetting__mdt getPortalSettings() {
        if (portalSettings == null) {
            String metaDataName = getEnvironment();

            Map<String, Schema.SObjectField> fieldMap = msPortalSystemSetting__mdt.SObjectType.getDescribe()
                .fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());

            msPortalSystemSetting__mdt apiSettings = Database.query(
                'SELECT ' +
                String.join(fieldNames, ',') +
                ' FROM msPortalSystemSetting__mdt WHERE DeveloperName =\'' +
                metaDataName +
                '\''
            );
            portalSettings = apiSettings;
        }
        return portalSettings;
    }

    public static Solar_Onboarding_Settings__mdt getSolarOnboardingSettings() {
        if (solarOnboardingSettings == null) {
            String metaDataName = getEnvironment();

            Map<String, Schema.SObjectField> fieldMap = Solar_Onboarding_Settings__mdt.SObjectType.getDescribe()
                .fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());

            Solar_Onboarding_Settings__mdt settings = Database.query(
                'SELECT ' +
                String.join(fieldNames, ',') +
                ' FROM Solar_Onboarding_Settings__mdt WHERE DeveloperName =\'' +
                metaDataName +
                '\''
            );
            solarOnboardingSettings = settings;
        }
        return solarOnboardingSettings;
    }

    public static Id getPixosServiceUserId() {
        if (pixosServiceUserId == null) {
            User pixosUser = [SELECT Id FROM User WHERE Name = 'Pixos Service' LIMIT 1];
            pixosServiceUserId = pixosUser.Id;
        }
        return pixosServiceUserId;
    }

    public static Id getSystemUserId() {
        if (systemUserId == null) {
            User systemUser = [SELECT Id FROM User WHERE Name = 'System' LIMIT 1];
            systemUserId = systemUser.Id;
        }
        return systemUserId;
    }

    public static String getEnvironment() {
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String metaDataName = 'Production';
        if (runningInASandbox) {
            metaDataName = 'PreProd';
        }

        if (environment != null) {
            metaDataName = environment;
        }

        return metaDataName;
    }

    public static Map<String, Statkraft_TimeSeries_Settings__mdt> getAllTimeSeriesSettings() {
        if (timeSeriesSettingByName == null) {
            timeSeriesSettingByName = new Map<String, Statkraft_TimeSeries_Settings__mdt>();
            Map<String, Schema.SObjectField> fieldMap = Statkraft_TimeSeries_Settings__mdt.SObjectType.getDescribe()
                .fields.getMap();
            String[] fieldNames = new List<String>(fieldMap.keySet());
            for (
                Statkraft_TimeSeries_Settings__mdt setting : Database.query(
                    'SELECT ' +
                    String.join(fieldNames, ',') +
                    ' FROM Statkraft_TimeSeries_Settings__mdt '
                )
            ) {
                timeSeriesSettingByName.put(setting.DeveloperName, setting);
            }
        }
        return timeSeriesSettingByName;
    }

    /**
     * @description - This method is central for the initialization of the community and retrieves data for the
     * Session Loader Component.
     */
    @AuraEnabled
    public static UserDetails getUserDetails() {
        UserDetails result;
        try {
            result = (UserDetails) Cache.Session.get('local.PortalCache.userDetails');
        } catch (Cache.Session.SessionCacheException e) {
            System.debug(e.getMessage());
        }

        if (
            result == null ||
            result.user.Id != UserInfo.getUserId() ||
            result.user.LanguageLocaleKey != UserInfo.getLanguage()
        ) {
            System.debug('Load User Details');
            result = new UserDetails();
            User user = [
                SELECT Name, Profile.Name, ContactId, LanguageLocaleKey, MobilePhone, Email, Contact.Name, Username
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            result.user = user;

            // Check for maintenance-mode. TRUE/FALSE
            Boolean checkMaintenanceModeTrueFalse = msUtility.getPortalSettings().MaintenanceMode__c;
            result.maintenance = checkMaintenanceModeTrueFalse; // Write boolean to our wrapper class field

            if (user.ContactId != null) {
                result.contact = user.Contact;
                result = getMeterInformation(result, user.ContactId);
                if (Test.isRunningTest() == false) {
                    result.unreadMessages = msNotificationBoardController.getUnreadMessages();
                }
            }

            try {
                Cache.Session.put('local.PortalCache.userDetails', result, 600);
            } catch (Cache.Session.SessionCacheException e) {
                System.debug(e.getMessage());
            }
        }
        return result;
    }

    private static UserDetails getMeterInformation(UserDetails result, String contactId) {
        Map<String, msUtility.FeatureSetting> settings = msUtility.getFeatureSettings();
        Map<String, Set<String>> meter2ContractName = new Map<String, Set<String>>();
        Map<String, List<MeterRegistration__c>> meterRegistrationMap = new Map<String, List<MeterRegistration__c>>();
        Boolean isContractualContact = false;
        Map<String, msUtility.FeatureSetting> meterFeatures = new Map<String, msUtility.FeatureSetting>();
        List<Id> meterIds = new List<Id>();
        Set<String> countries = new Set<String>();
        Set<String> markets = new Set<String>();
        Set<Id> contractIds = new Set<Id>();

        Date today = Date.today();
        Date startLastYear = Date.newInstance(today.year() - 1, 1, 1);

        List<Contract_Role__c> contractRoles = [
            SELECT Contract__c, Role__c
            FROM Contract_Role__c
            WHERE
                (Contract__r.Status__c = 'Active'
                OR (Contract__r.Status__c = 'Expired'
                AND Contract__r.KeepPortalAccessUntil__c >= :Date.today()))
                AND Contact__c = :contactId
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today()
                OR End_Date__c = NULL)
        ];

        List<Site_Role__c> siteRoles = [
            SELECT Meter__c, Meter__r.Current_Contract__c
            FROM Site_Role__c
            WHERE
                Contact__c = :contactId
                AND Role__c INCLUDES (:CUSTOMER_PORTAL_CONTRACT_ROLE)
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today()
                OR End_Date__c = NULL)
                AND (Meter__r.Current_Contract__r.Status__c = 'Active'
                OR (Meter__r.Current_Contract__r.Status__c = 'Expired'
                AND Meter__r.Current_Contract__r.KeepPortalAccessUntil__c >= :Date.today()))
        ];

        for (Site_Role__c tempSiteRole : siteRoles) {
            meterIds.add(tempSiteRole.Meter__c);
        }

        for (Contract_Role__c tmpContractRole : contractRoles) {
            if (tmpContractRole.Role__c.contains(CUSTOMER_PORTAL_CONTRACT_ROLE)) {
                contractIds.add(tmpContractRole.Contract__c);
            }
            if (tmpContractRole.Role__c.contains(CONTRACTUAL_CONTACT_CONTRACT_ROLE)) {
                isContractualContact = true;
            }
        }

        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>(
            [
                SELECT
                    Name,
                    Alternative_Contract_Name__c,
                    KeepPortalAccessUntil__c,
                    Contract_Holder__r.Name,
                    RecordType.DeveloperName,
                    Meter_Billing_Type__c,
                    Country__c,
                    Global_Portal_Market__c,
                    Contract_Type_New__c,
                    Product_Type_New__c,
                    Contract_Type__c,
                    Portal_PM__c,
                    Customer_Portal_Master_Data_Update__c
                FROM Contract__c
                WHERE Id IN :contractIds
            ]
        );

        List<MeterRegistration__c> meterRegistrations = [
            SELECT
                Meter__c,
                Contract__r.Name,
                Contract__r.Meter_Billing_Type__c,
                Contract__r.Parent_Contract__r.Name,
                Contract__r.Global_Portal_Market__c,
                Contract__r.Contract_Type__c,
                Contract__r.Contract_Type_New__c,
                Contract__r.Product_Type_New__c,
                Contract__r.Country__c,
                Contract__r.RecordTypeId,
                Contract__r.Status__c,
                Contract__r.Created_through_Portal__c,
                Contract__r.Portal_PM__c,
                Contract__c,
                Meter__r.Parent_Meter__c,
                Meter__r.Country__c,
                Meter__r.Name,
                Valid_from__c,
                Valid_to__c
            FROM MeterRegistration__c
            WHERE
                Valid_from__c <= :Date.today()
                AND ((Contract__r.Status__c = 'Active'
                AND (Valid_to__c >= :Date.today()
                OR Valid_to__c = NULL))
                OR (Contract__r.Status__c = 'Expired'
                AND Contract__r.KeepPortalAccessUntil__c >= :Date.today()))
                AND Meter__c IN :meterIds
            ORDER BY Contract__r.Start_Date__c DESC
        ];

        result.meterRegistrations = meterRegistrations;
        Set<Id> meterContractIds = new Set<Id>();
        for (MeterRegistration__c regItem : meterRegistrations) {
            meterIds.add(regItem.Meter__c);
            meterContractIds.add(regItem.Contract__c);
            if (regItem.Meter__r.Parent_Meter__c != null) {
                meterIds.add(regItem.Meter__r.Parent_Meter__c);
            }

            if (regItem.Meter__r.Country__c == 'Germany') {
                String meterId = regItem.Meter__c;
                if (regItem.Meter__r.Parent_Meter__c != null)
                    meterId = regItem.Meter__r.Parent_Meter__c;

                Set<String> contractNames = meter2ContractName.get(meterId);
                if (contractNames == null) {
                    contractNames = new Set<String>();
                }

                if (contractNames.size() == 2) {
                    contractNames.add('...');
                } else if (contractNames.size() < 2) {
                    String contractNameTemp = regItem.Contract__r.Name;
                    if (regItem.Contract__r.Parent_Contract__r != null) {
                        contractNameTemp = regItem.Contract__r.Parent_Contract__r.Name;
                    }
                    contractNames.add(msUtility.getLeftPartOfStringRelativeToLastDivider(contractNameTemp, '/'));
                }
                meter2ContractName.put(meterId, contractNames);
            }

            List<MeterRegistration__c> regOfMeter = meterRegistrationMap.get(regItem.Meter__c);
            if (regOfMeter == null) {
                regOfMeter = new List<MeterRegistration__c>();
            }
            regOfMeter.add(regItem);
            meterRegistrationMap.put(regItem.Meter__c, regOfMeter);
        }

        Map<Id, Meter__c> metersMap = new Map<Id, Meter__c>(
            [
                SELECT
                    Id,
                    Name,
                    Country__c,
                    Main_Technology__c,
                    GPS_Location__Longitude__s,
                    GPS_Location__Latitude__s,
                    RecordType.Name,
                    Installed_Capacity__c,
                    Parent_Meter__c,
                    Current_Contract__c,
                    Current_Contract__r.Name,
                    Marktstammdatenregister_ID__c,
                    Status__c,
                    Tertiary_Reserve__c,
                    Prequalified_Reserve_Capacity__c,
                    CreatedDate,
                    (SELECT Id, Installed_Capacity__c FROM Meters__r)
                FROM Meter__c
                WHERE Id IN :meterIds
                ORDER BY Name
            ]
        );

        for (MeterRegistration__c meterRegistration : meterRegistrations) {
            meterRegistration.Contract__r.Name = msUtility.getLeftPartOfStringRelativeToLastDivider(
                meterRegistration.Contract__r.Name,
                '/'
            );
            metersMap.get(meterRegistration.Meter__c).Current_Contract__r = meterRegistration.Contract__r;
        }

        //Get Feature Settings for contracts
        for (Contract__c contract : contractsMap.values()) {
            if (contract.Global_Portal_Market__c == null) {
                contract.Global_Portal_Market__c = determineMarket(contract);
            }
            FeatureSetting featureSetting = (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                JSON.serialize(settings.get(contract.Global_Portal_Market__c + '_Contract')),
                msUtility.FeatureSetting.class
            );
            featureSetting.entityName = contract.Name;
            meterFeatures.put(contract.Id, featureSetting);

            contract.Name = msUtility.getLeftPartOfStringRelativeToLastDivider(contract.Name, '/');

            //If true we don't have to verify this again.
            if (
                result.haveSolarOnboardingWLParentContract == null ||
                result.haveSolarOnboardingWLParentContract == false
            ) {
                result.haveSolarOnboardingWLParentContract = (contract.Contract_Type_New__c ==
                    FRAMEWORK_AGREEMENT_CONTRACT_TYPE &&
                    contract.Product_Type_New__c == WHITE_LBL_PROD_TYPE &&
                    contract.Portal_PM__c == true)
                    ? true
                    : false;
            }
        }

        Map<Id, Contract__c> meterContractsMap = msSubmeterUtility.getSubMeterContracts(meterContractIds);
        for (Meter__c meter : metersMap.values()) {
            countries.add(meter.Country__c);
            msUtility.FeatureSetting featureSetting = (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                JSON.serialize(new msUtility.FeatureSetting()),
                msUtility.FeatureSetting.class
            );
            List<MeterRegistration__c> regOfMeter = meterRegistrationMap.get(meter.Id);

            Set<String> contractNames = meter2ContractName.get(meter.Id);
            if (contractNames != null) {
                List<String> namesList = new List<String>();
                namesList.addAll(contractNames);
                meter.Description__c = '(' + String.join(namesList, ', ') + ')';
            }

            //Get Feature Settings for meters
            if (regOfMeter == null) {
                if (meter.Country__c != 'United Kingdom') {
                    featureSetting = (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                        JSON.serialize(settings.get(meter.Country__c)),
                        msUtility.FeatureSetting.class
                    );
                } else {
                    featureSetting = (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                        JSON.serialize(settings.get(PortalMarket.Flex.name())),
                        msUtility.FeatureSetting.class
                    );
                }
                System.debug('allocated feature setting: ' + featureSetting.market);
            } else {
                System.debug('meter reg was not null for meter' + meter.Name);
                if (regOfMeter[0].Contract__r.Global_Portal_Market__c == null) {
                    regOfMeter[0].Contract__r.Global_Portal_Market__c = determineMarket(regOfMeter[0]);
                }
                featureSetting = (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                    JSON.serialize(settings.get(regOfMeter[0].Contract__r.Global_Portal_Market__c)),
                    msUtility.FeatureSetting.class
                );
                System.debug('allocated feature setting: ' + featureSetting.market);
            }
            featureSetting.entityName = meter.Name;
            featureSetting.showReservePower =
                featureSetting.showReservePower &&
                meter.Tertiary_Reserve__c &&
                meter.Prequalified_Reserve_Capacity__c > 0;
            featureSetting.marketCurrencyCode = settings.get(featureSetting.market + '_Contract').marketCurrencyCode;

            if (regOfMeter != null) {
                Boolean submeterView = false;
                for (MeterRegistration__c temRegistration : regOfMeter) {
                    Contract__c registrationContract = meterContractsMap.get(temRegistration.Contract__c);
                    for (Pricing_Component__c localPricingComponent : registrationContract.Pricing_Components__r) {
                        if (
                            msSubmeterUtility.isMeterBillingTypePricingComponent(localPricingComponent) &&
                            localPricingComponent.Start_Date__c <= today &&
                            localPricingComponent.End_Date__c >= startLastYear &&
                            (featureSetting.submeterView &&
                            (localPricingComponent.Meter_Billing_Type__c == 'Sub-Meter Yearly' ||
                            localPricingComponent.Meter_Billing_Type__c == 'Sub-Meter Monthly'))
                        ) {
                            submeterView = true;
                        }
                    }
                    if (featureSetting.isFlexChart) {
                        FeatureSetting contractSetting = meterFeatures.get(registrationContract.Id);
                        if (contractSetting != null && contractSetting.cashflowCharts == true) {
                            featureSetting.cashflowCharts = true;
                        }
                    }
                }
                featureSetting.submeterView = submeterView;
            }

            if (meter.Meters__r.size() == 0) {
                if (meter.Parent_Meter__c != null) {
                    meterFeatures.put(
                        meter.Parent_Meter__c,
                        (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                            JSON.serialize(featureSetting),
                            msUtility.FeatureSetting.class
                        )
                    );
                    meterFeatures.put(
                        meter.Id,
                        (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                            JSON.serialize(featureSetting),
                            msUtility.FeatureSetting.class
                        )
                    );
                } else {
                    meterFeatures.put(
                        meter.Id,
                        (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                            JSON.serialize(featureSetting),
                            msUtility.FeatureSetting.class
                        )
                    );
                }
            }
            metersMap.put(meter.Id, meter);
        }

        for (msUtility.FeatureSetting tmpSetting : meterFeatures.values()) {
            markets.add(tmpSetting.market);
        }

        meterFeatures = setFeatureEnablements(meterFeatures, contactId);
        result.countries = countries;
        result.plantFeatures = meterFeatures;
        result.userFeatures = getUserFeatures(meterFeatures.values(), isContractualContact);
        result.plants = metersMap.values();
        result.contracts = contractsMap.values();
        result.news = getNews(markets);
        return result;
    }

    public static Map<String, FeatureSetting> getFeatureSettings() {
        Map<String, FeatureSetting> featureSettingsMap = new Map<String, FeatureSetting>();
        if (submeterSettingsMap == null) {
            List<PortalSettings__c> settings = [
                SELECT Checkbox__c, Name
                FROM PortalSettings__c
                WHERE Name = 'Annual Submeter - Allow Update' OR Name = 'Monthly Submeter - Allow Update'
            ];
            submeterSettingsMap = new Map<String, Boolean>();
            for (PortalSettings__c tmp : settings) {
                submeterSettingsMap.put(tmp.Name, tmp.Checkbox__c);
            }
        }

        Map<String, Schema.SObjectField> fieldMap = msPortalMarketFeature__mdt.SObjectType.getDescribe()
            .fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());
        List<msPortalMarketFeature__mdt> featureSettings = Database.query(
            'SELECT ' +
            String.join(fieldNames, ',') +
            ' FROM msPortalMarketFeature__mdt'
        );

        for (msPortalMarketFeature__mdt tmp : featureSettings) {
            if (tmp.submeterEditYearly__c == true) {
                tmp.submeterEditYearly__c = submeterSettingsMap.get('Annual Submeter - Allow Update');
            }
            if (tmp.submeterEditMonthly__c == true) {
                tmp.submeterEditYearly__c = (submeterSettingsMap.get('Annual Submeter - Allow Update') ||
                submeterSettingsMap.get('Monthly Submeter - Allow Update'));
            }

            featureSettingsMap.put(tmp.DeveloperName, new FeatureSetting(tmp));
        }

        return featureSettingsMap;
    }

    private static Map<String, msUtility.FeatureSetting> setFeatureEnablements(
        Map<String, msUtility.FeatureSetting> meterFeatures,
        Id contactId
    ) {
        List<FeatureEnablement__c> featureEnablements = [
            SELECT Meter__c, Meter__r.Parent_Meter__c, Contract__c, Feature__c
            FROM FeatureEnablement__c
            WHERE
                Valid_from__c <= :Date.today()
                AND Valid_to__c >= :Date.today()
                AND (Meter__c IN :meterFeatures.keySet()
                OR Contract__c IN :meterFeatures.keySet())
                AND (Contact__c = NULL
                OR Contact__c = :contactId)
        ];

        Map<String, String> picklistToFeatureseting = new Map<String, String>();
        picklistToFeatureseting.put('curtailment_allow_edit', 'isDownregulationEdit');
        picklistToFeatureseting.put('curtailment_allow_view', 'isDownregulationView');
        picklistToFeatureseting.put('curtailments_paragraph_51', 'isParagraph51');
        picklistToFeatureseting.put('downloads', 'isDownloads');
        picklistToFeatureseting.put('downtime_allow_view', 'isDowntime');
        picklistToFeatureseting.put('downtime_partial_outage', 'partialOutage');
        picklistToFeatureseting.put('downtime_single_units_affected', 'isSingleUnitsAffected');
        picklistToFeatureseting.put('earnings_data_chart', 'isViewEarningsDataChart');
        picklistToFeatureseting.put('file_upload', 'isFileUpload');
        picklistToFeatureseting.put('map_on_home', 'isMapOnHome');
        picklistToFeatureseting.put('master_data', 'isMasterData');
        picklistToFeatureseting.put('newsfeed', 'isNewsfeed');
        picklistToFeatureseting.put('notifications', 'isNotifications');
        picklistToFeatureseting.put('payment', 'isPayments');
        picklistToFeatureseting.put('plants', 'isPlants');
        picklistToFeatureseting.put('production_chart', 'isViewProductionChart');
        picklistToFeatureseting.put('remit_transparency', 'isREMITTransparency');
        picklistToFeatureseting.put('newsfeed', 'isNewsfeed');
        picklistToFeatureseting.put('submeter_edit_monthly', 'submeterEditMonthlyIndividual');
        picklistToFeatureseting.put('submeter_edit_yearly', 'submeterEditYearly');
        picklistToFeatureseting.put('submeter_view', 'submeterView');
        picklistToFeatureseting.put('flex_chart', 'isFlexChart');
        picklistToFeatureseting.put('user_management', 'userManagement');
        picklistToFeatureseting.put('welcome_message_on_home', 'isWelcomeMessageOnHome');

        for (FeatureEnablement__c tmpFeatureEnablement : featureEnablements) {
            String key = tmpFeatureEnablement.Contract__c;
            if (key == null)
                key = tmpFeatureEnablement.Meter__c;

            Map<String, Object> featureSettingMap = (Map<String, Object>) JSON.deserializeUntyped(
                JSON.serialize(meterFeatures.get(key))
            );
            featureSettingMap.put(picklistToFeatureseting.get(tmpFeatureEnablement.Feature__c), true);

            meterFeatures.put(
                key,
                (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                    JSON.serialize(featureSettingMap),
                    msUtility.FeatureSetting.class
                )
            );

            if (tmpFeatureEnablement.Meter__r != null && tmpFeatureEnablement.Meter__r.Parent_Meter__c != null) {
                Map<String, Object> featureSettingMapParent = (Map<String, Object>) JSON.deserializeUntyped(
                    JSON.serialize(meterFeatures.get(tmpFeatureEnablement.Meter__r.Parent_Meter__c))
                );
                featureSettingMapParent.put(picklistToFeatureseting.get(tmpFeatureEnablement.Feature__c), true);
                meterFeatures.put(
                    tmpFeatureEnablement.Meter__r.Parent_Meter__c,
                    (msUtility.FeatureSetting) System.JSON.deserializeStrict(
                        JSON.serialize(featureSettingMapParent),
                        msUtility.FeatureSetting.class
                    )
                );
            }
        }

        return meterFeatures;
    }

    private static FeatureSetting getUserFeatures(List<FeatureSetting> featureSettings, Boolean isContractualContact) {
        try {
            FeatureSetting result = featureSettings[0];
            for (FeatureSetting tmpSetting : featureSettings) {
                result = new FeatureSetting(result, tmpSetting);
            }
            result.userManagement = (result.userManagement && isContractualContact);

            return result;
        } catch (ListException e) {
            throw new AuraHandledException(Label.errorMessageNoPlantOrContractRole);
        }
    }

    private static List<PortalNews__c> getNews(Set<String> markets) {
        List<PortalNews__c> news = (List<PortalNews__c>) [
            SELECT Publication_Date__c, Title__c, Text__c, msMarkets__c
            FROM PortalNews__c
            WHERE
                Type__c = 'Maintenance Information'
                AND Language__c = :UserInfo.getLanguage()
                AND Publication_Date__c <= :Date.today()
                AND (End__c >= :Date.today()
                OR End__c = NULL)
            ORDER BY CreatedDate DESC
        ];
        for (PortalNews__c newsItem : news) {
            List<String> itemMarkets = newsItem.msMarkets__c.split(';');
            for (String market : itemMarkets) {
                if (markets.contains(market)) {
                    List<PortalNews__c> results = new List<PortalNews__c>();
                    results.add(newsItem);
                    return results;
                }
            }
        }
        return new List<PortalNews__c>();
    }

    public static Set<String> getUserMarkets() {
        Set<String> userMarkets = new Set<String>();
        UserDetails userDetails = getUserDetails();
        if (userDetails != null && userDetails.plantFeatures != null) {
            Map<String, FeatureSetting> allSetting = (Map<String, FeatureSetting>) userDetails.plantFeatures;
            for (String key : allSetting.keySet()) {
                userMarkets.add(allSetting.get(key).market);
            }
        }
        return userMarkets;
    }

    public static Map<Id, UserDetails> getContactDetails(Set<Id> contactIds) {
        Map<Id, UserDetails> contactDetailsById = new Map<Id, UserDetails>();
        Map<Id, Set<String>> contactMarketsById = getContactActiveMarkets(contactIds);
        for (Contact contact : [SELECT Id, Name, Email FROM Contact WHERE Id IN :contactIds]) {
            UserDetails userDetailsWrapper = new UserDetails();
            userDetailsWrapper.contact = contact;
            userDetailsWrapper.countries = contactMarketsById.get(contact.Id);
            contactDetailsById.put(contact.Id, userDetailsWrapper);
        }
        return contactDetailsById;
    }

    public static Map<Id, Set<String>> getContactActiveMarkets(Set<Id> contactIds) {
        Map<Id, Set<String>> results = new Map<Id, Set<String>>();
        List<Contract_Role__c> contractRoles = [
            SELECT
                Id,
                Contract__r.Global_Portal_Market__c,
                Contract__r.RecordTypeId,
                Contract__r.Contract_Type_New__c,
                Contract__r.Contract_Type__c,
                Contract__r.Product_Type_New__c,
                Contract__r.Country__c,
                Contact__c
            FROM Contract_Role__c
            WHERE
                (Contract__r.Status__c = 'Active'
                OR Contract__r.KeepPortalAccessUntil__c >= :Date.today())
                AND Contact__c IN :contactIds
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today()
                OR End_Date__c = NULL)
        ];

        for (Id contactId : contactIds) {
            results.put(contactId, new Set<String>());
            for (Contract_Role__c role : contractRoles) {
                if (contactId == role.Contact__c) {
                    if (role.Contract__r.Global_Portal_Market__c == null) {
                        role.Contract__r.Global_Portal_Market__c = determineMarket(role);
                    }
                    results.get(contactId).add(role.Contract__r.Global_Portal_Market__c);
                }
            }
        }
        return results;
    }

    @AuraEnabled
    public static FeatureSetting getMeterFeatures(Meter__c meter) {
        return getMeterFeatures(meter.Id);
    }
    @AuraEnabled
    public static FeatureSetting getMeterFeatures(Id meterId) {
        UserDetails userDetails = getUserDetails();

        Map<String, FeatureSetting> allSetting = (Map<String, FeatureSetting>) userDetails.plantFeatures;
        return allSetting.get(meterId);
    }

    public static Boolean checkObjectAccess(String objectId, String objectType) {
        UserDetails userDetails = getUserDetails();

        if (objectType == 'Contract__c') {
            for (Contract__c tempContract : userDetails.contracts) {
                if (tempContract.Id == objectId)
                    return true;
            }
        } else if (objectType == 'Meter__c') {
            for (Meter__c tempMeter : userDetails.plants) {
                if (tempMeter.Id == objectId)
                    return true;
            }
        }

        throw new AuraHandledException('User not allowed to access ' + objectType + ': ' + objectId);
    }

    public static Boolean checkFeatureAccess(Id id, String feature) {
        UserDetails userDetails = getUserDetails();
        Map<String, FeatureSetting> allSetting = (Map<String, FeatureSetting>) userDetails.plantFeatures;

        FeatureSetting featureSetting = allSetting.get(id);
        if (featureSetting == null) {
            throw new AuraHandledException('User not allowed to access ' + id.getSobjectType() + ': ' + id);
        }

        String featureSettingString = JSON.serialize(featureSetting);
        Map<String, Object> featureSettingMap = (Map<String, Object>) JSON.deserializeUntyped(featureSettingString);
        if (featureSettingMap.get(feature) == false) {
            throw new AuraHandledException(
                'Feature is \'' +
                feature +
                '\' is not enabled for  ' +
                id.getSobjectType() +
                ': ' +
                id
            );
        }
        return true;
    }

    public static String determineMarket(Contract__c contract) {
        String market;

        List<PicklistEntry> markets = Contract__c.Global_Portal_Market__c.getDescribe().getPicklistValues();
        Set<String> validMarkets = new Set<String>();
        for (PicklistEntry marketEntry : markets) {
            validMarkets.add(marketEntry.getValue());
        }

        if (
            contract.Contract_Type_New__c == MERCHANT_PPA_CONTRACT_TYPE &&
            FLEX_MARKET_PRODUCT_TYPES.contains(contract.Product_Type_New__c)
        ) {
            market = PortalMarket.Flex.name();
        } else if (
            contract.Contract_Type_New__c == MERCHANT_PPA_CONTRACT_TYPE &&
            contract.Product_Type_New__c == IRELAND_FLEX_PRODUCT_TYPE
        ) {
            market = PortalMarket.IrelandFlex.name();
        } else if (contract.Country__c == 'United Kingdom') {
            if (
                contract.Contract_Type_New__c == MERCHANT_PPA_CONTRACT_TYPE &&
                (contract.Product_Type_New__c == LONG_TERM_PPA_PRODUCT_TYPE ||
                contract.Product_Type_New__c == SHORT_TERM_PPA_PRODUCT_TYPE ||
                contract.Product_Type_New__c == NFPA_AUCTION_PRODUCT_TYPE)
            ) {
                market = PortalMarket.UK.name();
            } else if (contract.RecordTypeId == UK_RETAIL_CONTRACT_REC_TYPE_ID) {
                market = PortalMarket.UKRetail.name();
            }
        } else {
            market = contract.Country__c;
        }

        if (!validMarkets.contains(market)) {
            market = null;
        }
        return market;
    }

    public static String determineMarket(MeterRegistration__c meterReg) {
        Contract__c containerContract = new Contract__c(
            Contract_Type_New__c = meterReg.Contract__r.Contract_Type_New__c,
            Product_Type_New__c = meterReg.Contract__r.Product_Type_New__c,
            Country__c = meterReg.Contract__r.Country__c,
            Contract_Type__c = meterReg.Contract__r.Contract_Type__c,
            RecordTypeId = meterReg.Contract__r.RecordTypeId
        );
        return determineMarket(containerContract);
    }

    public static String determineMarket(Contract_Role__c contractRole) {
        Contract__c containerContract = new Contract__c(
            Contract_Type_New__c = contractRole.Contract__r.Contract_Type_New__c,
            Product_Type_New__c = contractRole.Contract__r.Product_Type_New__c,
            Country__c = contractRole.Contract__r.Country__c,
            Contract_Type__c = contractRole.Contract__r.Contract_Type__c,
            RecordTypeId = contractRole.Contract__r.RecordTypeId
        );
        return determineMarket(containerContract);
    }

    public static Map<Id, Contract__c> determineContract(List<Id> meterIds) {
        Date today = Date.today();
        Map<Id, Contract__c> resultMap = new Map<Id, Contract__c>();
        List<MeterRegistration__c> meterRegistrations = [
            SELECT
                Meter__c,
                Contract__r.Name,
                Contract__r.Meter_Billing_Type__c,
                Contract__c,
                Meter__r.Parent_Meter__c,
                Meter__r.Country__c,
                Meter__r.Name,
                Contract__r.Parent_Contract__r.Name,
                Contract__r.Global_Portal_Market__c,
                Contract__r.Start_Date__c,
                Contract__r.KeepPortalAccessUntil__c,
                Contract__r.End_Date__c,
                Valid_from__c,
                Valid_to__c
            FROM MeterRegistration__c
            WHERE
                Valid_from__c <= :today
                AND ((Contract__r.Status__c = 'Active'
                AND (Valid_to__c >= :today
                OR Valid_to__c = NULL))
                OR (Contract__r.Status__c = 'Expired'
                AND Contract__r.KeepPortalAccessUntil__c >= :today))
                AND (Meter__c IN :meterIds
                OR Meter__r.Parent_Meter__c IN :meterIds)
            ORDER BY Contract__r.Start_Date__c DESC
        ];

        for (MeterRegistration__c tempReg : meterRegistrations) {
            resultMap.put(tempReg.Meter__c, tempReg.Contract__r);
        }
        return resultMap;
    }
    public static Map<Id, Contract__c> determineContract(List<Meter__c> meters) {
        List<Id> meterIds = new List<Id>();
        for (Meter__c tempMeter : meters) {
            meterIds.add(tempMeter.Id);
        }
        return determineContract(meterIds);
    }
    public static Map<Id, Contract__c> determineContract(List<Site_Role__c> siteRoles) {
        List<Id> meterIds = new List<Id>();
        for (Site_Role__c tempRole : siteRoles) {
            meterIds.add(tempRole.Meter__c);
        }
        return determineContract(meterIds);
    }

    public static String utcDateToString(Datetime dt) {
        return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }
    public static Datetime parseUtcDateTime(String dt) {
        if (dt.contains('T')) {
            return Datetime.valueOfGmt(dt.replace('T', ' ') + 'Z');
        } else {
            return Datetime.valueOfGmt(dt);
        }
    }
    public static BackendMonitoring__e getEvent(String method) {
        BackendMonitoring__e logEvent = new BackendMonitoring__e(
            Start__c = Datetime.now(),
            Method__c = method,
            IsError__c = false
        );
        return logEvent;
    }
    public static BackendMonitoring__e handleException(BackendMonitoring__e logEvent, Exception e) {
        String message = '\n*** Message: ' + e.getMessage();
        message += '\n*** LineNumber: ' + e.getLineNumber();
        message += '\n*** Cause: ' + e.getCause();
        message += '\n*** TypeName: ' + e.getTypeName();
        message += '\n*** StackTrace: ' + e.getStackTraceString();
        message += '\n\n\n';
        logEvent.IsError__c = true;
        logEvent.Message__c += message;
        return logEvent;
    }
    public static void publishEvent(BackendMonitoring__e logEvent) {
        logEvent.End__c = Datetime.now();
        EventBus.publish(new List<BackendMonitoring__e>{ logEvent });
    }
    public virtual class BaseException extends Exception {
    }
    public class FakeException extends BaseException {
    }
    public static void ifTestThrowFakeException() {
        if (Test.isRunningTest() && throwFakeException) {
            throw new FakeException('Exception to test catch');
        }
    }
    public static String getLeftPartOfStringRelativeToLastDivider(String given_string, String divison_char) {
        if (!given_string.contains(divison_char)) {
            return given_string;
        }
        Integer index = given_string.lastIndexOf(divison_char);
        return given_string.left(index);
    }

    public static List<Custom_Validation_Passes__mdt> getValidationPasses() {
        Map<String, Schema.SObjectField> fieldMap = Custom_Validation_Passes__mdt.SObjectType.getDescribe()
            .fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());

        List<Custom_Validation_Passes__mdt> validationPasses = Database.query(
            'SELECT ' +
            String.join(fieldNames, ',') +
            ' FROM Custom_Validation_Passes__mdt WHERE Profile_Id__c =\'' +
            UserInfo.getProfileId() +
            '\''
        );
        return validationPasses;
    }

    public static List<LabelValuePair> getPickListValues(SObjectField field) {
        List<LabelValuePair> options = new List<LabelValuePair>();
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : picklistEntries) {
            options.add(new LabelValuePair(f.getLabel(), f.getValue()));
        }
        return options;
    }

    public class FeatureSetting {
        @AuraEnabled
        public Boolean isNewsfeed { get; set; }
        @AuraEnabled
        public Boolean isDowntime { get; set; }
        @AuraEnabled
        public Boolean isREMITTransparency { get; set; }
        @AuraEnabled
        public Boolean isDownregulationView { get; set; }
        @AuraEnabled
        public Boolean isDownregulationEdit { get; set; }
        @AuraEnabled
        public Boolean isFlexChart { get; set; }
        @AuraEnabled
        public Boolean isDownloads { get; set; }
        @AuraEnabled
        public Boolean isPayments { get; set; }
        @AuraEnabled
        public Boolean isEisman { get; set; }
        @AuraEnabled
        public Boolean isMasterData { get; set; }
        @AuraEnabled
        public Boolean isFileUpload { get; set; }
        @AuraEnabled
        public Boolean enablePricingFileUpload { get; set; }
        @AuraEnabled
        public Boolean isNotifications { get; set; }
        @AuraEnabled
        public Boolean isPlants { get; set; }
        @AuraEnabled
        public Boolean isSolarOnboarding { get; set; }
        @AuraEnabled
        public String timezone { get; set; }
        @AuraEnabled
        public String market { get; set; }
        @AuraEnabled
        public Boolean isParagraph51 { get; set; }
        @AuraEnabled
        public Boolean isViewProductionChart { get; set; }
        @AuraEnabled
        public Boolean isMapOnHome { get; set; }
        @AuraEnabled
        public Boolean isWelcomeMessageOnHome { get; set; }
        @AuraEnabled
        public Boolean isSingleUnitsAffected { get; set; }
        @AuraEnabled
        public Boolean isViewEarningsDataChart { get; set; }
        @AuraEnabled
        public Boolean isPP1PP2 { get; set; }
        @AuraEnabled
        public Boolean isPortalCase { get; set; }
        @AuraEnabled
        public Boolean isFAQ { get; set; }
        @AuraEnabled
        public String defaultPlantPage { get; set; }
        @AuraEnabled
        public Boolean partialOutage { get; set; }
        @AuraEnabled
        public Boolean submeterView { get; set; }
        @AuraEnabled
        public Boolean submeterEditYearly { get; set; }
        @AuraEnabled
        public Boolean submeterEditMonthly { get; set; }
        @AuraEnabled
        public Boolean submeterEditYearlyEnabled { get; set; }
        @AuraEnabled
        public Boolean submeterEditMonthlyEnabled { get; set; }
        @AuraEnabled
        public Boolean submeterEditMonthlyIndividual { get; set; }
        @AuraEnabled
        public Boolean userManagement { get; set; }
        @AuraEnabled
        public Boolean cashflowCharts { get; set; }
        @AuraEnabled
        public String entityName { get; set; }
        @AuraEnabled
        public Boolean showReservePower { get; set; }
        @AuraEnabled
        public Boolean isCommercialRolesAdminEnabled { get; set; }
        @AuraEnabled
        public String marketCurrencyCode { get; set; }
        @AuraEnabled
        public Boolean showContractData { get; set; }

        public FeatureSetting() {
            isNewsfeed = false;
            isDowntime = false;
            isREMITTransparency = false;
            isDownregulationView = false;
            isDownregulationEdit = false;
            isFlexChart = false;
            isDownloads = false;
            isPayments = false;
            isSolarOnboarding = false;
            isEisman = false;
            isMasterData = false;
            isParagraph51 = false;
            isFileUpload = false;
            enablePricingFileUpload = false;
            isNotifications = false;
            isPlants = false;
            isViewProductionChart = false;
            isMapOnHome = false;
            isWelcomeMessageOnHome = false;
            isSingleUnitsAffected = false;
            isViewEarningsDataChart = false;
            isPP1PP2 = false;
            isPortalCase = false;
            isFAQ = false;
            partialOutage = false;
            submeterView = false;
            submeterEditYearly = false;
            submeterEditMonthly = false;
            submeterEditYearlyEnabled = false;
            submeterEditMonthlyEnabled = false;
            submeterEditMonthlyIndividual = false;
            userManagement = false;
            cashflowCharts = false;
            showReservePower = false;
            isCommercialRolesAdminEnabled = false;
            showContractData = false;
        }

        public FeatureSetting(msPortalMarketFeature__mdt setting) {
            isNewsfeed = setting.isNewsfeed__c;
            isDowntime = setting.isDowntime__c;
            isREMITTransparency = setting.isREMITTransparency__c;
            isDownregulationView = setting.isDownregulationView__c;
            isDownregulationEdit = setting.isDownregulationEdit__c;
            isFlexChart = setting.isUKFLexChart__c;
            isDownloads = setting.isDownloads__c;
            isPayments = setting.isPayments__c;
            isSolarOnboarding = setting.isSolarOnboarding__c;
            isEisman = setting.isEisman__c;
            isMasterData = setting.isMasterData__c;
            isParagraph51 = setting.isParagraph51__c;
            isFileUpload = setting.isFileUpload__c;
            isNotifications = setting.isNotifications__c;
            isPlants = setting.isPlants__c;
            timezone = setting.Timezone__c;
            market = setting.DeveloperName.remove('_Contract');
            isViewProductionChart = setting.isViewProductionChart__c;
            isMapOnHome = setting.isMapOnHome__c;
            isWelcomeMessageOnHome = setting.isWelcomeMessageOnHome__c;
            isSingleUnitsAffected = setting.isSingleUnitsAffected__c;
            isViewEarningsDataChart = setting.isViewEarningsDataChart__c;
            defaultPlantPage = setting.defaultPlantPage__c;
            isPP1PP2 = setting.isPP1PP2__c;
            isPortalCase = setting.isPortalCase__c;
            isFAQ = setting.isFAQ__c;
            partialOutage = setting.isPartialOutage__c;
            submeterView = setting.submeterView__c;
            submeterEditYearly = setting.submeterEditYearly__c;
            submeterEditMonthly = setting.submeterEditMonthly__c;
            submeterEditMonthlyIndividual = false;
            userManagement = setting.userManagement__c;
            cashflowCharts = setting.cashflowCharts__c;
            submeterEditYearlyEnabled = submeterSettingsMap.get('Annual Submeter - Allow Update') == true;
            submeterEditMonthlyEnabled = submeterSettingsMap.get('Monthly Submeter - Allow Update') == true;
            showReservePower = setting.showReservePower__c;
            isCommercialRolesAdminEnabled = setting.Enable_Commercial_Roles_Admin__c;
            marketCurrencyCode = setting.Market_Currency_Code__c;
            showContractData = setting.Manage_Contract_Data__c;
            enablePricingFileUpload = setting.Enable_Pricing_File_Upload__c;
        }

        public FeatureSetting(FeatureSetting setting1, FeatureSetting setting2) {
            isNewsfeed = (setting1.isNewsfeed || setting2.isNewsfeed);
            isDowntime = (setting1.isDowntime || setting2.isDowntime);
            isREMITTransparency = (setting1.isREMITTransparency || setting2.isREMITTransparency);
            isDownregulationView = (setting1.isDownregulationView || setting2.isDownregulationView);
            isDownregulationEdit = (setting1.isDownregulationEdit || setting2.isDownregulationEdit);
            isFlexChart = (setting1.isFlexChart || setting2.isFlexChart);
            isDownloads = (setting1.isDownloads || setting2.isDownloads);
            isPayments = (setting1.isPayments || setting2.isPayments);
            isSolarOnboarding = (setting1.isSolarOnboarding || setting2.isSolarOnboarding);
            isEisman = (setting1.isEisman || setting2.isEisman);
            isMasterData = (setting1.isMasterData || setting2.isMasterData);
            isFileUpload = (setting1.isFileUpload || setting2.isFileUpload);
            enablePricingFileUpload = (setting1.enablePricingFileUpload || setting2.enablePricingFileUpload);
            isParagraph51 = (setting1.isParagraph51 || setting2.isParagraph51);
            isNotifications = (setting1.isNotifications || setting2.isNotifications);
            isPlants = (setting1.isPlants || setting2.isPlants);
            timezone = setting1.timezone;
            market = setting1.market;
            isViewProductionChart = (setting1.isViewProductionChart || setting2.isViewProductionChart);
            isMapOnHome = (setting1.isMapOnHome || setting2.isMapOnHome);
            isWelcomeMessageOnHome = (setting1.isWelcomeMessageOnHome && setting2.isWelcomeMessageOnHome);
            isSingleUnitsAffected = (setting1.isSingleUnitsAffected || setting2.isSingleUnitsAffected);
            isViewEarningsDataChart = (setting1.isViewEarningsDataChart || setting2.isViewEarningsDataChart);
            defaultPlantPage = setting1.defaultPlantPage;
            isPP1PP2 = (setting1.isPP1PP2 || setting2.isPP1PP2);
            isPortalCase = (setting1.isPortalCase || setting2.isPortalCase);
            isFAQ = (setting1.isFAQ || setting2.isFAQ);
            submeterView = (setting1.submeterView || setting2.submeterView);
            partialOutage = (setting1.partialOutage || setting2.partialOutage);
            submeterEditYearly = setting1.submeterEditYearly || setting2.submeterEditYearly;
            submeterEditMonthly = setting1.submeterEditMonthly || setting2.submeterEditMonthly;
            submeterEditMonthlyIndividual =
                setting1.submeterEditMonthlyIndividual || setting2.submeterEditMonthlyIndividual;
            userManagement = setting1.userManagement || setting2.userManagement;
            cashflowCharts = setting1.cashflowCharts || setting2.cashflowCharts;
            submeterEditYearlyEnabled = submeterSettingsMap.get('Annual Submeter - Allow Update') == true;
            submeterEditMonthlyEnabled = submeterSettingsMap.get('Monthly Submeter - Allow Update') == true;
            showReservePower = (setting1.showReservePower || setting2.showReservePower);
            isCommercialRolesAdminEnabled = (setting1.isCommercialRolesAdminEnabled ||
            setting2.isCommercialRolesAdminEnabled);
            marketCurrencyCode = setting1.marketCurrencyCode;
            showContractData = (setting1.showContractData || setting2.showContractData);
        }
    }

    public class UserDetails {
        @AuraEnabled
        public Contact contact { get; set; }
        @AuraEnabled
        public User user { get; set; }
        @AuraEnabled
        public Set<String> countries { get; set; }
        @AuraEnabled
        public Map<String, msUtility.FeatureSetting> plantFeatures { get; set; }
        @AuraEnabled
        public FeatureSetting userFeatures { get; set; }
        @AuraEnabled
        public List<Meter__c> plants { get; set; }
        @AuraEnabled
        public List<Contract__c> contracts { get; set; }
        @AuraEnabled
        public List<PortalNews__c> news { get; set; }
        @AuraEnabled
        public Boolean maintenance { get; set; }
        @AuraEnabled
        public Integer unreadMessages { get; set; }
        @AuraEnabled
        public List<MeterRegistration__c> meterRegistrations { get; set; }
        @AuraEnabled
        public Boolean haveSolarOnboardingWLParentContract { get; set; }
    }

    public enum PortalMarket {
        Germany,
        France,
        UK,
        Ireland,
        Flex,
        IrelandFlex,
        UKRetail
    }
    public class LabelValuePair implements Comparable {
        public LabelValuePair() {
        }

        public LabelValuePair(String lbl, String val) {
            label = lbl;
            value = val;
        }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }

        public Integer compareTo(Object compareTo) {
            LabelValuePair compareToAcc = (LabelValuePair) compareTo;

            Integer returnValue = 0;

            if (label > compareToAcc.label) {
                returnValue = 1;
            } else if (label < compareToAcc.label) {
                returnValue = -1;
            }

            return returnValue;
        }
    }
}
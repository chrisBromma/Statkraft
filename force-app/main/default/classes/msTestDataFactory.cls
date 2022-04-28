@IsTest
public class msTestDataFactory {
    //definitions
    public static final Id UK_RETAIL_CONTRACT_REC_TYPE_ID = Application.RecordTypes.byDeveloperName('Contract__c', 'UK_Retail_Portal_Contract').Id;
    public static final Id PPA_CONTRACT_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    public static final Id CONTRACT_PPA_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;

    public static final Id DE_ACC_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Account', 'Account').Id;
    public static final Id UK_ACC_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Account', 'UK_Market_Access_Account').Id;

    public static final Id CONTACT_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Contact', 'Contact').Id;
    public static final Id UK_CONTACT_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Contact', 'UK_PPA_Market_Access_Contact').Id;

    public static final Id GLOBAL_CUSTOMER_COMMUNITY_USER_PROFILE_ID = getUserProfileIdByProfileName('Global Customer Community User');

    public static final Id DE_EEG_PROFILE_ID = getUserProfileIdByProfileName('DE EEG');

    public static final Id FIXED_ENERGY_PRICING_COMPONENT_REC_TYPE_ID = Application.RecordTypes.byDeveloperName('Pricing_Component__c', 'Fixed_Energy_Price')
        .Id;
    public static final Id FLOATING_ENERGY_PRICING_COMPONENT_REC_TYPE_ID = Application.RecordTypes.byDeveloperName(
            'Pricing_Component__c',
            'Floating_Energy_Price'
        )
        .Id;

    public static final Id CONTRACT_ROLE_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Contract_Role__c', 'Contract_Role_Contact').Id;

    //legacy records:
    public static final Id UK_CUSTOMER_COMMUNITY_USER_PROFILE_ID = GLOBAL_CUSTOMER_COMMUNITY_USER_PROFILE_ID; //previously "UK Customer Community", but that Profile does not exist anymore
    public static final Id UK_SHORT_TERM_CONTRACT_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Contract__c', 'UK_Retail_Portal_Contract').Id;
    public static final Id UK_SHORT_SOLAR_ENTITY_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Entity__c', 'UK_Solar_Park').Id;
    public static final String UK_LEGACY_USERNAME = 'testuser_uk@legacyportal.com';

    public static final Date THIS_DAY = Date.today();

    public static void activateCustomPerm(Id userId, String permissionName) {
        PermissionSet ps = new PermissionSet(Name = 'CustomPermissionEnabled', Label = 'Custom Permisison Enabled');
        insert ps;

        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :permissionName LIMIT 1]
            .Id
        );

        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);

        insert new List<SObject>{ sea, psa };
    }

    @IsTest
    public static void createTestRecords() {
        createTestLegacyPortalContext();
    }

    @IsTest
    public static void createTestPortalContext() {
        fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();

        //accounts
        Account deAccount = new Account();
        deAccount.Name = 'Test Account DE';
        deAccount.Sandbox_Migration_Id__c = 'Test Account DE';
        deAccount.RecordTypeId = DE_ACC_RECORD_TYPE;
        deAccount.BillingCountry = 'Germany';
        deAccount.Customer_Type__c = 'not yet identified';
        deAccount.Customer_Segment_industry__c = 'Large industrials';
        uow.registerNew(deAccount);

        Account frAccount = new Account();
        frAccount.Name = 'Test Account FR';
        frAccount.RecordTypeId = DE_ACC_RECORD_TYPE;
        frAccount.BillingCountry = 'France';
        frAccount.Customer_Type__c = 'not yet identified';
        frAccount.Customer_Segment_industry__c = 'Large industrials';
        uow.registerNew(frAccount);

        Account ukAccount = new Account();
        ukAccount.Name = 'Test Account UK';
        ukAccount.BillingCountry = 'United Kingdom';
        ukAccount.Customer_Type__c = 'not yet identified';
        ukAccount.Customer_Segment_industry__c = 'Large industrials';
        ukAccount.Sandbox_Migration_Id__c = 'Test Account UK';
        ukAccount.RecordTypeId = UK_ACC_RECORD_TYPE;
        uow.registerNew(ukAccount);

        //contacts
        Contact deContact = new Contact();
        deContact.FirstName = 'Test';
        deContact.LastName = 'deContact';
        deContact.Email = 'decontact@mail.com.testdatafactory';
        deContact.RecordTypeId = CONTACT_RECORD_TYPE;
        deContact.MobilePhone = '+49123456789';
        uow.registerNew(deContact, Contact.AccountId, deAccount);

        Contact frContact = new Contact();
        frContact.FirstName = 'Test';
        frContact.LastName = 'frContact';
        frContact.Email = 'frcontact@mail.com.testdatafactory';
        frContact.RecordTypeId = CONTACT_RECORD_TYPE;
        frContact.MobilePhone = '+33123456789';
        uow.registerNew(frContact, Contact.AccountId, frAccount);

        Contact ukContact = new Contact();
        ukContact.FirstName = 'Test';
        ukContact.LastName = 'ukContact';
        ukContact.Email = 'ukcontact@mail.com.testdatafactory';
        ukContact.RecordTypeId = CONTACT_RECORD_TYPE;
        ukContact.MobilePhone = '+44123456789';
        uow.registerNew(ukContact, Contact.AccountId, ukAccount);

        //portal settings
        PortalSettings__c annualSubmeter = new PortalSettings__c(Name = 'Annual Submeter - Allow Update', Checkbox__c = true);
        uow.registerNew(annualSubmeter);
        PortalSettings__c submeter = new PortalSettings__c(Name = 'Monthly Submeter - Allow Update', Checkbox__c = true);
        uow.registerNew(submeter);

        //contracts
        Contract__c de_test_contract_1 = new Contract__c(
            RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
            Start_Date__c = THIS_DAY.addDays(-20),
            End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
            Contract_Type_New__c = 'Feed in Tariff PPA',
            Product_Type_New__c = 'Direct Marketing',
            Status__c = 'Active',
            Country__c = 'Germany',
            RED_Contract_ID__c = 'GermanTestContract1',
            Approved__c = true,
            Meter_Billing_Type__c = 'Sub-Meter Yearly',
            Name = 'DETestContract1',
            Settlement_SubModel__c = null
        );
        uow.registerNew(de_test_contract_1, Contract__c.Contract_Holder__c, deAccount);

        Contract__c fr_test_contract_1 = new Contract__c(
            RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
            Start_Date__c = THIS_DAY.addDays(-20),
            End_Date__c = THIS_DAY.addDays(2),
            Status__c = 'Active',
            Country__c = 'France',
            RED_Contract_ID__c = 'FranceTestContract1',
            Approved__c = true,
            Name = 'FRTestContract1',
            Settlement_SubModel__c = null
        );
        uow.registerNew(fr_test_contract_1, Contract__c.Contract_Holder__c, frAccount);

        Contract__c uk_test_contract_1 = new Contract__c(
            RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
            Start_Date__c = THIS_DAY.addDays(-20),
            End_Date__c = THIS_DAY.addDays(2),
            Status__c = 'Active',
            Country__c = 'United Kingdom',
            Contract_Type__c = 'Flex',
            Contract_Type_New__c = 'Merchant PPA',
            Product_Type_New__c = 'Flex Optimization GB',
            RED_Contract_ID__c = 'UKTestContract1',
            Approved__c = true,
            Inflation_Index__c = 'RPI',
            Name = 'UKTestContract1',
            Settlement_SubModel__c = null
        );
        uow.registerNew(uk_test_contract_1, Contract__c.Contract_Holder__c, ukAccount);

        //pricing components
        Pricing_Component__c germanPC = new Pricing_Component__c(
            Name = 'Floating Energy Price',
            RecordTypeId = FLOATING_ENERGY_PRICING_COMPONENT_REC_TYPE_ID,
            Start_Date__c = THIS_DAY.addDays(-20),
            End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
            Meter_Billing_Type__c = 'Sub-Meter Monthly'
        );
        uow.registerNew(germanPC, Pricing_Component__c.Contract__c, de_test_contract_1);

        //meters
        List<Meter__c> deMeterList = new List<Meter__c>();
        List<Meter__c> ukMeterList = new List<Meter__c>();
        List<Meter__c> frMeterList = new List<Meter__c>();

        for (Integer i = 0; i < 16; i++) {
            Meter__c newMeter = new Meter__c(
                Name = 'deMeter' + i,
                Status__c = 'Active',
                Country__c = 'Germany',
                Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                Alternative_Meter_ID__c = 'FRPORTALPLH'
            );
            deMeterList.add(newMeter);
            uow.registerNew(newMeter, Meter__c.Current_Contract__c, de_test_contract_1);
            uow.registerRelationship(newMeter, Meter__c.TSO__c, deAccount);
            uow.registerRelationship(newMeter, Meter__c.Asset_Owner_Account__c, deAccount);
        }

        for (Integer i = 0; i < 16; i++) {
            Meter__c newMeter = new Meter__c(
                Name = 'ukMeter' + i,
                Status__c = 'Active',
                Country__c = 'United Kingdom',
                Portfolio_ID__c = 'mt_uk_rockingham' + i,
                Alternative_Meter_ID__c = 'ABCDEFGHIJK'
            );
            ukMeterList.add(newMeter);
            uow.registerNew(newMeter, Meter__c.Current_Contract__c, uk_test_contract_1);
            uow.registerRelationship(newMeter, Meter__c.TSO__c, ukAccount);
            uow.registerRelationship(newMeter, Meter__c.Asset_Owner_Account__c, ukAccount);
        }

        for (Integer i = 10; i < 26; i++) {
            Meter__c newMeter = new Meter__c(
                Name = 'frMeter' + i,
                Status__c = 'Active',
                Country__c = 'France',
                Portfolio_ID__c = 'as_fr_nordex_liv_1_' + i,
                Alternative_Meter_ID__c = '123456789' + i
            );
            frMeterList.add(newMeter);
            uow.registerNew(newMeter, Meter__c.Current_Contract__c, fr_test_contract_1);
            uow.registerRelationship(newMeter, Meter__c.TSO__c, frAccount);
            uow.registerRelationship(newMeter, Meter__c.Asset_Owner_Account__c, frAccount);
        }

        //site roles
        for (Integer i = 0; i < deMeterList.size(); i++) {
            Site_Role__c deSiteRole = new Site_Role__c(Role__c = 'Customer Portal', Start_Date__c = THIS_DAY, End_Date__c = THIS_DAY);
            uow.registerNew(deSiteRole, Site_Role__c.Contact__c, deContact);
            uow.registerRelationship(deSiteRole, Site_Role__c.Meter__c, deMeterList[i]);
        }

        for (Integer i = 0; i < ukMeterList.size(); i++) {
            Site_Role__c ukSiteRole = new Site_Role__c(Role__c = 'Customer Portal', Start_Date__c = THIS_DAY, End_Date__c = THIS_DAY);
            uow.registerNew(ukSiteRole, Site_Role__c.Contact__c, ukContact);
            uow.registerRelationship(ukSiteRole, Site_Role__c.Meter__c, ukMeterList[i]);
        }

        for (Integer i = 0; i < frMeterList.size(); i++) {
            Site_Role__c frSiteRole = new Site_Role__c(Role__c = 'Customer Portal', Start_Date__c = THIS_DAY, End_Date__c = THIS_DAY);
            uow.registerNew(frSiteRole, Site_Role__c.Contact__c, frContact);
            uow.registerRelationship(frSiteRole, Site_Role__c.Meter__c, frMeterList[i]);
        }

        //generation units
        List<Generation_Unit__c> deGenerationUnits = new List<Generation_Unit__c>();
        List<Generation_Unit__c> frGenerationUnits = new List<Generation_Unit__c>();
        List<Generation_Unit__c> ukGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < 32; i++) {
            Generation_Unit__c deGUnit = new Generation_Unit__c(
                Name = 'DE Generation Unit' + i,
                Annual_Production__c = 320,
                Portfolio_ID__c = 'DE_test' + i,
                Country__c = 'Germany'
            );
            deGenerationUnits.add(deGUnit);
            uow.registerNew(deGUnit);
            Generation_Unit__c frGUnit = new Generation_Unit__c(
                Name = 'FR Generation Unit' + i,
                Annual_Production__c = 320,
                Portfolio_ID__c = 'FR_test' + i,
                Country__c = 'France'
            );
            frGenerationUnits.add(frGUnit);
            uow.registerNew(frGUnit);
            Generation_Unit__c ukGUnit = new Generation_Unit__c(
                Name = 'UK Generation Unit' + i,
                Annual_Production__c = 320,
                Portfolio_ID__c = 'UK_test' + i,
                Country__c = 'United Kingdom'
            );
            ukGenerationUnits.add(ukGUnit);
            uow.registerNew(ukGUnit);
        }

        //generation types
        for (Integer i = 0; i < 32; i++) {
            Generator_Type__c gType = new Generator_Type__c(Name = 'Generation Type' + i, Annual_Reference_Production__c = 200, Capacity__c = 500);
            uow.registerNew(gType);
        }

        //meter to generation unit relationship
        for (Integer i = 0; i < 16; i++) {
            Meter2GenerationUnitRelationship__c m2gDE = new Meter2GenerationUnitRelationship__c(
                Name = 'DE Meter 2 Generation Unit Relationship' + i,
                Valid_from__c = THIS_DAY,
                Valid_to__c = THIS_DAY+2,
                Active__c = true
            );
            uow.registerNew(m2gDE, Meter2GenerationUnitRelationship__c.Meter__c, deMeterList[i]);
            uow.registerRelationship(m2gDE, Meter2GenerationUnitRelationship__c.Generator_Unit__c, deGenerationUnits[i]);
            Meter2GenerationUnitRelationship__c m2gFR = new Meter2GenerationUnitRelationship__c(
                Name = 'FR Meter 2 Generation Unit Relationship' + i,
                Valid_from__c = THIS_DAY,
                Valid_to__c = THIS_DAY+2,
                Active__c = true
            );
            uow.registerNew(m2gFR, Meter2GenerationUnitRelationship__c.Meter__c, frMeterList[i]);
            uow.registerRelationship(m2gFR, Meter2GenerationUnitRelationship__c.Generator_Unit__c, frGenerationUnits[i]);
            Meter2GenerationUnitRelationship__c m2gUK = new Meter2GenerationUnitRelationship__c(
                Name = 'UK Meter 2 Generation Unit Relationship' + i,
                Valid_from__c = THIS_DAY,
                Valid_to__c = THIS_DAY+2,
                Active__c = true
            );
            uow.registerNew(m2gUK, Meter2GenerationUnitRelationship__c.Meter__c, ukMeterList[i]);
            uow.registerRelationship(m2gUK, Meter2GenerationUnitRelationship__c.Generator_Unit__c, ukGenerationUnits[i]);
        }

        //MeterRegistration__c
        for (Integer i = 0; i < 16; i++) {
            MeterRegistration__c meterRegDE = new MeterRegistration__c(
                Name = 'DEMeterRegistration' + i,
                Valid_from__c = THIS_DAY.addDays(-20),
                Valid_to__c = THIS_DAY.addDays(2),
                Active__c = true
            );
            uow.registerNew(meterRegDE, MeterRegistration__c.Meter__c, deMeterList[i]);
            uow.registerRelationship(meterRegDE, MeterRegistration__c.Contract__c, de_test_contract_1);

            MeterRegistration__c meterRegFR = new MeterRegistration__c(
                Name = 'FRMeterRegistration' + i,
                Meter__c = frMeterList[i].Id,
                Contract__c = fr_test_contract_1.Id,
                Valid_from__c = THIS_DAY.addDays(-20),
                Valid_to__c = THIS_DAY.addDays(2),
                Active__c = true
            );
            uow.registerNew(meterRegFR, MeterRegistration__c.Meter__c, frMeterList[i]);
            uow.registerRelationship(meterRegFR, MeterRegistration__c.Contract__c, fr_test_contract_1);

            MeterRegistration__c meterRegUK = new MeterRegistration__c(
                Name = 'UKMeterRegistration' + i,
                Valid_from__c = THIS_DAY.addDays(-20),
                Valid_to__c = THIS_DAY.addDays(2),
                Active__c = true
            );
            uow.registerNew(meterRegUK, MeterRegistration__c.Meter__c, ukMeterList[i]);
            uow.registerRelationship(meterRegUK, MeterRegistration__c.Contract__c, uk_test_contract_1);
        }

        //contract roles
        Contract_Role__c contractRole1 = new Contract_Role__c(
            RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
            Role__c = 'Customer Portal',
            Start_Date__c = THIS_DAY.addDays(-7),
            End_Date__c = THIS_DAY.addDays(1)
        );
        uow.registerNew(contractRole1, Contract_Role__c.Contract__c, de_test_contract_1);
        uow.registerRelationship(contractRole1, Contract_Role__c.Contact__c, deContact);
        Contract_Role__c contractRole2 = new Contract_Role__c(
            RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
            Role__c = 'Contractual contact',
            Start_Date__c = THIS_DAY.addDays(-7),
            End_Date__c = THIS_DAY.addDays(1)
        );
        uow.registerNew(contractRole2, Contract_Role__c.Contract__c, de_test_contract_1);
        uow.registerRelationship(contractRole2, Contract_Role__c.Contact__c, deContact);
        Contract_Role__c contractRole3 = new Contract_Role__c(
            RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
            Role__c = 'Customer Portal',
            Start_Date__c = THIS_DAY.addDays(-7),
            End_Date__c = THIS_DAY.addDays(1)
        );
        uow.registerNew(contractRole3, Contract_Role__c.Contract__c, fr_test_contract_1);
        uow.registerRelationship(contractRole3, Contract_Role__c.Contact__c, frContact);
        Contract_Role__c contractRole4 = new Contract_Role__c(
            RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
            Role__c = 'Customer Portal',
            Start_Date__c = THIS_DAY.addDays(-7),
            End_Date__c = THIS_DAY.addDays(1)
        );
        uow.registerNew(contractRole4, Contract_Role__c.Contract__c, uk_test_contract_1);
        uow.registerRelationship(contractRole4, Contract_Role__c.Contact__c, ukContact);
        Contract_Role__c contractRole5 = new Contract_Role__c(
            RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
            Role__c = 'Customer Portal',
            Start_Date__c = THIS_DAY.addDays(-7),
            End_Date__c = THIS_DAY.addDays(1)
        );
        uow.registerNew(contractRole5, Contract_Role__c.Contract__c, uk_test_contract_1);
        uow.registerRelationship(contractRole5, Contract_Role__c.Contact__c, ukContact);
        Contract_Role__c contractRole6 = new Contract_Role__c(
            RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
            Role__c = 'Customer Portal',
            Start_Date__c = THIS_DAY.addDays(-7),
            End_Date__c = THIS_DAY.addDays(1)
        );
        uow.registerNew(contractRole6, Contract_Role__c.Contract__c, uk_test_contract_1);
        uow.registerRelationship(contractRole6, Contract_Role__c.Contact__c, ukContact);

        //users
        User testUserDE = new User();
        testUserDE.ProfileId = GLOBAL_CUSTOMER_COMMUNITY_USER_PROFILE_ID;
        testUserDE.Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal';
        testUserDE.Email = 'testuser@mindsquare.de';
        testUserDE.EmailEncodingKey = 'ISO-8859-1';
        testUserDE.LocaleSidKey = 'de_DE_EURO';
        testUserDE.LanguageLocaleKey = 'en_US';
        testUserDE.TimeZoneSidKey = 'Europe/Berlin';
        testUserDE.Alias = 'tstDEusr';
        testUserDE.LastName = 'DEuser';
        testUserDE.MobilePhone = '+49123456789';
        testUserDE.IsActive = true;
        uow.registerNew(testUserDE, User.ContactId, deContact);

        User testUserFR = new User();
        testUserFR.ProfileId = GLOBAL_CUSTOMER_COMMUNITY_USER_PROFILE_ID;
        testUserFR.Username = 'FRtestuser@statkraft.mindsquare.apex.testuser.statkraftportal';
        testUserFR.Email = 'testuser@mindsquare.fr';
        testUserFR.EmailEncodingKey = 'ISO-8859-1';
        testUserFR.LocaleSidKey = 'fr_FR_EURO';
        testUserFR.LanguageLocaleKey = 'fr';
        testUserFR.TimeZoneSidKey = 'Europe/Berlin';
        testUserFR.Alias = 'tstFRusr';
        testUserFR.LastName = 'FRuser';
        testUserFR.MobilePhone = '+33123456789';
        testUserFR.IsActive = true;
        uow.registerNew(testUserFR, User.ContactId, frContact);

        User testUserUK = new User();
        testUserUK.ProfileId = GLOBAL_CUSTOMER_COMMUNITY_USER_PROFILE_ID;
        testUserUK.Username = 'UKtestuser@statkraft.mindsquare.apex.testuser.statkraftportal';
        testUserUK.Email = 'testuser@mindsquare.co.uk';
        testUserUK.EmailEncodingKey = 'ISO-8859-1';
        testUserUK.LocaleSidKey = 'en_GB';
        testUserUK.LanguageLocaleKey = 'en_US';
        testUserUK.TimeZoneSidKey = 'Europe/Berlin';
        testUserUK.Alias = 'tstUKusr';
        testUserUK.LastName = 'UKuser';
        testUserUK.MobilePhone = '+44123456789';
        testUserUK.IsActive = true;
        uow.registerNew(testUserUK, User.ContactId, ukContact);

        User testUserDE_Office = new User();
        testUserDE_Office.ProfileId = DE_EEG_PROFILE_ID;
        testUserDE_Office.Username = 'DEtestuserOffice@statkraft.mindsquare.apex.testuser';
        testUserDE_Office.Email = 'testuser@mindsquare.de';
        testUserDE_Office.EmailEncodingKey = 'ISO-8859-1';
        testUserDE_Office.LocaleSidKey = 'de_DE_EURO';
        testUserDE_Office.LanguageLocaleKey = 'en_US';
        testUserDE_Office.TimeZoneSidKey = 'Europe/Berlin';
        testUserDE_Office.Alias = 'tstDEOff';
        testUserDE_Office.LastName = 'DEuserOffice';
        testUserDE_Office.MobilePhone = '+49123456789';
        testUserDE_Office.IsActive = true;
        uow.registerNew(testUserDE_Office);

        //misc
        Id networkId = [SELECT Id FROM Network WHERE Name = 'Customer Portal' LIMIT 1].Id;
        ConnectApi.FeedElementPage page = new ConnectApi.FeedElementPage();
        ConnectApi.GenericFeedElement element = new ConnectApi.GenericFeedElement();
        element.createdDate = Datetime.newInstance(2020, 12, 31);
        element.body = new ConnectApi.FeedBody();
        element.capabilities = new ConnectApi.FeedElementCapabilities();
        element.capabilities.readBy = new ConnectApi.ReadByCapability();
        page.elements = new List<ConnectApi.FeedElement>();
        page.elements.add(element);

        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFilterFeed(networkId, 'me', '005', null, 100, null, page);

        uow.commitWork();
    }

    @IsTest
    public static void createTestLegacyPortalContext() {
        fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();

        Account ukAccount = new Account();
        ukAccount.Name = 'Test Account UK';
        ukAccount.RecordTypeId = UK_ACC_RECORD_TYPE;
        ukAccount.BillingCountry = 'United Kingdom';
        ukAccount.Customer_Type__c = 'not yet identified';
        ukAccount.Customer_Segment_industry__c = 'Large industrials';
        uow.registerNew(ukAccount);

        Contact ukContact = new Contact();
        ukContact.FirstName = 'Test';
        ukContact.LastName = 'ukContact';
        ukContact.Email = 'ukcontact@mail.com.testdatafactory';
        ukContact.RecordTypeId = CONTACT_RECORD_TYPE;
        ukContact.MobilePhone = '+44123456789';
        uow.registerNew(ukContact, Contact.AccountId, ukAccount);

        //contracts
        Contract__c uk_test_contract = new Contract__c(
            RecordTypeId = UK_SHORT_TERM_CONTRACT_RECORD_TYPE,
            Start_Date__c = THIS_DAY.addDays(-20),
            End_Date__c = THIS_DAY.addDays(2),
            Status__c = 'Active',
            Country__c = 'United Kingdom',
            RED_Contract_ID__c = 'UKTestContract3',
            Approved__c = true,
            Name = 'UKTestContract3'
        );
        uow.registerNew(uk_test_contract, Contract__c.Contract_Holder__c, ukAccount);

        PicklistEntry uk;
        for (PicklistEntry c : Entity__c.Country__c.getDescribe().getPicklistValues()) {
            if (c.label == 'United Kingdom') {
                uk = c;
            }
        }

        //entity
        for (Integer i = 0; i < 16; i++) {
            Entity__c entity = new Entity__c(
                Name = 'ukEntity' + i,
                Status__c = 'Active',
                Country__c = uk.getValue(),
                RecordTypeId = UK_SHORT_SOLAR_ENTITY_RECORD_TYPE,
                Portfolio_ID__c = 'as_uk_entity_' + i,
                Installed_Capacity__c = 5.9
            );
            uow.registerNew(entity);
        }

        User testUserUK = new User();
        testUserUK.ProfileId = UK_CUSTOMER_COMMUNITY_USER_PROFILE_ID;
        testUserUK.Username = UK_LEGACY_USERNAME;
        testUserUK.Email = 'testuser@mindsquare.co.uk';
        testUserUK.EmailEncodingKey = 'ISO-8859-1';
        testUserUK.LocaleSidKey = 'en_GB';
        testUserUK.LanguageLocaleKey = 'en_US';
        testUserUK.TimeZoneSidKey = 'Europe/Berlin';
        testUserUK.Alias = 'tstUKusr';
        testUserUK.LastName = 'UKuser';
        testUserUK.MobilePhone = '+44123456789';
        testUserUK.IsActive = true;
        uow.registerNew(testUserUK, User.ContactId, ukContact);

        uow.commitWork();
    }

    private static Id getUserProfileIdByProfileName(String profileName) {
        return [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id;
    }
}
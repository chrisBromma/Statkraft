@isTest
public class msGranularTestDataFactory {
    public static final Id CONTACT_RECORD_TYPE = msTestDataFactory.CONTACT_RECORD_TYPE;
    public static final Id CONTRACT_ROLE_RECORD_TYPE = msTestDataFactory.CONTRACT_ROLE_RECORD_TYPE;

    public static final Date THIS_DAY = Date.today();

    public static List<EmailTemplate> createTestEmailTemplates(Integer numberOfTemplates) {
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
        for (Integer i = 0; i < numberOfTemplates; i++) {
            EmailTemplate returnTemplate = new EmailTemplate();
            EmailTemplate validEmailTemplate;
            System.runAs(new User(Id = UserInfo.getUserId())) {
                validEmailTemplate = new EmailTemplate();
                validEmailTemplate.Name = 'test' + i;
                validEmailTemplate.DeveloperName = 'testdev' + i;
                validEmailTemplate.TemplateType = 'text';
                validEmailTemplate.FolderId = UserInfo.getUserId();

                returnTemplate = validEmailTemplate;
            }
            emailTemplates.add(returnTemplate);
        }
        return emailTemplates;
    }

    public static List<Account> createTestAccounts(Integer numberOfAccounts, String billingCountry, Id recordType) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < numberOfAccounts; i++) {
            Account testAccount = new Account(
                Name = 'Test Account ' + i,
                Sandbox_Migration_Id__c = 'Test Account ' + i,
                RecordTypeId = recordType,
                BillingCountry = billingCountry,
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                Tax_Or_VAT__c = true,
                Company_Registration__c = false
            );
            accounts.add(testAccount);
        }
        return accounts;
    }

    public static List<Contact> createTestContacts(Integer numberOfContacts) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numberOfContacts; i++) {
            Contact testContact = new Contact();
            testContact.FirstName = 'Test FirstName ' + i;
            testContact.LastName = 'Test LastName ' + i;
            testContact.Email = 'TestMail' + i + '@mail.com.testdatafactory';
            testContact.RecordTypeId = CONTACT_RECORD_TYPE;
            testContact.MobilePhone = '+4912345678' + i;
            contacts.add(testCOntact);
        }
        return contacts;
    }

    public static List<Contact> linkContactsToAccounts(Id accountId, List<Contact> contactsToLink) {
        List<Contact> linkedContacts = new List<Contact>();
        for (Contact contact : contactsToLink) {
            contact.AccountId = accountId;
            linkedContacts.add(contact);
        }
        return linkedContacts;
    }

    public static List<PortalSettings__c> createTestPortalSettings(
        Integer numberOfSettings,
        String name,
        Boolean checkbox
    ) {
        List<PortalSettings__c> portalSettings = new List<PortalSettings__c>();
        for (Integer i = 0; i < numberOfSettings; i++) {
            PortalSettings__c testSetting = new PortalSettings__c(Name = name, Checkbox__c = checkbox);
            portalSettings.add(testSetting);
        }
        return portalSettings;
    }

    public static List<Contract__c> createTestContracts(
        Integer numberOfContracts,
        Id recordType,
        String country,
        String type,
        String newType,
        String productNewType,
        String redContract,
        String inflationIndex
    ) {
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 0; i < numberOfContracts; i++) {
            Contract__c testContract = new Contract__c(
                RecordTypeId = recordType,
                Start_Date__c = THIS_DAY.addDays(-20),
                End_Date__c = THIS_DAY.addDays(2),
                Status__c = 'Active',
                Country__c = country,
                Contract_Type__c = type,
                Contract_Type_New__c = newType,
                Product_Type_New__c = productNewType,
                RED_Contract_ID__c = redContract,
                Approved__c = true,
                Inflation_Index__c = inflationIndex,
                Name = 'Test Contract ' + i,
                Settlement_SubModel__c = null
            );
            contracts.add(testContract);
        }
        return contracts;
    }

    public static List<Contract__c> linkContractsToAccount(Id accountId, List<Contract__c> contractsToLink) {
        List<Contract__c> linkedContracts = new List<Contract__c>();
        for (Contract__c contract : contractsToLink) {
            contract.Contract_Holder__c = accountId;
            linkedContracts.add(contract);
        }
        return linkedContracts;
    }

    public static List<Pricing_Component__c> createTestPricingComponents(
        Integer numberofComponents,
        String componentName,
        Id recordType,
        String billingType
    ) {
        List<Pricing_Component__c> components = new List<Pricing_Component__c>();
        for (Integer i = 0; i < numberofComponents; i++) {
            Pricing_Component__c germanPC = new Pricing_Component__c(
                Name = componentName,
                RecordTypeId = recordType,
                Start_Date__c = THIS_DAY.addDays(-15),
                End_Date__c = THIS_DAY.addDays(1),
                Meter_Billing_Type__c = billingType
            );
            components.add(germanPC);
        }
        return components;
    }

    public static List<Pricing_Component__c> linkPricingComponentsToContract(
        Id contractId,
        List<Pricing_Component__c> componentsToLink
    ) {
        List<Pricing_Component__c> linkedComponents = new List<Pricing_Component__c>();
        for (Pricing_Component__c component : componentsToLink) {
            component.Contract__c = contractId;
            linkedComponents.add(component);
        }
        return linkedComponents;
    }

    public static List<Meter__c> createTestMeters(Integer numberOfMeters, String meterCountry) {
        List<Meter__c> meters = new List<Meter__c>();
        String portfolioID = '';
        switch on meterCountry {
            when 'Germany' {
                portfolioID = 'mt_de_an_11210_windpark_hohenseefeld';
            }
            when 'United Kingdom' {
                portfolioID = 'mt_uk_rockingham';
            }
            when else {
                portfolioID = 'as_fr_nordex_liv_1_';
            }
        }
        for (Integer i = 0; i < numberOfMeters; i++) {
            Meter__c testMeter = new Meter__c(
                Name = 'testMeter' + i,
                Status__c = 'Active',
                Country__c = meterCountry,
                Portfolio_ID__c = portfolioID + i,
                Alternative_Meter_ID__c = 'FRPORTALPLH'
            );
            meters.add(testMeter);
        }
        return meters;
    }

    public static List<Meter__c> linkMeters(Id contractId, Id accountId, List<Meter__c> metersToLink) {
        List<Meter__c> linkedMeters = new List<Meter__c>();
        for (Meter__c meter : metersToLink) {
            meter.Current_Contract__c = contractId;
            meter.TSO__c = accountId;
            meter.Asset_Owner_Account__c = accountId;
            linkedMeters.add(meter);
        }
        return linkedMeters;
    }

    public static List<Site_Role__c> createTestSiteRole(List<Meter__c> linkedMeters) {
        List<Site_Role__c> siteRoles = new List<Site_Role__c>();
        for (Integer i = 0; i < linkedMeters.size(); i++) {
            Site_Role__c testSiteRole = new Site_Role__c(
                Role__c = 'Customer Portal',
                Start_Date__c = THIS_DAY,
                End_Date__c = THIS_DAY,
                Meter__c = linkedMeters[i].Id
            );
            siteRoles.add(testSiteRole);
        }
        return siteRoles;
    }

    public static List<Site_Role__c> linkSiteRolesToContact(Id contactId, List<Site_Role__c> siteRolesToLink) {
        List<Site_Role__c> linkedSiteRoles = new List<Site_Role__c>();
        for (Site_Role__c siteRole : siteRolesToLink) {
            siteRole.Contact__c = contactId;
            linkedSiteRoles.add(siteRole);
        }
        return linkedSiteRoles;
    }

    public static List<Generation_Unit__c> createTestGenerationUnits(Integer numberOfUnits, String country) {
        List<Generation_Unit__c> generationUnits = new List<Generation_Unit__c>();
        String key = '';
        switch on country {
            when 'Germany' {
                key = 'DE';
            }
            when 'United Kingdom' {
                key = 'UK';
            }
            when else {
                key = 'FR';
            }
        }
        for (Integer i = 0; i < numberOfUnits; i++) {
            Generation_Unit__c testUnit = new Generation_Unit__c(
                Name = key + ' Generation Unit' + i,
                Annual_Production__c = 320,
                Portfolio_ID__c = key + '_test' + i,
                Country__c = country
            );
            generationUnits.add(testUnit);
        }
        return generationUnits;
    }

    public static List<Generator_Type__c> createTestGeneratorTypes(Integer numberOfTypes) {
        List<Generator_Type__c> generatorTypes = new List<Generator_Type__c>();
        for (Integer i = 0; i < numberOfTypes; i++) {
            Generator_Type__c testType = new Generator_Type__c(
                Name = 'Generator Type' + i,
                Annual_Reference_Production__c = 200,
                Capacity__c = 500
            );
            generatorTypes.add(testType);
        }
        return generatorTypes;
    }

    public static List<Case> createTestCases(Integer numberOfCases, Id caseRecordTypeId) {
        List<Case> caseList = new List<Case>();

        for (Integer i = 0; i < numberOfCases; i++) {
            Case testCase = new Case(Subject = 'Case' + i, RecordTypeId = caseRecordTypeId, Status = 'New');
            caseList.add(testCase);
        }

        return caseList;
    }

    public static List<Meter2GenerationUnitRelationship__c> createTestMeter2GURelationships(
        List<Meter__c> meters,
        List<Generation_Unit__c> generationUnits
    ) {
        List<Meter2GenerationUnitRelationship__c> relationships = new List<Meter2GenerationUnitRelationship__c>();
        for (Integer i = 0; i < meters.size(); i++) {
            Meter2GenerationUnitRelationship__c testRelationship = new Meter2GenerationUnitRelationship__c(
                Name = 'Meter 2 Generation Unit Relationship' + i,
                Valid_from__c = THIS_DAY,
                Valid_to__c = THIS_DAY+30,
                Active__c = true,
                Meter__c = meters[i].Id,
                Generator_Unit__c = generationUnits[i].Id
            );
            relationships.add(testRelationship);
        }
        return relationships;
    }

    public static List<Meter2GenerationUnitRelationship__c> createTestMeter2GURelationships(
        Meter__c meter,
        List<Generation_Unit__c> generationUnits
    ) {
        List<Meter2GenerationUnitRelationship__c> relationships = new List<Meter2GenerationUnitRelationship__c>();
        for (Generation_Unit__c gu : generationUnits) {
            Meter2GenerationUnitRelationship__c testRelationship = new Meter2GenerationUnitRelationship__c(
                Name = meter.name + gu.name,
                Valid_from__c = THIS_DAY,
                Valid_to__c = THIS_DAY+30,
                Active__c = true,
                Meter__c = meter.Id,
                Generator_Unit__c = gu.Id
            );
            relationships.add(testRelationship);
        }
        return relationships;
    }

    public static List<MeterRegistration__c> createTestMeterRegistrations(List<Meter__c> meters) {
        List<MeterRegistration__c> meterRegistrations = new List<MeterRegistration__c>();
        for (Integer i = 0; i < meters.size(); i++) {
            MeterRegistration__c testMeterRegistration = new MeterRegistration__c(
                Name = 'MeterRegistration' + i,
                Valid_from__c = THIS_DAY.addDays(-20),
                Valid_to__c = THIS_DAY.addDays(2),
                Active__c = true,
                Meter__c = meters[i].Id
            );
            meterRegistrations.add(testMeterRegistration);
        }
        return meterRegistrations;
    }

    public static List<MeterRegistration__c> linkMeterRegistrationsToContract(
        Id contractId,
        List<MeterRegistration__c> registrationsToLink
    ) {
        List<MeterRegistration__c> linkedRegistrations = new List<MeterRegistration__c>();
        for (MeterRegistration__c registration : registrationsToLink) {
            registration.Contract__c = contractId;
            linkedRegistrations.add(registration);
        }
        return linkedRegistrations;
    }

    public static List<Contract_Role__c> createTestContractRoles(Integer numberofRoles, String roleName) {
        List<Contract_Role__c> contractRoles = new List<Contract_Role__c>();
        for (Integer i = 0; i < numberofRoles; i++) {
            Contract_Role__c testContractRole = new Contract_Role__c(
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE,
                Role__c = roleName,
                Start_Date__c = THIS_DAY.addDays(-7),
                End_Date__c = THIS_DAY.addDays(1)
            );
            contractRoles.add(testContractRole);
        }
        return contractRoles;
    }

    public static List<Contract_Role__c> linkContractRoles(
        Id contractId,
        Id contactId,
        List<Contract_Role__c> rolesToLink
    ) {
        List<Contract_Role__c> linkedRoles = new List<Contract_Role__c>();
        for (Contract_Role__c contractRole : rolesToLink) {
            contractRole.Contract__c = contractId;
            contractRole.Contact__c = contactId;
            linkedRoles.add(contractRole);
        }
        return linkedRoles;
    }

    public static List<User> createTestUsers(
        Integer numberOfUsers,
        Id profileId,
        String localeSidKey,
        String languageLocaleKey
    ) {
        List<User> users = new List<User>();
        for (Integer i = 0; i < numberOfUsers; i++) {
            User testUser = new User(
                ProfileId = profileId,
                Username = 'testuser' + i + '@statkraft.mindsquare.apex.testuser.statkraftportal',
                Email = 'testuser' + i + '@mindsquare.de',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = localeSidKey,
                LanguageLocaleKey = languageLocaleKey,
                TimeZoneSidKey = 'Europe/Berlin',
                Alias = 'tstusr' + i,
                LastName = 'User' + i,
                MobilePhone = '+4912345678' + i,
                IsActive = true
            );
            users.add(testUser);
        }
        return users;
    }

    public static void createLoggerSetting() {
        LoggerSettings__c orgDef = new LoggerSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            DefaultLogShareAccessLevel__c = 'Read',
            DefaultNumberOfDaysToRetainLogs__c = 14,
            DefaultSaveMethod__c = 'EVENT_BUS',
            EnableSystemmessages__c = true,
            LoggingLevel__c = 'DEBUG',
            IsEnabled__c = true
        );
        insert orgDef;
    }
}
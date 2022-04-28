@IsTest
public without sharing class msBrytTestDataFactory {

    // BrytContractId = ContractRecId
    //ContactRecordTypeId = ContactRecId
    // AccountRecordTypeId = AccRecId

    public static void createTestRecords() {

        List<String> TEST_CONTRACT_ID = new List<String>{
                '12345', '67890'
        };
        String CSV_CONTENT = 'Contract Name,Bryt Contract ID,Tradable Quarters\r\ntestName,' + TEST_CONTRACT_ID[0] + ',4\r\ntestName2,' + TEST_CONTRACT_ID[1] + ',12';

        String CSV_CONTRACT_TO_TEST = 'Company,Allow Sell Back,Ask Premium,Bid Premium,Bryt Contract ID,Contract Name,Cost Per Trade,End Date,Expiry Days,Fixed Clip Percent,Start Date,Tradable Months,Tradable Quarters,Tradable Seasons,Tradable Years,Contract RecordType,Account RecordType\r\n' +
                'NANDOS LIMITED,TRUE,0,0,141053,NANDOS LIMITED,0,30/09/2021,3,,01/10/2018,2,1,4,0,Bryt Contract,Bryt Account';

        String CSV_NEW_CONTRACT_TO_TEST = 'Company,Allow Sell Back,Ask Premium,Bid Premium,Bryt Contract ID,Contract Name,Cost Per Trade,End Date,Expiry Days,Fixed Clip Percent,Start Date,Tradable Months,Tradable Quarters,Tradable Seasons,Tradable Years,Contract RecordType,Account RecordType\r\n' +
                'New Nanos 2.0,TRUE,0,0,1232131,New Nanos 2.0,0,30/09/2022,3,,01/10/2017,2,1,4,0,Bryt Contract,Bryt Account';

        String CSV_REFCAP_TO_TEST = 'Bryt Contract Id,Capacity Base,Capacity Peak,Month\r\n' +
                '141053,14,12,09/12/2021';
        String CSV_REFCAP_NON_EXISTING_TO_TEST = 'Bryt Contract Id,Capacity Base,Capacity Peak,Month\r\n' +
                '141050,14.8,12,09/12/2049';

        Date thisDay = Date.today();
        Id AccRecId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('msBrytAccount').getRecordTypeId();
        Id ContractRecId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
        Id ContactRecId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('msBrytContact').getRecordTypeId();
        Id ContractRoleRecId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
        Id PricingComponentRecId = Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Bryt_Pricing_Component').getRecordTypeId();

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        dml.duplicateRuleHeader.runAsCurrentUser = true;

        //Accounts
        // try catch for see all data usage
        Account testAccount = new Account();
        testAccount.Name = 'TestAccount';
        testAccount.RecordTypeId = AccRecId;
        testAccount.BillingCountry = 'United Kingdom';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        Database.SaveResult accSave = Database.insert(testAccount);

        //Contacts
        List<Contact> contactList = new List<Contact>();
        Contact testContact = new Contact();
        testContact.LastName = 'Tester';
        testContact.AccountId = accSave.id;
        testContact.OtherStreet = 'OSlane 123';
        testContact.OtherPostalCode = '1234';
        testContact.OtherCity = 'OCtown';
        testContact.OtherCountry = 'Denmark';
        testContact.MailingCountry = 'Denmark';
        testContact.Email = 'test@mail.com';
        testContact.RecordTypeId = ContactRecId;
        testContact.Bryt_isUser_Admin__c = true;
        contactList.add(testContact);
        //Database.SaveResult conSave = Database.insert(testContact);

        Contact testContact2 = new Contact();
        testContact2.FirstName = 'Test';
        testContact2.LastName = 'SecondTester';
        testContact2.AccountId = accSave.getId();
        testContact2.OtherStreet = 'Street 5';
        testContact2.OtherPostalCode = '4321';
        testContact2.OtherCity = 'BCtown';
        testContact2.OtherCountry = 'Germany';
        testContact2.MailingCountry = 'Germany';
        testContact2.Email = 'test2@mail.com';
        testContact2.RecordTypeId = ContactRecId;
        contactList.add(testContact2);

        Contact testContact3 = new Contact();
        testContact3.FirstName = 'Test';
        testContact3.LastName = 'ThirdTester';
        testContact3.AccountId = accSave.getId();
        testContact3.OtherStreet = 'OSlane 123';
        testContact3.OtherPostalCode = '1234';
        testContact3.OtherCity = 'OCtown';
        testContact3.OtherCountry = 'Denmark';
        testContact3.MailingCountry = 'Denmark';
        testContact3.Email = 'test3@mail.com';
        testContact3.RecordTypeId = ContactRecId;
        contactList.add(testContact3);

        Contact testContact4 = new Contact();
        testContact4.FirstName = 'Test';
        testContact4.LastName = 'FourthTester';
        testContact4.AccountId = accSave.getId();
        testContact4.OtherStreet = 'OSlane 123';
        testContact4.OtherPostalCode = '1234';
        testContact4.OtherCity = 'OCtown';
        testContact4.OtherCountry = 'Denmark';
        testContact4.MailingCountry = 'Denmark';
        testContact4.Email = 'test4@mail.com';
        testContact4.RecordTypeId = ContactRecId;
        contactList.add(testContact4);
        insert contactList;

        Contact testContact5 = new Contact();
        testContact5.LastName = 'FifthTester';
        testContact5.AccountId = accSave.getId();
        testContact5.OtherStreet = 'OSlane 123';
        testContact5.OtherPostalCode = '1234';
        testContact5.OtherCity = 'OCtown';
        testContact5.OtherCountry = 'Denmark';
        testContact5.MailingCountry = 'Denmark';
        testContact5.Email = 'test5@mail.com';
        testContact5.RecordTypeId = ContactRecId;
        Database.SaveResult con5Save = Database.insert(testContact5);

        Contact testContact6 = new Contact();
        testContact6.LastName = 'Admin Unit Tester';
        testContact6.AccountId = accSave.getId();
        testContact6.OtherStreet = 'Admin 123';
        testContact6.OtherPostalCode = '1234';
        testContact6.OtherCity = 'OCtown';
        testContact6.OtherCountry = 'Denmark';
        testContact6.MailingCountry = 'Denmark';
        testContact6.Email = 'test6@mail.com';
        testContact6.RecordTypeId = ContactRecId;
        Database.SaveResult con6Save = Database.insert(testContact6);

        //User
        List<Profile> profile = [SELECT Id FROM Profile WHERE Profile.Name = 'Bryt Customer Community User'];
        Id profileId = profile[0].Id;

        List<User> usersToInsert = new List<User>();

        User testUser = new User();
        testUser.Username = 'testuser@statkraft.mindsquare.user.dev';
        testUser.Email = 'testuser@mindsquare.de';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.LocaleSidKey = 'de_DE_EURO';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.TimeZoneSidKey = 'Europe/Berlin';
        testUser.Alias = 'testusr';
        testUser.FirstName = 'Testi';
        testUser.LastName = 'User';
        testUser.ContactId = testContact.Id;
        testUser.ProfileId = profileId;
        testUser.IsActive = true;
        usersToInsert.add(testUser);


        User testUser2 = new User();
        testUser2.ProfileId = profileId;
        testUser2.Username = 'testuser2@statkraft.mindsquare.user.dev';
        testUser2.Email = 'testuser2@mindsquare.de';
        testUser2.EmailEncodingKey = 'ISO-8859-1';
        testUser2.LocaleSidKey = 'de_DE_EURO';
        testUser2.LanguageLocaleKey = 'es';
        testUser2.TimeZoneSidKey = 'Europe/Berlin';
        testUser2.Alias = 'testus2';
        testUser2.FirstName = 'Testi';
        testUser2.LastName = 'User2';
        testUser2.ContactId = testContact2.Id;
        testUser2.IsActive = true;
        usersToInsert.add(testUser2);

        User testUserNoAdmin = new User();
        testUserNoAdmin.ProfileId = profileId;
        testUserNoAdmin.Username = 'brytNoAdminTestUser@statkraft.mindsquare.user.dev';
        testUserNoAdmin.Email = 'testuser3@mindsquare.de';
        testUserNoAdmin.EmailEncodingKey = 'ISO-8859-1';
        testUserNoAdmin.LocaleSidKey = 'de_DE_EURO';
        testUserNoAdmin.LanguageLocaleKey = 'es';
        testUserNoAdmin.TimeZoneSidKey = 'Europe/Berlin';
        testUserNoAdmin.Alias = 'testus3';
        testUserNoAdmin.FirstName = 'Testi';
        testUserNoAdmin.LastName = 'User3';
        testUserNoAdmin.ContactId = testContact3.Id;
        testUserNoAdmin.IsActive = true;
        usersToInsert.add(testUserNoAdmin);

        insert(usersToInsert);
        System.setPassword(testUser.Id, '1234abcd');


        //contracts
        List<Contract__c> contractList = new List<Contract__c>();  // Put all new contracts to this List

        Contract__c testContract = new Contract__c();
        testContract.RED_Contract_ID__c = 'TestContract1';
        testContract.Approved__c = true;
        testContract.Start_Date__c = thisDay.addMonths(-12).toStartOfMonth();
        testContract.End_Date__c = thisDay.addMonths(25).toStartOfMonth();
        testContract.Status__c = 'Draft';
        testContract.Contract_Holder__c = accSave.getId();
        testContract.RecordTypeId = ContractRecId;
        testContract.POD_ID__c = 'test';
        testContract.Name = 'test1_bryt';
        contractList.add(testContract);

        Contract__c testContract2 = new Contract__c();
        testContract2.RED_Contract_ID__c = 'TestContract2';
        testContract2.Approved__c = true;
        testContract2.Start_Date__c = thisDay.addMonths(-2).toStartOfMonth();
        testContract2.End_Date__c = thisDay.addMonths(5).toStartOfMonth();
        testContract2.Status__c = 'Draft';
        testContract2.Contract_Holder__c = accSave.getId();
        testContract2.RecordTypeId = ContractRecId;
        testContract2.POD_ID__c = 'test';
        testContract2.Name = 'test2_bryt';
        contractList.add(testContract2);

        Contract__c testContract3 = new Contract__c();
        testContract3.RED_Contract_ID__c = 'TestContract3';
        testContract3.Approved__c = true;
        testContract3.Start_Date__c = thisDay.addMonths(-2).toStartOfMonth();
        testContract3.End_Date__c = thisDay.addMonths(5).toStartOfMonth();
        testContract3.Status__c = 'Expired';
        testContract3.Contract_Holder__c = accSave.getId();
        testContract3.RecordTypeId = ContractRecId;
        testContract3.POD_ID__c = 'test';
        testContract3.Name = 'test3_bryt';
        contractList.add(testContract3);

        Contract__c testContract4 = new Contract__c();
        testContract4.RED_Contract_ID__c = 'TestContract4';
        testContract4.Approved__c = true;
        testContract4.Start_Date__c = thisDay.addMonths(-2).toStartOfMonth();
        testContract4.End_Date__c = thisDay.addMonths(5).toStartOfMonth();
        testContract4.Status__c = 'Draft';
        testContract4.Contract_Holder__c = accSave.getId();
        testContract4.RecordTypeId = ContractRecId;
        testContract4.POD_ID__c = 'test';
        testContract4.Name = 'test4_bryt';
        contractList.add(testContract4);

        Contract__c testContract5 = new Contract__c();
        testContract5.RED_Contract_ID__c = 'TestContract5';
        testContract5.Approved__c = true;
        testContract5.Start_Date__c = thisDay.addMonths(-2).toStartOfMonth();
        testContract5.End_Date__c = thisDay.addMonths(5).toStartOfMonth();
        testContract5.Status__c = 'Draft';
        testContract5.Contract_Holder__c = accSave.getId();
        testContract5.RecordTypeId = ContractRecId;
        testContract5.POD_ID__c = 'test';
        testContract5.Name = 'test5_bryt';
        contractList.add(testContract5);

        Contract__c testContract6 = new Contract__c();
        testContract6.RED_Contract_ID__c = 'TestContract6';
        testContract6.Approved__c = true;
        testContract6.Start_Date__c = thisDay.addMonths(-2).toStartOfMonth();
        testContract6.End_Date__c = thisDay.addMonths(5).toStartOfMonth();
        testContract6.Status__c = 'Draft';
        testContract6.Contract_Holder__c = accSave.getId();
        testContract6.Opportunity_Renegotiation__c = null;
        testContract6.BrytNotificationEmails__c = 'unit@test.com;asdasd;';
        testContract6.RecordTypeId = ContractRecId;
        testContract6.POD_ID__c = 'test';
        testContract6.Name = 'test6_bryt';
        contractList.add(testContract6);

        Contract__c testContract7 = new Contract__c();
        testContract7.RED_Contract_ID__c = 'TestContract7';
        testContract7.Approved__c = true;
        testContract7.Start_Date__c = thisDay.addMonths(-2).toStartOfMonth();
        testContract7.End_Date__c = thisDay.addMonths(5).toStartOfMonth();
        testContract7.Status__c = 'Draft';
        testContract7.Contract_Holder__c = accSave.getId();
        testContract7.Opportunity_Renegotiation__c = null;
        testContract7.BrytNotificationEmails__c = 'unit@test.com';
        testContract7.RecordTypeId = ContractRecId;
        testContract7.POD_ID__c = 'test';
        testContract7.Name = 'test7_bryt';
        contractList.add(testContract7);

        Contract__c c1 = new Contract__c();
        c1.Name = 'NANDO LIMITED';
        c1.Bryt_Contract_ID__c = '141053';
        c1.Start_Date__c = Date.today();
        c1.Contract_Holder__c = accSave.Id;
        c1.Approved__c = true;
        c1.Status__c = 'Active';
        c1.RecordTypeId = ContractRecId;
        contractList.add(c1);

        // Non existing Contract
        Contract__c c2 = new Contract__c();
        c2.Name = 'TestL2';
        c2.Bryt_Contract_ID__c = '123456';
        c2.Start_Date__c = Date.today();
        c2.Contract_Holder__c = accSave.Id;
        c2.Approved__c = true;
        c2.Status__c = 'Expired';
        c2.RecordTypeId = ContractRecId;
        contractList.add(c2);

        // Contract without "Reference Capacities"
        Contract__c c3 = new Contract__c();
        c3.Name = 'TestL3';
        c3.Bryt_Contract_ID__c = '141050';
        c3.Start_Date__c = Date.today();
        c3.Contract_Holder__c = accSave.Id;
        c3.Approved__c = true;
        c3.Status__c = 'Expired';
        c3.RecordTypeId = ContractRecId;
        contractList.add(c3);

        insert contractList; // Use only ONE DML statement in order not to run into governor-limits!

        // Contract Roles: Put new records into this list: DML-governor-Limits!
        List<Contract_Role__c> contrRoleList = new List<Contract_Role__c>();
        Contract_Role__c testContractRole = new Contract_Role__c();
        testContractRole.Role__c = 'Commercial contact';
        testContractRole.Start_Date__c = Date.today();
        testContractRole.End_Date__c = Date.today();
        testContractRole.Contact__c = testContact.Id;
        testContractRole.Contract__c = testContract5.Id;
        testContractRole.RecordTypeId = ContractRoleRecId;
        testContractRole.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole);

        Contract_Role__c testContractRole2 = new Contract_Role__c();
        testContractRole2.Role__c = 'Commercial contact';
        testContractRole2.Contact__c = testContact2.Id;
        testContractRole2.Contract__c = testContract6.Id;
        testContractRole2.RecordTypeId = ContractRoleRecId;
        testContractRole2.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole2);

        Contract_Role__c testContractRole3 = new Contract_Role__c();
        testContractRole3.Role__c = 'Portal contractual contact';
        testContractRole3.Start_Date__c = Date.today();
        testContractRole3.End_Date__c = Date.today();
        testContractRole3.Contact__c = testContact3.Id;
        testContractRole3.Contract__c = testContract5.Id;
        testContractRole3.RecordTypeId = ContractRoleRecId;
        testContractRole3.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole3);

        Contract_Role__c testContractRole4 = new Contract_Role__c();
        testContractRole4.Role__c = 'Portal contractual contact';
        testContractRole4.Contact__c = testContact4.Id;
        testContractRole4.Contract__c = testContract6.Id;
        testContractRole4.RecordTypeId = ContractRoleRecId;
        testContractRole4.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole4);

        Contract_Role__c testContractRole5 = new Contract_Role__c();
        testContractRole5.Role__c = 'Portal contractual contact';
        testContractRole5.Contact__c = con5Save.Id;
        testContractRole5.Contract__c = testContract6.Id;
        testContractRole5.RecordTypeId = ContractRoleRecId;
        testContractRole5.Bryt_isTPI__c = true;
        Database.SaveResult conRole5Save = Database.insert(testContractRole5);

        Contract_Role__c testContractRole6 = new Contract_Role__c();
        testContractRole6.Role__c = 'Commercial contact';
        testContractRole6.Start_Date__c = Date.today();
        testContractRole6.End_Date__c = Date.today();
        testContractRole6.Contact__c = testContact.Id;
        testContractRole6.Contract__c = testContract5.Id;
        testContractRole6.RecordTypeId = ContractRoleRecId;
        testContractRole6.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole6);

        Contract_Role__c testContractRole7 = new Contract_Role__c();
        testContractRole7.Role__c = 'Commercial contact';
        testContractRole7.Start_Date__c = Date.today();
        testContractRole7.End_Date__c = Date.today();
        testContractRole7.Contact__c = con6Save.Id;
        testContractRole7.Contract__c = testContract5.Id;
        testContractRole7.RecordTypeId = ContractRoleRecId;
        testContractRole7.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole7);

        Contract_Role__c testContractRole8 = new Contract_Role__c();
        testContractRole8.Role__c = 'Customer Portal';
        testContractRole8.Start_Date__c = Date.today();
        testContractRole8.End_Date__c = Date.today();
        testContractRole8.Contact__c = testContact.Id;
        testContractRole8.Contract__c = testContract.Id;
        testContractRole8.RecordTypeId = ContractRoleRecId;
        testContractRole8.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole8);

        Contract_Role__c testContractRole9 = new Contract_Role__c();
        testContractRole9.Role__c = 'Customer Portal';
        testContractRole9.Start_Date__c = Date.today();
        testContractRole9.End_Date__c = Date.today();
        testContractRole9.Contact__c = testContact.Id;
        testContractRole9.Contract__c = testContract6.id;
        testContractRole9.RecordTypeId = ContractRoleRecId;
        testContractRole9.Bryt_isTPI__c = true;
        contrRoleList.add(testContractRole9);
        insert contrRoleList;

        //Reference Capacities: Put new records into this list: DML-governor-Limits!
        List<Bryt_Reference_Capacity__c> refCapList = new List<Bryt_Reference_Capacity__c>();

        Bryt_Reference_Capacity__c testRefCap0 = new Bryt_Reference_Capacity__c();
        testRefCap0.Month__c = thisDay.addMonths(-1).toStartOfMonth();
        testRefCap0.Capacity_Off_Peak__c = 1000;
        testRefCap0.Contract__c = testContract6.Id;
        refCapList.add(testRefCap0);

        Bryt_Reference_Capacity__c testRefCap8 = new Bryt_Reference_Capacity__c();
        testRefCap8.Month__c = thisDay.toStartOfMonth();
        testRefCap8.Capacity_Off_Peak__c = 1000;
        testRefCap8.Contract__c = testContract6.Id;
        refCapList.add(testRefCap8);

        Bryt_Reference_Capacity__c testRefCap1 = new Bryt_Reference_Capacity__c();
        testRefCap1.Month__c = thisDay.addMonths(1).toStartOfMonth();
        testRefCap1.Capacity_Off_Peak__c = 1000;
        testRefCap1.Contract__c = testContract6.Id;
        refCapList.add(testRefCap1);

        Bryt_Reference_Capacity__c testRefCap4 = new Bryt_Reference_Capacity__c();
        testRefCap4.Month__c = thisDay.addMonths(2).toStartOfMonth();
        testRefCap4.Capacity_Off_Peak__c = 1000;
        testRefCap4.Contract__c = testContract6.Id;
        refCapList.add(testRefCap4);

        Bryt_Reference_Capacity__c testRefCap5 = new Bryt_Reference_Capacity__c();
        testRefCap5.Month__c = thisDay.addMonths(3).toStartOfMonth();
        testRefCap5.Capacity_Off_Peak__c = 1000;
        testRefCap5.Contract__c = testContract6.Id;
        refCapList.add(testRefCap5);

        Bryt_Reference_Capacity__c testRefCap9 = new Bryt_Reference_Capacity__c();
        testRefCap9.Month__c = thisDay.addMonths(4).toStartOfMonth();
        testRefCap9.Capacity_Off_Peak__c = 1000;
        testRefCap9.Contract__c = testContract6.Id;
        refCapList.add(testRefCap9);

        Bryt_Reference_Capacity__c testRefCap2 = new Bryt_Reference_Capacity__c();
        testRefCap2.Month__c = thisDay.addMonths(-1).toStartOfMonth();
        testRefCap2.Capacity_Off_Peak__c = 1000;
        testRefCap2.Contract__c = testContract5.Id;
        refCapList.add(testRefCap2);

        Bryt_Reference_Capacity__c testRefCap7 = new Bryt_Reference_Capacity__c();
        testRefCap7.Month__c = thisDay.toStartOfMonth();
        testRefCap7.Capacity_Off_Peak__c = 1000;
        testRefCap7.Contract__c = testContract5.Id;
        refCapList.add(testRefCap7);

        Bryt_Reference_Capacity__c testRefCap3 = new Bryt_Reference_Capacity__c();
        testRefCap3.Month__c = thisDay.addMonths(-1).toStartOfMonth();
        testRefCap3.Capacity_Off_Peak__c = 1000;
        testRefCap3.Contract__c = testContract7.Id;
        refCapList.add(testRefCap3);

        Bryt_Reference_Capacity__c testRefCap6 = new Bryt_Reference_Capacity__c();
        testRefCap6.Month__c = thisDay.toStartOfMonth();
        testRefCap6.Capacity_Off_Peak__c = 1000;
        testRefCap6.Contract__c = testContract7.Id;
        refCapList.add(testRefCap6);

        Bryt_Reference_Capacity__c r1 = new Bryt_Reference_Capacity__c();
        r1.Capacity_Off_Peak__c = 12;
        r1.Capacity_Peak__c = 14;
        r1.Contract__c = c1.Id;
        r1.Month__c = Date.newInstance(2021, 12, 09);
        refCapList.add(r1);

        // Ref Cap NOT-OK
        Bryt_Reference_Capacity__c r2 = new Bryt_Reference_Capacity__c();
        r2.Capacity_Off_Peak__c = 12;
        r2.Capacity_Peak__c = 14;
        r2.Contract__c = c2.Id;
        r2.Month__c = Date.today();
        refCapList.add(r2);
        insert refCapList;


        // Pricing Component
        List<Pricing_Component__c> pcList = new List<Pricing_Component__c>();
        Pricing_Component__c testPC1 = new Pricing_Component__c();
        testPC1.Start_Date__c = thisDay.addMonths(1).toStartOfMonth();
        testPC1.End_Date__c = thisDay.addMonths(4).toStartOfMonth().addDays(-1);
        testPC1.Name = 'Test Price Component Factory 1';
        testPC1.Fixed_Volume__c = 1;
        testPC1.Value__c = 1;
        testPC1.Index_Price__c = 'APX RPD';
        testPC1.Contract__c = testContract6.id;
        testPC1.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC1);

        Pricing_Component__c testPC2 = new Pricing_Component__c();
        testPC2.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC2.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC2.Name = 'Test Price Component Factory 2';
        testPC2.Fixed_Volume__c = 2;
        testPC2.Value__c = 2;
        testPC2.Index_Price__c = 'APX RPD';
        testPC2.Contract__c = testContract6.id;
        testPC2.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC2);

        Pricing_Component__c testPC3 = new Pricing_Component__c();
        testPC3.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC3.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC3.Name = 'Test Price Component Factory3';
        testPC3.Fixed_Volume__c = 3;
        testPC3.Value__c = 3;
        testPC3.Index_Price__c = 'APX RPD';
        testPC3.Contract__c = testContract6.id;
        testPC3.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC3);

        Pricing_Component__c testPC4 = new Pricing_Component__c();
        testPC4.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC4.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC4.Name = 'Test Price Component Factory4';
        testPC4.Fixed_Volume__c = 3;
        testPC4.Value__c = 3;
        testPC4.Index_Price__c = 'APX RPD';
        testPC4.Contract__c = testContract5.id;
        testPC4.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC4);

        Pricing_Component__c testPC5 = new Pricing_Component__c();
        testPC5.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC5.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC5.Name = 'Test Price Component Factory5';
        testPC5.Fixed_Volume__c = 3;
        testPC5.Value__c = 3;
        testPC5.Index_Price__c = 'APX RPD';
        testPC5.Contract__c = testContract7.id;
        testPC5.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC5);

        Pricing_Component__c testPC6 = new Pricing_Component__c();
        testPC6.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC6.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC6.Name = 'Test Price Component Factory6';
        testPC6.Fixed_Volume__c = 3;
        testPC6.Value__c = 3;
        testPC6.Index_Price__c = 'APX RPD';
        testPC6.Contract__c = testContract7.id;
        testPC6.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC6);

        Pricing_Component__c testPC7 = new Pricing_Component__c();
        testPC7.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC7.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC7.Name = 'Test Price Component Factory7';
        testPC7.Fixed_Volume__c = 3;
        testPC7.Value__c = 3;
        testPC7.Index_Price__c = 'APX RPD';
        testPC7.Contract__c = testContract7.id;
        testPC7.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC7);

        Pricing_Component__c testPC8 = new Pricing_Component__c();
        testPC8.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC8.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC8.Name = 'Test Price Component Factory8';
        testPC8.Fixed_Volume__c = 3;
        testPC8.Value__c = 3;
        testPC8.Index_Price__c = 'APX RPD';
        testPC8.Contract__c = testContract7.id;
        testPC8.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC8);

        Pricing_Component__c testPC9 = new Pricing_Component__c();
        testPC9.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC9.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC9.Name = 'Test Price Component Factory9';
        testPC9.Fixed_Volume__c = 3;
        testPC9.Value__c = 3;
        testPC9.Index_Price__c = 'APX RPD';
        testPC9.Contract__c = testContract7.id;
        testPC9.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC9);

        Pricing_Component__c testPC10 = new Pricing_Component__c();
        testPC10.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC10.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC10.Name = 'Test Price Component Factory10';
        testPC10.Fixed_Volume__c = 3;
        testPC10.Value__c = 3;
        testPC10.Index_Price__c = 'APX RPD';
        testPC10.Contract__c = testContract7.id;
        testPC10.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC10);

        Pricing_Component__c testPC11 = new Pricing_Component__c();
        testPC11.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC11.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC11.Name = 'Test Price Component Factory11';
        testPC11.Fixed_Volume__c = 3;
        testPC11.Value__c = 3;
        testPC11.Index_Price__c = 'APX RPD';
        testPC11.Contract__c = testContract7.id;
        testPC11.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC11);

        Pricing_Component__c testPC12 = new Pricing_Component__c();
        testPC12.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC12.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC12.Name = 'Test Price Component Factory12';
        testPC12.Fixed_Volume__c = 3;
        testPC12.Value__c = 3;
        testPC12.Index_Price__c = 'APX RPD';
        testPC12.Contract__c = testContract7.id;
        testPC12.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC12);

        Pricing_Component__c testPC13 = new Pricing_Component__c();
        testPC13.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC13.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC13.Name = 'Test Price Component Factory13';
        testPC13.Fixed_Volume__c = 3;
        testPC13.Value__c = 3;
        testPC13.Index_Price__c = 'APX RPD';
        testPC13.Contract__c = testContract7.id;
        testPC13.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC13);

        Pricing_Component__c testPC14 = new Pricing_Component__c();
        testPC14.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC14.End_Date__c = thisDay.toStartOfMonth().addDays(-1);
        testPC14.Name = 'Test Price Component Factory14';
        testPC14.Fixed_Volume__c = 3;
        testPC14.Value__c = 3;
        testPC14.Index_Price__c = 'APX RPD';
        testPC14.Contract__c = testContract7.id;
        testPC14.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC14);

        Pricing_Component__c testPC15 = new Pricing_Component__c();
        testPC15.Start_Date__c = thisDay.addMonths(-1).toStartOfMonth();
        testPC15.End_Date__c = thisDay.toStartOfMonth().addMonths(1).addDays(-1);
        testPC15.Name = 'Test Price Component Factory15';
        testPC15.Fixed_Volume__c = 3;
        testPC15.Value__c = 3;
        testPC15.Index_Price__c = 'APX RPD';
        testPC15.Contract__c = testContract7.id;
        testPC15.RecordTypeId = PricingComponentRecId;
        pcList.add(testPC15);
        insert(pcList);
        //Database.SaveResult testPCResult15 = Database.insert(testPC15);

        //Country Contact Details
        try {

            CountryContactDetails__c contactDetail = new CountryContactDetails__c();
            contactDetail.Name = 'John Doe';
            contactDetail.Country__c = 'United Kingdom';
            contactDetail.Address__c = 'Teststreet1';
            contactDetail.Phone__c = '012345678';
            Database.SaveResult conDetSave = Database.insert(contactDetail);
        } catch (Exception e) {
        }

        //Custom Setting Timeseries
        try {
            msTimeSeries__c timeSerie = new msTimeSeries__c();
            timeSerie.Name = 'as_de2';
            timeSerie.Resolution__c = 'PT15M';
            timeSerie.Timezone__c = 'Europe/Berlin';
            timeSerie.Unit__c = 'MW';
            timeSerie.Paths__c = '/forecast/power/ems/default,/metering/power/ems/default,/regulation/power/ems/default,/availability/power/portal/correction,/eisman/power/rotorsoft/default';
            timeSerie.PathsOverview__c = '/forecast/power/ems/default,/metering/power/ems/default,/availability/power/portal/correction';
            timeSerie.PathsCurtailments__c = '/regulation/power/ems/default,/metering/power/ems/default';
            Database.SaveResult tiSiSave = Database.insert(timeSerie);
        } catch (Exception e) {
        }

        //Custom Setting Notification Salutation
        try {
            msNotificationSalutation__c salutation = new msNotificationSalutation__c();
            salutation.Name = 'en_US';
            salutation.female__c = 'Dear Ms. ';
            salutation.male__c = 'Dear Mr. ';
            Database.SaveResult saluSave = Database.insert(salutation);
        } catch (Exception e) {
        }

        //Portal Files
        Portal_Files__c portalFile = new Portal_Files__c();
        portalFile.Name = 'Test';
        portalFile.Subtitle__c = 'Test';
        portalFile.Language__c = 'en_US';
        Database.SaveResult portFiSave = Database.insert(portalFile);

        // Content Version
        Blob file = Blob.valueOf('testdata');
        ContentVersion testVersion = new ContentVersion();
        testVersion.Title = 'testVersion';
        testVersion.VersionData = file;
        testVersion.PathOnClient = '/somepath0.txt';
        testVersion.Community_available__c = true;
        testVersion.Attachement_Type__c = 'Sonstiges';
        Database.SaveResult testVersionSave = Database.insert(testVersion);
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];

        // CSV to test for Bryt Admin-Panel: CSV Upload
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        Blob file0 = Blob.valueOf(CSV_CONTENT);
        ContentVersion version1 = new ContentVersion();
        version1.Title = 'testCsvContentVersion';
        version1.VersionData = file0;
        version1.PathOnClient = '/somepath1.csv';
        version1.Community_available__c = true;
        version1.IsMajorVersion = false;
        version1.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version1);

        // CSV-template to test (One header + one row) Test new Contract (Insert)
        Blob file2 = Blob.valueOf(CSV_NEW_CONTRACT_TO_TEST);
        ContentVersion version2 = new ContentVersion();
        version2.Title = 'testCsvContentVersion2';
        version2.VersionData = file2;
        version2.PathOnClient = '/somepath2.csv';
        version2.Community_available__c = true;
        version2.IsMajorVersion = false;
        version2.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version2);

        // CSV-template to test (One header + one row)
        Blob file3 = Blob.valueOf(CSV_REFCAP_TO_TEST);
        ContentVersion version3 = new ContentVersion();
        version3.Title = 'testCsvContentVersion3';
        version3.VersionData = file3;
        version3.PathOnClient = '/somepath3.csv';
        version3.Community_available__c = true;
        version3.IsMajorVersion = false;
        version3.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version3);

        // CSV-template to test (One header + one row)
        Blob file4 = Blob.valueOf(CSV_REFCAP_NON_EXISTING_TO_TEST);
        ContentVersion version4 = new ContentVersion();
        version4.Title = 'testCsvContentVersion4';
        version4.VersionData = file4;
        version4.PathOnClient = '/somepath4.csv';
        version4.Community_available__c = true;
        version4.IsMajorVersion = false;
        version4.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version4);

        // CSV-template to test (One header + one row)
        Blob file5 = Blob.valueOf(CSV_CONTRACT_TO_TEST);
        ContentVersion version5 = new ContentVersion();
        version5.Title = 'testCsvContentVersion5';
        version5.VersionData = file5;
        version5.PathOnClient = '/somepath5.csv';
        version5.Community_available__c = true;
        version5.IsMajorVersion = false;
        version5.Bryt_Content_Type__c = 'Contracts';
        contentVersionList.add(version5);

        insert contentVersionList;

        ContentDocument conDoc2 = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :version2.Id];
        ContentDocument conDoc3 = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :version3.Id];

        ContentVersion cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testVersion.Id LIMIT 1];

        // ContentDocumentLink
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

        ContentDocumentLink cdLink1 = new ContentDocumentLink();
        cdLink1.LinkedEntityId = testContract5.id;
        cdLink1.ContentDocumentId = cv.ContentDocumentId;
        cdLink1.ShareType = 'V';
        cdlList.add(cdLink1);

        ContentDocumentLink cdLink2 = new ContentDocumentLink();
        cdLink2.LinkedEntityId = portalFile.id;
        cdLink2.ContentDocumentId = cv1.ContentDocumentId;
        cdLink2.ShareType = 'V';
        cdlList.add(cdLink2);

        // ContentDocumentLink
        ContentDocumentLink cdLink3 = new ContentDocumentLink();
        cdLink3.LinkedEntityId = c1.Id;
        cdLink3.ContentDocumentId = conDoc2.Id;
        cdLink3.ShareType = 'I';
        cdLink3.Visibility = 'AllUsers';
        cdlList.add(cdLink3);

        // ContentDocumentLink
        ContentDocumentLink cdLink4 = new ContentDocumentLink();
        cdLink4.LinkedEntityId = c2.Id;
        cdLink4.ContentDocumentId = conDoc3.Id;
        cdLink4.ShareType = 'I';
        cdLink4.Visibility = 'AllUsers';
        cdlList.add(cdLink4);
        insert cdlList;

        //PortalNews
        PortalNews__c testNews = new PortalNews__c();
        testNews.Title__c = 'Test Title' ;
        testNews.Link__c = 'www.test.com';
        testNews.Language__c = 'en_US';
        testNews.Publication_Date__c = thisDay.addDays(-2);
        testNews.Text__c = 'This is jsut a test message for the news item.';
        testNews.Type__c = 'News';
        Database.SaveResult testNewsSave = Database.insert(testNews);

        PortalNews__c testNews2 = new PortalNews__c();
        testNews2.Title__c = 'Test Title2' ;
        testNews2.Link__c = 'www.test.com';
        testNews2.Language__c = 'en_US';
        testNews2.Publication_Date__c = thisDay.addDays(-2);
        testNews2.Text__c = 'This is jsut a test message for the news item.';
        testNews2.Type__c = 'News';
        Database.SaveResult testNewsSave2 = Database.insert(testNews2);

        PortalNews__c testNews3 = new PortalNews__c();
        testNews3.Title__c = 'Test Title3' ;
        testNews3.Link__c = 'www.test.com';
        testNews3.Language__c = 'en_US';
        testNews3.Publication_Date__c = thisDay.addDays(-2);
        testNews3.Text__c = 'This is jsut a test message for the news item.';
        testNews3.Type__c = 'News';
        Database.SaveResult testNewsSave3 = Database.insert(testNews3);

        PortalNews__c testNews4 = new PortalNews__c();
        testNews4.Title__c = 'Test Title4' ;
        testNews4.Link__c = 'www.test.com';
        testNews4.Language__c = 'de';
        testNews4.Publication_Date__c = thisDay.addDays(-2);
        testNews4.Text__c = 'This is jsut a test message for the news item.';
        testNews4.Type__c = 'News';
        Database.SaveResult testNewsSave4 = Database.insert(testNews4);


        PortalNews__c maintenanceNews = new PortalNews__c();
        maintenanceNews.Title__c = 'Maintenance Planned' ;
        maintenanceNews.Link__c = 'www.test.com';
        maintenanceNews.Language__c = 'de';
        maintenanceNews.Publication_Date__c = thisDay.addDays(-2);
        maintenanceNews.Text__c = 'This is jsut a test message for the news item.';
        maintenanceNews.Type__c = 'Maintenance Information';
        Database.SaveResult maintenanceNewsSave = Database.insert(maintenanceNews);

        //Portal settings
        try {
            PortalSettings__c annualSubmeter = new PortalSettings__c();
            annualSubmeter.Name = 'Annual Submeter - Allow Update';
            annualSubmeter.Checkbox__c = true;
            Database.insert(annualSubmeter);
        } catch (Exception e) {
        }


        try {
            PortalSettings__c submeter = new PortalSettings__c();
            submeter.Name = 'Submeter - Allow Update';
            submeter.Checkbox__c = true;
            Database.insert(submeter);
        } catch (Exception e) {
        }

        try {
            PortalSettings__c notificationTypes = new PortalSettings__c();
            notificationTypes.Name = 'Notification Types';
            notificationTypes.String__c = 'test1,test2,test3';
            Database.insert(notificationTypes);
        } catch (Exception e) {
        }

        //Portal Features
        try {

            Portal_Features__c portalFeatures = new Portal_Features__c();
            portalFeatures.Name = 'DE';
            portalFeatures.Eisman__c = true;
            portalFeatures.Downregulations__c = false;
            portalFeatures.Payments__c = false;
            Database.SaveResult porFea = Database.insert(portalFeatures);
        } catch (Exception e) {
        }
    }
}
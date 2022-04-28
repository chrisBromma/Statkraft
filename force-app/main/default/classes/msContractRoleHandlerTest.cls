/****************************************************************************************************
* Class msContractRoleHandlerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   12.12.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   12.12.2019      	    Init version.
*****************************************************************************************************/

@IsTest
private class msContractRoleHandlerTest {
    private static String CONTACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contact', 'Contact').Id;
    private static Id CONTRACT_ROLE_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract_Role__c', 'Contract_Role_Contact').Id;
    public static final Id SITE_ROLE_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Site_Role__c', 'Site_Role_Contact').Id;

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    static void testCreateContractualContact() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = new Contact();
        testContact.AccountId = testAccount.Id;
        testContact.Salutation = 'Mrs';
        testContact.FirstName = 'John';
        testContact.LastName = 'Travolta';
        testContact.Email = 'johntravolta@mail.com.contractroletest';
        testContact.RecordTypeId = CONTACT_RECORD_TYPE;
        testContact.MobilePhone = '+49123456799';
        insert testContact;

        List<Contract__c> testContracts = [SELECT Id, (SELECT Id, Meter__c FROM Meter_Registrations__r) FROM Contract__c];
        Contract__c testContract = new Contract__c();
        Contract__c testContract2 = new Contract__c();
        Boolean matchOne = false;
        for (Contract__c contractToCheck : testContracts) {
            if (!matchOne && !contractToCheck.Meter_Registrations__r.isEmpty()) {
                testContract = contractToCheck;
                matchOne = true;
            } else if (!contractToCheck.Meter_Registrations__r.isEmpty()) {
                testContract2 = contractToCheck;
                break;
            }
        }

        Test.startTest();
        List<Site_Role__c> siteRoles = new List<Site_Role__c>();
        siteRoles.add(new Site_Role__c(
                Meter__c = testContract.Meter_Registrations__r[0].Meter__c,
                Start_Date__c = Date.today().addDays(-2),
                Role__c = 'Customer Portal',
                Contact__c = testContact.Id,
                RecordTypeId = SITE_ROLE_RECORD_TYPE
        ));
        siteRoles.add(new Site_Role__c(
                Meter__c = testContract2.Meter_Registrations__r[0].Meter__c,
                Start_Date__c = Date.today().addDays(-2000),
                End_Date__c = Date.today().addDays(-2000),
                Role__c = 'Customer Portal',
                Contact__c = testContact.Id,
                RecordTypeId = SITE_ROLE_RECORD_TYPE
        ));
        List<Contract_Role__c> testRoles = new List<Contract_Role__c>();
        testRoles.add(new Contract_Role__c(
                Contract__c = testContract.Id,
                Start_Date__c = Date.today().addDays(-2),
                Role__c = 'Customer Portal',
                Contact__c = testContact.Id,
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        ));
        testRoles.add(new Contract_Role__c(
                Contract__c = testContract.Id,
                Start_Date__c = Date.today().addDays(-2),
                Role__c = 'Contractual contact',
                Contact__c = testContact.Id,
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        ));
        testRoles.add(new Contract_Role__c(
                Contract__c = testContract.Id,
                Start_Date__c = Date.today(),
                Role__c = 'Contractual contact',
                Contact__c = testContact.Id,
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        ));
        testRoles.add(new Contract_Role__c(
                Contract__c = testContract2.Id,
                Start_Date__c = Date.today().addDays(-2000),
                End_Date__c = Date.today().addDays(-2000),
                Role__c = 'Customer Portal',
                Contact__c = testContact.Id,
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        ));
        testRoles.add(new Contract_Role__c(
                Contract__c = testContract2.Id,
                Start_Date__c = Date.today(),
                Role__c = 'Contractual contact',
                Contact__c = testContact.Id,
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        ));
        insert siteRoles;
        insert testRoles;
        Test.stopTest();

        System.assert([
                SELECT msAwaitingPortalActivation__c
                FROM Contact
                WHERE Id = :testContact.Id
                LIMIT 1
        ].msAwaitingPortalActivation__c);
        System.assertEquals(1, [
                SELECT COUNT()
                FROM Contract_Role__c
                WHERE Contact__c = :testContact.Id
                AND Contract__c = :testContract.Id
                AND Role__c = 'Customer Portal'
        ]);
        Set<Id> meterIds = new Set<Id>();
        for (MeterRegistration__c regItem : testContract.Meter_Registrations__r) {
            meterIds.add(regItem.Meter__c);
        }
        System.assertEquals(meterIds.size(), [
                SELECT COUNT()
                FROM Site_Role__c
                WHERE Contact__c = :testContact.Id
                AND Meter__c IN :meterIds
                AND Role__c = 'Customer Portal'
        ]);
        System.assertEquals(2, [
                SELECT COUNT()
                FROM Contract_Role__c
                WHERE Contact__c = :testContact.Id
                AND Contract__c = :testContract2.Id
                AND Role__c = 'Customer Portal'
        ]
        );
        System.assertEquals(2, [
                SELECT COUNT()
                FROM Site_Role__c
                WHERE Contact__c = :testContact.Id
                AND Meter__c = :testContract2.Meter_Registrations__r[0].Meter__c
                AND Role__c = 'Customer Portal'
        ]
        );
    }

    @IsTest
    static void checkNamingAfterInsert() {
        Contract__c randomContract = [
                SELECT Name, (
                        SELECT Id, Meter__r.Name
                        FROM Meter_Registrations__r
                        ORDER BY CreatedDate ASC
                )
                FROM Contract__c
                LIMIT 1
        ];
        String resultName = randomContract.Name;
        if (!randomContract.Meter_Registrations__r.isEmpty()) {
            resultName += '-';
            Set<String> meterNames = new Set<String>();
            for (MeterRegistration__c regItem : randomContract.Meter_Registrations__r) {
                meterNames.add(regItem.Meter__r.Name);
            }
            for (String meterName : meterNames) {
                resultName += meterName + ',';
            }
            resultName = resultName.removeEnd(',');
            if (resultName.length() > 80) {
                resultName = resultName.left(76) + '...';
            }
        }
        Contact randomContact = [
                SELECT Id
                FROM Contact
                LIMIT 1
        ];
        Contract_Role__c newRole = new Contract_Role__c(
                Name = 'test',
                Contract__c = randomContract.Id,
                Contact__c = randomContact.Id
        );
        Test.startTest();
        insert newRole;
        Test.stopTest();
        newRole = [SELECT Name FROM Contract_Role__c WHERE Id = :newRole.Id];
        System.assert(newRole.Name == resultName);
    }

    @IsTest
    private static void noDuplicateInsertFrance_Test() {
        Contact frenchUser = [
                SELECT Id
                FROM Contact
                WHERE Email = 'frcontact@mail.com.testdatafactory'
        ];
        List<msUserNotificationSetting__c> newInvoice = [
                SELECT Id
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = 'new_invoice'
                AND msContact__c = :frenchUser.Id
        ];
        if (newInvoice.isEmpty()) {
            insert new msUserNotificationSetting__c(msContact__c = frenchUser.Id, msNotificationType__c = 'new_Invoice');
        }
        Contract__c frenchContract = [SELECT Id FROM Contract__c WHERE Global_Portal_Market__c = 'France'];
        Contract_Role__c cpRole = new Contract_Role__c(
                Contact__c = frenchUser.Id,
                Contract__c = frenchContract.Id,
                Start_Date__c = Date.today().addDays(-1),
                Role__c = 'Customer Portal',
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        );

        Test.startTest();

        insert cpRole;

        Test.stopTest();

        newInvoice = [
                SELECT Id
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = 'new_invoice'
                AND msContact__c = :frenchUser.Id
        ];
        System.assertEquals(1, newInvoice.size());
    }

    @IsTest
    private static void franceSubscription_Test() {
        Contract__c frenchContract = [SELECT Id FROM Contract__c WHERE Global_Portal_Market__c = 'France'];
        Contact freshContact = new Contact(LastName = 'franceSubscription_Test');
        insert freshContact;
        Contract_Role__c cpRole = new Contract_Role__c(
                Contact__c = freshContact.Id,
                Contract__c = frenchContract.Id,
                Start_Date__c = Date.today().addDays(-1),
                Role__c = 'Customer Portal',
                RecordTypeId = CONTRACT_ROLE_RECORD_TYPE
        );

        Test.startTest();

        insert cpRole;

        Test.stopTest();

        List<msUserNotificationSetting__c> newInvoice = [
                SELECT Id, msIsEmail__c, msIsSMS__c
                FROM msUserNotificationSetting__c
                WHERE msNotificationType__c = 'new_invoice'
                AND msContact__c = :freshContact.Id
        ];
        System.assertEquals(1, newInvoice.size());
        System.assertEquals(true, newInvoice[0].msIsEmail__c);
        System.assertEquals(false, newInvoice[0].msIsSMS__c);
    }

    @IsTest
    private static void renamingTest() {
        List<Contract_Role__c> allRoles = [
                SELECT Id, Name
                FROM Contract_Role__c
        ];

        Test.startTest();

        for(Contract_Role__c role : allRoles) {
            role.Name = 'Reinitialize';
        }
        update allRoles;

        Test.stopTest();

        allRoles = [
                SELECT Id, Name
                FROM Contract_Role__c
        ];
        for(Contract_Role__c role : allRoles) {
            System.assert(role.Name != 'Reinitialize', 'Role was not renamed');
        }
    }
}
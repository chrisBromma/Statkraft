/****************************************************************************************************
* Class msUserNotificationSettingsHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-06-18
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-06-18       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msUserNotificationSettingsHandlerTest {

    @TestSetup
    private static void testSetup() {

    }

    @IsTest
    private static void denyDuplicateThroughInsert_Test1() {
        Contact testContact = new Contact(LastName = 'test');
        insert testContact;
        List<msUserNotificationSetting__c> settings = new List<msUserNotificationSetting__c>();
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        insert settings[0];
        Test.startTest();
        try {
            insert settings[1];
            System.assert(false, 'The Duplicate was not stopped from insertion');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains(Label.validationErrorDuplicateNotificationSubscription));
        }
    }

    @IsTest
    private static void denyDuplicateThroughInsert_Test2() {
        Contact testContact = new Contact(LastName = 'test');
        insert testContact;
        List<msUserNotificationSetting__c> settings = new List<msUserNotificationSetting__c>();
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        Test.startTest();
        try {
            insert settings;
            System.assert(false, 'The Duplicate was not stopped from insertion');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains(Label.validationErrorDuplicateNotificationSubscription));
        }
    }

    @IsTest
    private static void denyDuplicateThroughUndelete_Test1() {
        Contact testContact = new Contact(LastName = 'test');
        insert testContact;
        List<msUserNotificationSetting__c> settings = new List<msUserNotificationSetting__c>();
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        insert settings[0];
        delete settings[0];
        insert settings[1];

        Test.startTest();
        try {
            undelete settings[0];
            System.assert(false, 'The Duplicate was not stopped from undeletion');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains(Label.validationErrorDuplicateNotificationSubscription));
        }
    }

    @IsTest
    private static void denyDuplicateThroughUndelete_Test2() {
        Contact testContact = new Contact(LastName = 'test');
        insert testContact;
        List<msUserNotificationSetting__c> settings = new List<msUserNotificationSetting__c>();
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        insert settings[0];
        delete settings[0];
        insert settings[1];
        delete settings[1];

        Test.startTest();
        try {
            undelete settings;
            System.assert(false, 'The Duplicate was not stopped from undeletion');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains(Label.validationErrorDuplicateNotificationSubscription));
        }
    }

    @IsTest
    private static void denyDuplicateThroughUpdate_Test1() {
        Contact testContact = new Contact(LastName = 'test');
        insert testContact;
        List<msUserNotificationSetting__c> settings = new List<msUserNotificationSetting__c>();
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'downreg_notification'
        ));
        insert settings;

        Test.startTest();
        settings[1].msNotificationType__c = 'new_invoice';
        try {
            update settings[1];
            System.assert(false, 'The Duplicate was not stopped from update');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains(Label.validationErrorDuplicateNotificationSubscription));
        }
    }

    @IsTest
    private static void denyDuplicateThroughUpdate_Test2() {
        Contact testContact = new Contact(LastName = 'test');
        insert testContact;
        List<msUserNotificationSetting__c> settings = new List<msUserNotificationSetting__c>();
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'new_invoice'
        ));
        settings.add(new msUserNotificationSetting__c(
                msContact__c = testContact.Id,
                msNotificationType__c = 'downreg_notification'
        ));
        insert settings;

        Test.startTest();
        settings[0].msNotificationType__c = 'submeter_enabled';
        settings[1].msNotificationType__c = 'submeter_enabled';
        try {
            update settings;
            System.assert(false, 'The Duplicate was not stopped from update');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(e.getMessage().contains(Label.validationErrorDuplicateNotificationSubscription));
        }
    }
}
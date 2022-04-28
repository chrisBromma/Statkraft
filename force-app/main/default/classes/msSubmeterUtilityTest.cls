/****************************************************************************************************
* Class msSubmeterUtilityTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2020-01-07
*   Description	:	Test Class for the Apex Class msSubmeterUtility
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2020-01-07       	Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msSubmeterUtilityTest {
    @TestSetup private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
        List<PortalSettings__c> portalSettings = new List<PortalSettings__c>();
        portalSettings.add(new PortalSettings__c(Name = 'Annual Submeter - Allow Update', Checkbox__c = true));
        portalSettings.add(new PortalSettings__c(Name = 'Monthly Submeter - Allow Update', Checkbox__c = true));
        insert portalSettings;
    }

    @IsTest private static void switchSubmeterEditingTest() {
        msSubmeterUtility.switchSubmeterEditing('annual_submeter_enabled', true);
        msSubmeterUtility.switchSubmeterEditing('annual_submeter_enabled', false);
        msSubmeterUtility.switchSubmeterEditing('monthly_submeter_enabled', true);
        msSubmeterUtility.switchSubmeterEditing('monthly_submeter_enabled', false);
    }

    @IsTest private static void issueNotificationsAnnualEnabledTest() {
        msSubmeterUtility.issueNotifications('annual_submeter_enabled');
    }
    @IsTest private static void issueNotificationsAnnualReminderTest() {
        msSubmeterUtility.issueNotifications('annual_submeter_reminder');
    }
    @IsTest private static void issueNotificationsMonthlyEnabledTest() {
        msSubmeterUtility.issueNotifications('monthly_submeter_enabled');
    }
    @IsTest private static void issueNotificationsMonthlyReminderTest() {
        msSubmeterUtility.issueNotifications('monthly_submeter_reminder');
    }

    @IsTest private static void isMeterBillingTypePricingComponentTest(){
        Pricing_Component__c fixedPricePc = new Pricing_Component__c(
                Name = 'Fixed Energy Price',
                RecordTypeId = Application.RecordTypes.byDeveloperName('Pricing_Component__c', 'Fixed_Energy_Price').Id,
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                Meter_Billing_Type__c = 'Sub-Meter Monthly'
        );

        Pricing_Component__c floatingPricePc = new Pricing_Component__c(
                Name = 'Floating Energy Price',
                RecordTypeId = Application.RecordTypes.byDeveloperName('Pricing_Component__c', 'Floating_Energy_Price').Id,
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                Meter_Billing_Type__c = 'Sub-Meter Monthly'
        );

        System.assertEquals(false, msSubmeterUtility.isMeterBillingTypePricingComponent(floatingPricePc));
        System.assertEquals(false, msSubmeterUtility.isMeterBillingTypePricingComponent(fixedPricePc));
    }

}
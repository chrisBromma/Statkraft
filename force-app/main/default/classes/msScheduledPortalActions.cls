/****************************************************************************************************
* Class msScheduledPortalActions
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-12-12
*   Description	:	This is the central class to organize all Scheduled notifications that are issued
*                   via the Notification Framework. Settings for this class can be found in the
*                   Custom Metadata Portal System Settings.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-12-12       	Init version.
*****************************************************************************************************/

global without sharing class msScheduledPortalActions implements Schedulable {
    global void execute(SchedulableContext ctx) {
        msPortalSystemSetting__mdt portalSystemSettings = msUtility.getPortalSettings();
        Date today = Date.today();

        BackendMonitoring__e logEventGeneral = msUtility.getEvent('Schedule Portal Actions');

        /**
        * Submeter Annual Editing enabled
        */
        if ((today.day() == portalSystemSettings.annual_submeter_enabled_day__c
                && today.month() == portalSystemSettings.annual_submeter_enabled_month__c)
                || Test.isRunningTest()) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Annual Editing enabled');

            if (!portalSystemSettings.debug_submeter_enabled__c) {
                try {
                    msSubmeterUtility.switchSubmeterEditing('annual_submeter_enabled', true);

                    msUtility.ifTestThrowFakeException();
                } catch (Exception e) {
                    logEvent = msUtility.handleException(logEvent, e);
                }
            }
            try {
                msSubmeterUtility.issueNotifications('annual_submeter_enabled');

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Submeter Annual Editing reminder
        */
        if ((today.day() == portalSystemSettings.annual_submeter_reminder_day__c
                && today.month() == portalSystemSettings.annual_submeter_reminder_month__c)
                || Test.isRunningTest()) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Annual Editing reminder');

            try {
                msSubmeterUtility.issueNotifications('annual_submeter_reminder');

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }

        }

        /**
        * Submeter Annual Editing disabled
        */
        if (((today.day() == portalSystemSettings.annual_submeter_reminder_day__c
                && today.month() == portalSystemSettings.annual_submeter_disabled_month__c)
                && !portalSystemSettings.debug_submeter_enabled__c)
                || Test.isRunningTest()) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Annual Editing disabled');

            try {
                msSubmeterUtility.switchSubmeterEditing('annual_submeter_enabled', false);

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Submeter Monthly Editing enabled
        */
        if (today.day() == portalSystemSettings.monthly_submeter_enabled_day__c || Test.isRunningTest()) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Monthly Editing enabled');

            if (!portalSystemSettings.debug_submeter_enabled__c) {
                try {
                    msSubmeterUtility.switchSubmeterEditing('monthly_submeter_enabled', true);

                    msUtility.ifTestThrowFakeException();
                } catch (Exception e) {
                    logEvent = msUtility.handleException(logEvent, e);
                }
            }

            try {
                msSubmeterUtility.issueNotifications('monthly_submeter_enabled');

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Submeter Monthly Editing reminder
        */
        if (today.day() == portalSystemSettings.monthly_submeter_reminder_day__c || Test.isRunningTest()) {

            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Monthly Editing reminder');
            try {
                msSubmeterUtility.issueNotifications('monthly_submeter_reminder');

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Submeter Monthly Editing disabled
        */
        if (((today.day() == portalSystemSettings.monthly_submeter_disabled_day__c && !portalSystemSettings.debug_submeter_enabled__c) || Test.isRunningTest()) ) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Submeter Monthly Editing disabled');
            try {
                msSubmeterUtility.switchSubmeterEditing('monthly_submeter_enabled', false);

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Monthly Production Mails
        */
        if (today.day() == portalSystemSettings.monthly_production_data_day__c || Test.isRunningTest()) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Monthly Production Mails');
            try {
                msNotificationLogic.distributeMessage(null, null, 'monthly_production_data', null, null, null, null);

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Unlock Curtailments Editing
        */
        if (today.day() == portalSystemSettings.curtailment_unlocking_day__c || Test.isRunningTest()) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Unlock Curtailments Editing');
            try {
                msCurtailmentLockHandler.unlockCurtailmentUpdate();

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

        /**
        * Lock Curtailments Editing
        */
        if ((0 < portalSystemSettings.curtailment_locking_day__c
                && portalSystemSettings.curtailment_locking_day__c < 32
                && msCurtailmentLockHandler.calculateTriggerWorkdays((Integer) portalSystemSettings.curtailment_locking_day__c).contains(today))
                || Test.isRunningTest() ) {
            BackendMonitoring__e logEvent = msUtility.getEvent('Lock Curtailments Editing');
            try {
                msCurtailmentLockHandler.lockCurtailmentUpdate();

                msUtility.ifTestThrowFakeException();
            } catch (Exception e) {
                logEvent = msUtility.handleException(logEvent, e);
            } finally {
                msUtility.publishEvent(logEvent);
            }
        }

    }
}
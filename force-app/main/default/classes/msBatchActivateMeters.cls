/****************************************************************************************************
* Class msBatchActivateMeters
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2019-07-15
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            2019-07-15       	Init version.
*   * Dennis Grzyb (mindsquare AG)   	                2021-07-15       	Extend BatchJobBase for Scheduler Framework.
*****************************************************************************************************/

global without sharing class msBatchActivateMeters
        extends BatchJobBase
        implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
    global msBatchActivateMeters() {
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        super.startLogging(batchableContext?.getJobId());
        return Database.getQueryLocator(
                'SELECT ' +
                        'Id,' +
                        'Current_Contract__c,' +
                        'Scheduled_Cloning_Date__c,' +
                        'Scheduled_for_Activation_on__c, (' +
                        'SELECT ' +
                                'Id,' +
                                'Active__c,' +
                                'Valid_from__c,' +
                                'Valid_to__c,' +
                                'Contract__c ' +
                        'FROM Meter_Registrations__r ' +
                        'ORDER BY Valid_from__c ASC' +
                ') ' +
                'FROM Meter__c'
        );
    }
    global void execute(Database.BatchableContext batchableContext, List<Meter__c> scope) {
        updateActiveFlagsForMeters(scope);
        super.logEndOfBatch(scope, batchableContext.getJobId(), true, Label.batchLoggingSuccessMessage);
    }

    global void finish(Database.BatchableContext batchableContext) {
        super.finishBatch(batchableContext.getJobId());
    }

    public static void updateActiveFlagForMeters(Set<Id> meterIds) {
        List<Meter__c> metersToCheck = [
                SELECT
                        Id,
                        Current_Contract__c,
                        Scheduled_Cloning_Date__c,
                        Scheduled_for_Activation_on__c, (
                        SELECT
                                Id,
                                Active__c,
                                Valid_from__c,
                                Valid_to__c,
                                Contract__c
                        FROM Meter_Registrations__r
                        ORDER BY Valid_from__c ASC
                )
                FROM Meter__c
                WHERE Id IN :meterIds
        ];

        updateActiveFlagsForMeters(metersToCheck);
    }

    private static void updateActiveFlagsForMeters(List<Meter__c> metersToUpdate) {
        List<MeterRegistration__c> registrations = new List<MeterRegistration__c>();
        List<Meter__c> meterUpdates = new List<Meter__c>();

        for (Meter__c meterItem : metersToUpdate) {
            updateContainer resultItem = setActiveFlagsForMeterRegistrationsOnMeter(meterItem);
            if (!resultItem.updatedMeterRegistrations.isEmpty()) {
                registrations.addAll(resultItem.updatedMeterRegistrations);
            }
            if (resultItem.updatedMeter != null) {
                meterUpdates.add(resultItem.updatedMeter);
            }
        }
        if (!registrations.isEmpty()) {
            update registrations;
        }
        if (!meterUpdates.isEmpty()) {
            update meterUpdates;
        }
    }

    private static updateContainer setActiveFlagsForMeterRegistrationsOnMeter(Meter__c meterToCheck) {
        MeterRegistration__c currentlyAsActiveSelectedMeterReg = null;
        Id currentContract = null;
        updateContainer result = new updateContainer();

        Map<Id, Boolean> beforeUpdateActiveState = new Map<Id, Boolean>();
        for (MeterRegistration__c regItem : meterToCheck.Meter_Registrations__r) {
            beforeUpdateActiveState.put(regItem.Id, regItem.Active__c);

            if ((meterToCheck.Scheduled_Cloning_Date__c != null
                    && meterToCheck.Scheduled_Cloning_Date__c <= Date.today())
                    || (meterToCheck.Scheduled_for_Activation_on__c != null
                    && meterToCheck.Scheduled_for_Activation_on__c > Date.today())) {
                regItem.Active__c = false;
                currentContract = regItem.Contract__c;
            } else if (currentlyAsActiveSelectedMeterReg == null) {
                regItem.Active__c = true;
                currentContract = regItem.Contract__c;
                currentlyAsActiveSelectedMeterReg = regItem;
            } else if (regItem.Valid_from__c != null && regItem.Valid_from__c <= Date.today()) {
                regItem.Active__c = true;
                currentContract = regItem.Contract__c;
                currentlyAsActiveSelectedMeterReg.Active__c = false;
                currentlyAsActiveSelectedMeterReg = regItem;
            } else {
                regItem.Active__c = false;
            }
        }

        for (MeterRegistration__c regItem : meterToCheck.Meter_Registrations__r) {
            if (regItem.Active__c != beforeUpdateActiveState.get(regItem.Id)) {
                result.updatedMeterRegistrations.add(new MeterRegistration__c(
                        Id = regItem.Id,
                        Active__c = regItem.Active__c
                ));
            }
        }

        if (currentContract != meterToCheck.Current_Contract__c) {
            meterToCheck.Current_Contract__c = currentContract;
            result.updatedMeter = new Meter__c(Id = meterToCheck.Id, Current_Contract__c = currentContract);
        }
        return result;
    }

    private class updateContainer {

        private List<MeterRegistration__c> updatedMeterRegistrations { get; set; }
        private Meter__c updatedMeter { get; set; }

        private updateContainer() {
            updatedMeterRegistrations = new List<MeterRegistration__c>();
            updatedMeter = null;
        }
    }
}
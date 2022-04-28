/****************************************************************************************************
* Class BatchSetParkCategoryForContracts
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-09-22
*   Description	:	Sets the fields Park Category and Park Category Next Year based on the state of the currently
 *                  connected Generation Units (via Meter Reg. and M2GU). Currently only supports Germany (U20) Model
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-09-22       	Init version.
*****************************************************************************************************/

global without sharing class BatchSetParkCategoryForContracts extends BatchJobBase implements Database.Batchable<SObject> {
    //Resulting values
    private static final String U20_ONLY = 'U20 Only';
    private static final String NOT_U20 = 'Not U20';
    private static final String MIXED = 'Mixed';

    //Comparing Dates
    private static final Date START_CURRENT_YEAR = Date.newInstance(Date.today().year(), 1, 1);
    private static final Date START_NEXT_YEAR = START_CURRENT_YEAR.addYears(1);

    //Local Batch Run variables
    private Set<Id> connectedMeterIds = new Set<Id>();
    private Map<Id, Meter__c> allConnectedMeters = new Map<Id, Meter__c>();
    private Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();

    //Legal Settings
    private static final Integer GERMANY_SUBSIDY_YEARS = 20;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
                'SELECT Id, Country__c, ' +
                        'Park_Category__c, Park_Category_Next_Year__c, ' +
                        '(' +
                        'SELECT Contract__c, Meter__c, '  +
                        'Valid_from__c, Valid_to__c ' +
                        'FROM Meter_Registrations__r ' +
                        ') ' +
                        'FROM Contract__c ' +
                        'WHERE Country__c = \'Germany\' ' +
                        'AND End_Date__c > TODAY');
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        identifyMeterIds(scope);
        loadMeters();
        determineScopeUpdates(scope);
        updateScope();
    }

    global void finish(Database.BatchableContext bc) {
        super.finishBatch(bc.getJobId());
    }

    private void identifyMeterIds(List<Contract__c> scope) {
        for (Contract__c germanContract : scope) {
            for (MeterRegistration__c regItem : germanContract.Meter_Registrations__r) {
                connectedMeterIds.add(regItem.Meter__c);
            }
        }
    }

    private void loadMeters() {
        if (!connectedMeterIds.isEmpty()) {
            allConnectedMeters = new Map<Id, Meter__c>([
                    SELECT Id, Country__c, (
                            SELECT Meter__c, Generator_Unit__c,
                                    Valid_from__c, Valid_to__c, Generator_Unit__r.Commissioning_Date__c
                            FROM Meter_Generator_Relationships__r
                    )
                    FROM Meter__c
                    WHERE Id IN :connectedMeterIds
            ]);
        }
    }

    private void determineScopeUpdates(List<Contract__c> scope) {
        if (!allConnectedMeters.isEmpty()) {
            for (Contract__c contractToCheck : scope) {
                //Checks for this year
                String categoryThisYear = determineSubsidy(contractToCheck.Meter_Registrations__r, START_CURRENT_YEAR, GERMANY_SUBSIDY_YEARS);
                //Checks for next year
                String categoryNextYear = determineSubsidy(contractToCheck.Meter_Registrations__r, START_NEXT_YEAR, GERMANY_SUBSIDY_YEARS);

                assignValuesAndListForUpdateIfNecessary(contractToCheck, categoryThisYear, categoryNextYear);
            }
        }
    }

    private String determineSubsidy(List<MeterRegistration__c> regs, Date comparableYearStart, Integer subsidyLength) {
        Boolean preU20Found = false;
        Boolean U20Found = false;

        for(MeterRegistration__c regItem : regs) {
            if (isValidThatYear(regItem, comparableYearStart)) {
                for (Meter2GenerationUnitRelationship__c relItem : allConnectedMeters.get(regItem.Meter__c).Meter_Generator_Relationships__r) {
                    if (relItem.Generator_Unit__r.Commissioning_Date__c != null) {
                        //Only Gen Units injecting this entire year
                        if (isValidThatYear(relItem, comparableYearStart)) {
                            if (comparableYearStart <= relItem.Generator_Unit__r.Commissioning_Date__c.addYears(subsidyLength)) {
                                preU20Found = true;
                            } else {
                                U20Found = true;
                            }
                        }
                    }
                }
            }
        }
        return determineValue(U20Found, preU20Found);
    }

    private Boolean isValidThatYear(MeterRegistration__c registration, Date firstDayOfYear) {
        return registration.Valid_from__c < firstDayOfYear.addYears(1)
                && (registration.Valid_to__c == null || registration.Valid_to__c >= firstDayOfYear);
    }

    private Boolean isValidThatYear(Meter2GenerationUnitRelationship__c relationship, Date firstDayOfYear) {
        return relationship.Valid_from__c < firstDayOfYear.addYears(1)
                && (relationship.Valid_to__c == null || relationship.Valid_to__c >= firstDayOfYear);
    }

    private String determineValue(Boolean U20Found, Boolean preU20Found) {
        String result = null;
        if (U20Found && preU20Found) {
            result = MIXED;
        } else if (preU20Found) {
            result = NOT_U20;
        } else if (U20Found) {
            result = U20_ONLY;
        }
        return result;
    }

    private void assignValuesAndListForUpdateIfNecessary(Contract__c contractToCheck,
            String categoryThisYear, String categoryNextYear) {
        if (contractToCheck.Park_Category__c != categoryThisYear
                || contractToCheck.Park_Category_Next_Year__c != categoryNextYear) {
            contractToCheck.Park_Category__c = categoryThisYear;
            contractToCheck.Park_Category_Next_Year__c = categoryNextYear;
            contractUpdateMap.put(contractToCheck.Id, contractToCheck);
        }
    }

    private void updateScope() {
        if (!contractUpdateMap.isEmpty()) {
            update contractUpdateMap.values();
        }
    }
}
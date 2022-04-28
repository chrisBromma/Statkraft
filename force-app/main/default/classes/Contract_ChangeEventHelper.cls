/****************************************************************************************************
* Class Contract_ChangeEventHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-01
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-01       	Init version.
*****************************************************************************************************/

public without sharing class Contract_ChangeEventHelper {

    //Class specific variables and Constructor
    private List<Contract__ChangeEvent> triggerNew;

    //Global / System / Static / Final
    private final Date TODAY = Date.today();

    //Constructors
    public Contract_ChangeEventHelper(List<Contract__ChangeEvent> newChangeEvents) {
        triggerNew = newChangeEvents;
    }

    //Please keep the SOQL and DML Listings sorted alphanumerically sorted by SObjectType (_< 1 < a)

    //SOQL Maps -- Only one Map per SObjectType allowed
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Generation_Unit_Assignment__c> genUnitAssignmentsMap = new Map<Id, Generation_Unit_Assignment__c>();
    private Map<Id, Generation_Unit_Ownership__c> genUnitOwnerMap = new Map<Id, Generation_Unit_Ownership__c>();
    private Map<Id, Meter2GenerationUnitRelationship__c> m2GMap = new Map<Id, Meter2GenerationUnitRelationship__c>();
    private Map<Id, MeterRegistration__c> meterRegMap = new Map<Id, MeterRegistration__c>();

    //DML Lists/Maps -- Only use Maps for Update -- Only one item per DML Type and SObjectType
    public Map<Id, Generation_Unit_Ownership__c> genUnitOwnershipUpdates = new Map<Id, Generation_Unit_Ownership__c>();
    public Map<Id, MeterRegistration__c> meterRegUpdates = new Map<Id, MeterRegistration__c>();
    public Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();


    //Contract Expiration Variables
    private Set<Id> exp_contractIdsToCheckForExpirationProceedings = new Set<Id>();
    private Set<Id> exp_expiredContractIds = new Set<Id>();
    private Set<Id> exp_possibleExpiredMeterIds = new Set<Id>();
    private Set<Id> exp_meterIdHasNoSuccessorReg = new Set<Id>();
    private Set<Id> exp_genUnitsIdsMightBeOutOfPortfolio = new Set<Id>();
    private Set<Id> exp_genUnitsIdsOutOfPortfolio = new Set<Id>();
    private Map<Id, Set<Id>> exp_contractIdToExpiringGenUnitIdsMap = new Map<Id, Set<Id>>();
    private ListMapContainer exp_genUnitIdsToExpiringGenUnitOwnerShips = new ListMapContainer(Generation_Unit_Ownership__c.SObjectType);
    private ListMapContainer exp_contractIdToExpiringMeterRegs = new ListMapContainer(MeterRegistration__c.SObjectType);
    private ListMapContainer exp_meterIdToSuccessorRegs = new ListMapContainer(MeterRegistration__c.SObjectType);
    private ListMapContainer exp_meterIdToExpiredM2Gs = new ListMapContainer(Meter2GenerationUnitRelationship__c.SObjectType);
    private ListMapContainer exp_genUnitIdToSuccessorM2Gs = new ListMapContainer(Meter2GenerationUnitRelationship__c.SObjectType);


    //Capacity and Production Recalculation related variables
    private Set<Id> cpr_relevantContractIds = new Set<Id>();
    private ListMapContainer cpr_contractIdToGenUnitAssignments = new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);


    //All SOQL Operations please keep sorted by SObject Type
    public void load_Contracts() {
        if (!exp_contractIdsToCheckForExpirationProceedings.isEmpty()
                || !cpr_relevantContractIds.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, Contract_Type_New__c, Country__c, End_Date__c, Product_Type_New__c,
                            Installed_Capacity__c,
                            Active_Installed_Capacity__c,
                            Active_Installed_Capacity_Conga__c,
                            Installed_Annual_Production__c,
                            Active_Installed_Annual_Production__c,
                            Active_Installed_Production_Conga__c,
                            Contracted_Capacity__c, Contracted_Annual_Production__c
                    FROM Contract__c
                    WHERE Id IN :exp_contractIdsToCheckForExpirationProceedings
                    OR Id IN :cpr_relevantContractIds
            ]);
        }
    }

    public void load_GenUnitAssignments() {
        if (!cpr_relevantContractIds.isEmpty()) {
            genUnitAssignmentsMap = new Map<Id, Generation_Unit_Assignment__c>([
                    SELECT Id,
                            Contract__c,
                            Installed_Capacity__c,
                            Annual_Production__c,
                            Active__c,
                            Active_for_Conga_Context__c,
                            Generation_Unit__c
                    FROM Generation_Unit_Assignment__c
                    WHERE Contract__c IN :cpr_relevantContractIds
            ]);
        }
    }

    public void load_GenUnitOwnerships() {
        if (!exp_genUnitsIdsOutOfPortfolio.isEmpty()) {
            genUnitOwnerMap = new Map<Id, Generation_Unit_Ownership__c>([
                    SELECT Id, Asset_Owner__c, End_Date__c, Generation_Unit__c, Start_Date__c
                    FROM Generation_Unit_Ownership__c
                    WHERE Generation_Unit__c IN :exp_genUnitsIdsOutOfPortfolio
                    AND (End_Date__c > TODAY OR End_Date__c = NULL)
            ]);
        }
    }

    public void load_M2Gs() {
        if (!exp_meterIdHasNoSuccessorReg.isEmpty()) {
            m2GMap = new Map<Id, Meter2GenerationUnitRelationship__c>([
                    SELECT Id, Generator_Unit__c, Meter__c, Valid_from__c, Valid_to__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Meter__c IN :exp_meterIdHasNoSuccessorReg
                    AND (Valid_to__c > TODAY OR Valid_to__c = NULL)
            ]);
        }
    }

    public void exp_load_SuccessorM2Gs() {
        if (!exp_genUnitsIdsMightBeOutOfPortfolio.isEmpty()) {
            m2GMap.putAll([
                    SELECT Id, Generator_Unit__c, Meter__c, Valid_from__c, Valid_to__c
                    FROM Meter2GenerationUnitRelationship__c
                    WHERE Meter__c NOT IN :exp_meterIdHasNoSuccessorReg
                    AND Generator_Unit__c IN :exp_genUnitsIdsMightBeOutOfPortfolio
                    AND (Valid_to__c > TODAY OR Valid_to__c = NULL)
                    AND Id NOT IN :m2GMap.keySet()
            ]);
        }
    }

    public void load_MeterRegistrations() {
        if (!exp_expiredContractIds.isEmpty()) {
            meterRegMap = new Map<Id, MeterRegistration__c>([
                    SELECT Id, Contract__c, Meter__c, Valid_from__c, Valid_to__c
                    FROM MeterRegistration__c
                    WHERE (Valid_to__c >= TODAY OR Valid_to__c = NULL)
                    AND Contract__c IN :exp_expiredContractIds
            ]);
        }
    }

    public void exp_load_SuccessorRegistrations() {
        if (!exp_possibleExpiredMeterIds.isEmpty()) {
            meterRegMap.putAll([
                    SELECT Id, Contract__c, Meter__c, Valid_from__c, Valid_to__c
                    FROM MeterRegistration__c
                    WHERE Meter__c IN :exp_possibleExpiredMeterIds
                    AND Contract__c NOT IN :exp_expiredContractIds
                    AND (Valid_to__c > TODAY OR Valid_to__c = NULL)
                    AND Id NOT IN :meterRegMap.keySet()
            ]);
        }
    }

    //Contract Expiration Methods
    public void exp_identifyExpiredContractsToCheckForRelevancy() {
        for (Contract__ChangeEvent change : triggerNew) {
            if (change.get('Status__c') == 'Expired') {
                exp_contractIdsToCheckForExpirationProceedings.addAll(msLepton.castToSetId(change.ChangeEventHeader.getRecordIds()));
            }
        }
    }

    private static Boolean exp_contractIsRelevantForExpirationLogic(Contract__c contract) {
        return !(contract.Contract_Type_New__c == 'Sub-Contract'
                && contract.Product_Type_New__c == 'White Label')
                && contract.Country__c == 'Germany';
    }

    public void exp_identifyRelevantExpiredContracts() {
        for (Id contractId : exp_contractIdsToCheckForExpirationProceedings) {
            if (exp_contractIsRelevantForExpirationLogic(contractMap.get(contractId))) {
                exp_expiredContractIds.add(contractId);
            }
        }
    }

    public void exp_identifyMetersForExpirationCheck() {
        if (!exp_expiredContractIds.isEmpty()) {
            for (MeterRegistration__c regItem : meterRegMap.values()) {
                if (exp_expiredContractIds.contains(regItem.Contract__c)) {
                    exp_possibleExpiredMeterIds.add(regItem.Meter__c);
                }
            }
        }
    }

    public void exp_identifyMetersWithoutSuccessor() {
        exp_meterIdHasNoSuccessorReg = new Set<Id>(exp_possibleExpiredMeterIds);
        Set<Id> meterIdsWithSuccessor = msLepton.castToSetId(exp_meterIdToSuccessorRegs.keySet());
        exp_meterIdHasNoSuccessorReg.removeAll(meterIdsWithSuccessor);
    }

    public void exp_identifyGenUnitsWithoutSuccessor() {
        exp_genUnitsIdsOutOfPortfolio = new Set<Id>(exp_genUnitsIdsMightBeOutOfPortfolio);
        Set<Id> genUnitIdsWithSuccessor = msLepton.castToSetId(exp_genUnitIdToSuccessorM2Gs.keySet());
        exp_genUnitsIdsOutOfPortfolio.removeAll(genUnitIdsWithSuccessor);
    }

    public void exp_identifyGenUnitsThatMightDropOutOfPortfolio() {
        if (!exp_meterIdHasNoSuccessorReg.isEmpty()) {
            for (Meter2GenerationUnitRelationship__c relItem : m2GMap.values()) {
                exp_genUnitsIdsMightBeOutOfPortfolio.add(relItem.Generator_Unit__c);
            }
        }
    }

    public void exp_buildDataModelMeterRegs() {
        if (!exp_expiredContractIds.isEmpty()) {
            for (MeterRegistration__c regItemToGroup : meterRegMap.values()) {
                if (exp_expiredContractIds.contains(regItemToGroup.Contract__c)
                        && (regItemToGroup.Valid_to__c >= TODAY
                        || regItemToGroup.Valid_to__c == null)) {
                    exp_contractIdToExpiringMeterRegs.addToMap(regItemToGroup.Contract__c, regItemToGroup);
                } else if (!exp_expiredContractIds.contains(regItemToGroup.Contract__c)
                        && exp_possibleExpiredMeterIds.contains(regItemToGroup.Meter__c)
                        && (regItemToGroup.Valid_to__c >= TODAY
                        || regItemToGroup.Valid_to__c == null)) {
                    exp_meterIdToSuccessorRegs.addToMap(regItemToGroup.Meter__c, regItemToGroup);
                }
            }
        }
    }

    public void exp_buildDataModelM2G() {
        if (!exp_meterIdHasNoSuccessorReg.isEmpty()) {
            for (Meter2GenerationUnitRelationship__c relItem : m2GMap.values()) {
                if (exp_meterIdHasNoSuccessorReg.contains(relItem.Meter__c)
                        && (relItem.Valid_to__c > TODAY
                        || relItem.Valid_to__c == null)) {
                    exp_meterIdToExpiredM2Gs.addToMap(relItem.Meter__c, relItem);
                } else if (!exp_meterIdHasNoSuccessorReg.contains(relItem.Meter__c)
                        && exp_genUnitsIdsMightBeOutOfPortfolio.contains(relItem.Generator_Unit__c)
                        && (relItem.Valid_to__c >= TODAY
                        || relItem.Valid_to__c == null)) {
                    exp_genUnitIdToSuccessorM2Gs.addToMap(relItem.Generator_Unit__c, relItem);
                }
            }
        }
    }

    public void exp_buildDataModelGenUnitOwnership() {
        if (!exp_genUnitsIdsOutOfPortfolio.isEmpty()) {
            for (Id contractId : exp_contractIdToExpiringMeterRegs.keySet()) {
                List<MeterRegistration__c> expiringRegistrations = exp_contractIdToExpiringMeterRegs.get(contractId);
                for (MeterRegistration__c regItem : expiringRegistrations) {
                    if (exp_meterIdHasNoSuccessorReg.contains(regItem.Meter__c)) {
                        List<Meter2GenerationUnitRelationship__c> expiringM2Gs = exp_meterIdToExpiredM2Gs.get(regItem.Meter__c);
                        for (Meter2GenerationUnitRelationship__c relItem : expiringM2Gs) {
                            Set<String> genUnitsWithSuccessorM2Gs = exp_genUnitIdToSuccessorM2Gs.keySet();
                            if (!genUnitsWithSuccessorM2Gs.contains(relItem.Generator_Unit__c)) {
                                msLepton.addToMap(regItem.Contract__c, relItem.Generator_Unit__c, exp_contractIdToExpiringGenUnitIdsMap);
                            }
                        }
                    }
                }
            }
            for (Generation_Unit_Ownership__c ownershipItem : genUnitOwnerMap.values()) {
                if (exp_genUnitsIdsOutOfPortfolio.contains(ownershipItem.Generation_Unit__c)
                        && (ownershipItem.End_Date__c > TODAY
                        || ownershipItem.End_Date__c == null)) {
                    exp_genUnitIdsToExpiringGenUnitOwnerShips.addToMap(ownershipItem.Generation_Unit__c, ownershipItem);
                }
            }
        }
    }

    public void exp_ifExpirationHandleContracts(Contract__ChangeEvent change) {
        if (change.get('Status__c') == 'Expired') {
            for (Id contractId : change.ChangeEventHeader.getRecordIds()) {
                Contract__c contract = contractMap.get(contractId);
                if (exp_contractIsRelevantForExpirationLogic(contract)) {
                    exp_closeRelatedRecordsAfterExpiration(contract);
                }
            }
        }
    }

    public void exp_closeRelatedRecordsAfterExpiration(Contract__c contract) {
        List <MeterRegistration__c> meterRegsList = exp_contractIdToExpiringMeterRegs.get(contract.Id);
        Set<Id> relevantMeterIds = new Set<Id>();
        for (MeterRegistration__c meterRegItem : meterRegsList) {
            meterRegItem.Valid_to__c = contract.End_Date__c;
            if (meterRegItem.Valid_to__c < meterRegItem.Valid_from__c) {
                meterRegItem.Valid_from__c = meterRegItem.Valid_to__c.addDays(-1);
            }
            meterRegUpdates.put(meterRegItem.Id, meterRegItem);
            relevantMeterIds.add(meterRegItem.Meter__c);
        }
        Set<Id> genUnitsToCloseIds = exp_contractIdToExpiringGenUnitIdsMap.get(contract.Id);
        //M2G will only be closed when they either are relocated to different Meter or are knowingly decommissioned. We do close Ownerships though if they don't succeed here
        if (genUnitsToCloseIds != null) {
            for (Id genUnitId : genUnitsToCloseIds) {
                List<Generation_Unit_Ownership__c> ownershipsToClose = exp_genUnitIdsToExpiringGenUnitOwnerShips.get(genUnitId);
                for (Generation_Unit_Ownership__c ownershipToClose : ownershipsToClose) {
                    ownershipToClose.End_Date__c = contract.End_Date__c;
                    if (ownershipToClose.Start_Date__c >= ownershipToClose.End_Date__c) {
                        ownershipToClose.Start_Date__c = ownershipToClose.End_Date__c.addDays(-1);
                    }
                    genUnitOwnershipUpdates.put(ownershipToClose.Id, ownershipToClose);
                }
            }
        }
    }

    //Conga Context related methods
    public void cpr_identifyContracts_Update() {
        for (Contract__ChangeEvent change : triggerNew) {
            if (cpr_isRelevantUpdate(change)) {
                cpr_relevantContractIds.addAll(msLepton.castToSetId(change.ChangeEventHeader.getRecordIds()));
            }
        }
    }

    public void cpr_buildDataModel() {
        for (Generation_Unit_Assignment__c assignmentItem : genUnitAssignmentsMap.values()) {
            cpr_contractIdToGenUnitAssignments.addToMap(assignmentItem.Contract__c, assignmentItem);
        }
    }

    public void cpr_calculateContractUpdate(Contract__ChangeEvent change) {
        //TODO: ugly on the limit side, needs a proper solution
        if (cpr_isRelevantUpdate(change)) {
            Set<Id> contractsToCheckForUpdateIds = msLepton.castToSetId(change.ChangeEventHeader.getRecordIds());
            BatchCalculateCapAndProdOnContracts.checkForUpdateAndExecuteUpdate(contractsToCheckForUpdateIds);
        }
    }

    private static Boolean cpr_isRelevantUpdate(Contract__ChangeEvent change) {
        return change.get('Start_for_Conga_Context__c') != null
                || change.get('End_for_Conga_Context__c') != null
                || change.get('Start_Date__c') != null
                || change.get('End_Date__c') != null;
    }
}
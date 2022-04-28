/****************************************************************************************************
* Class msMeterRegistrationHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-09-30
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-09-30       	Init version.
*****************************************************************************************************/

public without sharing class msMeterRegistrationHelper {

    private List<MeterRegistration__c> triggerOld;
    private List<MeterRegistration__c> triggerNew;
    private Map<Id, MeterRegistration__c> oldMap;
    private Map<Id, MeterRegistration__c> newMap;

    public msMeterRegistrationHelper(
            List<MeterRegistration__c> oldList,
            List<MeterRegistration__c> newList,
            Map<Id, MeterRegistration__c> mapOld,
            Map<Id, MeterRegistration__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //Global/System Static variables
    private static final String PPA_CONTRACT_RECORD_TYPE =
            Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    private static final List<Schema.PicklistEntry> statusEntries = MeterRegistration__c.Status__c.getDescribe().getPicklistValues();

    //SOQL Maps
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Balancing_Circle__c> balancingCircleMap = new Map<Id, Balancing_Circle__c>();

    //DML Lists/Maps
    public Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();


    //Meter Registration Status update variables
    private Set<Id> mrs_contractIdsForStatusUpdate = new Set<Id>();
    private ListMapContainer mrs_contractIdsToStatusUpdateMeterRegs = new ListMapContainer(MeterRegistration__c.SObjectType);

    //France Balancing Circle variables
    private Boolean fbc_isBalancingCircleUpdateRelevant = false;
    private Balancing_Circle__c fbc_franceBalancingCircle = null;
    private static final String fbc_FRANCE_BALANCING_CIRCLE_NAME = '11XSTATKRAFT001N';

    //Balancing Circle Lookup matching variables
    private Boolean bcl_isBalancingCircleUpdateRelevant = false;
    private Map<String, Balancing_Circle__c> bcl_balancingCirclesByNameMap = new Map<String, Balancing_Circle__c>();

    //Remit Relevancy Check variables
    private Set<Id> rrc_contractIds = new Set<Id>();
    private ListMapContainer rrc_contractIdToMeterRegsOfActiveMeters = new ListMapContainer(MeterRegistration__c.SObjectType);
    private static final List<String> rrc_INACTIVE_METER_STATUS = new List<String>{
            'Planned', 'Under Construction'
    };

    //Capacity and Production variables
    private Set<Id> cap_contractIdsToUpdate = new Set<Id>();
    private ListMapContainer cap_contractIdToMeterRegs = new ListMapContainer(MeterRegistration__c.SObjectType);

    //SOQL methods
    public void load_BalancingCircles() {
        if (fbc_isBalancingCircleUpdateRelevant || bcl_isBalancingCircleUpdateRelevant) {
            balancingCircleMap = new Map<Id, Balancing_Circle__c>([
                    SELECT Id, Name
                    FROM Balancing_Circle__c
            ]);
        }
    }

    public void load_Contracts() {
        if (!mrs_contractIdsForStatusUpdate.isEmpty()
                || !rrc_contractIds.isEmpty()
                || !cap_contractIdsToUpdate.isEmpty()) {
            contractMap = new Map<Id, Contract__c> ([
                    SELECT Id, Name, Contracted_Capacity__c, Active_Installed_Capacity__c, Start_Date__c,
                            Contracted_Annual_Production__c,
                            End_Date__c, Status__c, Country__c, Workflow_Type__c,
                            REMIT_Reporting_Relevant__c, Contract_Type_New__c,
                            Product_Type_New__c, Legal_Capacity__c,
                            Third_Party_Contract__c, RecordTypeId, (
                            SELECT Id, Name, Annual_Production__c,
                                    Installed_Capacity__c, Volume_Share__c, Contract__c, Active__c,
                                    Status__c, Contract__r.RecordTypeId, Meter__r.Status__c, Meter__c
                            FROM Meter_Registrations__r
                    )
                    FROM Contract__c
                    WHERE Id IN :mrs_contractIdsForStatusUpdate
                    OR Id IN :rrc_contractIds
                    OR Id IN :cap_contractIdsToUpdate
            ]);
        }
    }

    //France Balancing Circle methods
    public void fbc_determineIfBalancingCirclesNeedToBeLoadedOnInsert() {
        for (MeterRegistration__c newRegItem : triggerNew) {
            if (newRegItem.Country__c == 'France') {
                fbc_isBalancingCircleUpdateRelevant = true;
            }
        }
    }

    public void fbc_determineIfBalancingCirclesNeedToBeLoadedOnUpdate() {
        for (MeterRegistration__c newRegItem : triggerNew) {
            if (newRegItem.Country__c == 'France'
                    && (newRegItem.Balancing_Circle__c == null
                    || newRegItem.Balancing_Circle_Lookup__c == null)) {
                fbc_isBalancingCircleUpdateRelevant = true;
            }
        }
    }

    public void fbc_ifFranceSetBalancingCircle(MeterRegistration__c newMeterRegistration) {
        if (newMeterRegistration.Country__c == 'France'
                && (newMeterRegistration.Balancing_Circle__c == null
                || newMeterRegistration.Balancing_Circle__c == '')) {
            newMeterRegistration.Balancing_Circle__c = fbc_FRANCE_BALANCING_CIRCLE_NAME;
            newMeterRegistration.Balancing_Circle_Lookup__c = fbc_franceBalancingCircle.Id;
        }
    }

    public void fbc_setFranceBalancingCircle() {
        if (fbc_isBalancingCircleUpdateRelevant) {
            for (Balancing_Circle__c balCircleItem : balancingCircleMap.values()) {
                if (balCircleItem.Name == fbc_FRANCE_BALANCING_CIRCLE_NAME) {
                    fbc_franceBalancingCircle = balCircleItem;
                }
            }
        }
    }

    //Meter Registration Status Update methods
    public void mrs_identifyContractsForStatusUpdate_Insert() {
        for (MeterRegistration__c regItem : triggerNew) {
            mrs_contractIdsForStatusUpdate.add(regItem.Contract__c);
        }
    }

    public void mrs_identifyContractsForStatusUpdate_Delete() {
        for (MeterRegistration__c regItem : triggerOld) {
            mrs_contractIdsForStatusUpdate.add(regItem.Contract__c);
        }
    }

    public void mrs_identifyContractsForStatusUpdate_Update() {
        for (MeterRegistration__c regItem : triggerNew) {
            if (regItem.Status__c != oldMap.get(regItem.Id).Status__c) {
                mrs_contractIdsForStatusUpdate.add(regItem.Contract__c);
            }
        }
    }

    public void mrs_buildMeterRegStatusUpdateDataModel() {
        for (Contract__c contractItem : contractMap.values()) {
            if (mrs_contractIdsForStatusUpdate.contains(contractItem.Id)
                    && (contractItem.Workflow_Type__c == 'New'
                    || contractItem.Workflow_Type__c == 'Reactivation')
                    && contractItem.Country__c == 'Germany'
                    && contractItem.RecordTypeId == PPA_CONTRACT_RECORD_TYPE) {
                for (MeterRegistration__c regItem : contractItem.Meter_Registrations__r) {
                    mrs_contractIdsToStatusUpdateMeterRegs.addToMap(contractItem.Id, regItem);
                }
            }
        }
    }

    public void mrs_updateContractRegStatusIfRelevantChange(MeterRegistration__c oldMeterRegistration, MeterRegistration__c newMeterRegistration) {
        if (newMeterRegistration.Status__c != oldMeterRegistration.Status__c) {
            mrs_updateContractRegStatus(newMeterRegistration);
        }
    }

    public void mrs_updateContractRegStatus(MeterRegistration__c regItem) {
        if (mrs_contractIdsToStatusUpdateMeterRegs.containsKey(regItem.Contract__c)) {
            Contract__c contractToSetStatusTo = contractMap.get(regItem.Contract__c);
            String lowestStatus = 'N/A';
            List<MeterRegistration__c> meterRegistrationsToInspect = mrs_contractIdsToStatusUpdateMeterRegs.get(contractToSetStatusTo.Id);
            for (MeterRegistration__c regItemForStatusUpdate : meterRegistrationsToInspect) {
                switch on regItemForStatusUpdate.Status__c {
                    when 'Pending' {
                        lowestStatus = 'Pending';
                    }
                    when 'In Progress' {
                        if (lowestStatus != 'Pending') {
                            lowestStatus = 'In Progress';
                        }
                    }
                    when 'Registration rejected' {
                        if (lowestStatus != 'Pending' && lowestStatus != 'In Progress') {
                            lowestStatus = 'Registration rejected';
                        }
                    }
                    when 'Completed' {
                        if (lowestStatus != 'Pending' && lowestStatus != 'In Progress' && lowestStatus != 'Registration rejected') {
                            lowestStatus = 'Completed';
                        }
                    }
                }
            }
            String label = null;
            for (Schema.PicklistEntry entry : statusEntries) {
                if (entry.getValue() == lowestStatus) {
                    label = entry.getLabel();
                }
            }
            contractToSetStatusTo.Meter_Registration_Status__c = Datetime.now().format('dd.MM.yyyy', '') + ' - ' + label;
            contractUpdateMap.put(contractToSetStatusTo.Id, contractToSetStatusTo);
        }
    }

    //Balancing Circle Lookup methods
    public void bcl_determineIfBalancingCirclesNeedToBeLoadedOnInsert() {
        for (MeterRegistration__c newRegItem : triggerNew) {
            if ((newRegItem.Balancing_Circle__c != null && newRegItem.Balancing_Circle__c != '')
                    || newRegItem.Balancing_Circle_Lookup__c != null) {
                bcl_isBalancingCircleUpdateRelevant = true;
            }
        }
    }

    public void bcl_determineIfBalancingCirclesNeedToBeLoadedOnUpdate() {
        for (MeterRegistration__c newRegItem : triggerNew) {
            if (newRegItem.Balancing_Circle__c != oldMap.get(newRegItem.Id).Balancing_Circle__c
                    || newRegItem.Balancing_Circle_Lookup__c != oldMap.get(newRegItem.Id).Balancing_Circle_Lookup__c) {
                bcl_isBalancingCircleUpdateRelevant = true;
            }
        }
    }

    public void bcl_matchPicklistWithLookupForBalancingCircleOnInsert(MeterRegistration__c newMeterRegistration) {
        if (newMeterRegistration.Balancing_Circle__c == null || newMeterRegistration.Balancing_Circle__c == '') {
            newMeterRegistration.Balancing_Circle_Lookup__c = null;
        } else {
            bcl_matchOrThrowErrorForBalancingCircle(newMeterRegistration);
        }
    }

    public void bcl_matchPicklistWithLookupForBalancingCircleOnUpdate(
            MeterRegistration__c oldMeterRegistration, MeterRegistration__c newMeterRegistration) {
        if (newMeterRegistration.Balancing_Circle__c == null || newMeterRegistration.Balancing_Circle__c == '') {
            newMeterRegistration.Balancing_Circle_Lookup__c = null;
        } else if (oldMeterRegistration.Balancing_Circle__c != newMeterRegistration.Balancing_Circle__c
                || oldMeterRegistration.Balancing_Circle_Lookup__c != newMeterRegistration.Balancing_Circle_Lookup__c) {
            bcl_matchOrThrowErrorForBalancingCircle(newMeterRegistration);
        }
    }

    private void bcl_matchOrThrowErrorForBalancingCircle(MeterRegistration__c newMeterRegistration) {
        if (bcl_balancingCirclesByNameMap.get(newMeterRegistration.Balancing_Circle__c) == null) {
            newMeterRegistration.addError(Label.validationErrorBalancingCircleRecordNotFound);
        } else {
            newMeterRegistration.Balancing_Circle_Lookup__c = bcl_balancingCirclesByNameMap.get(newMeterRegistration.Balancing_Circle__c).Id;
        }
    }

    public void bcl_buildBalancingCircleMappingToNames() {
        for (Balancing_Circle__c balCircleItem : balancingCircleMap.values()) {
            bcl_balancingCirclesByNameMap.put(balCircleItem.Name, balCircleItem);
        }
    }

    //Remit Relevancy Check methods
    public void rrc_identifyContractIds_Insert() {
        for (MeterRegistration__c regItemToCheckForRemitUpdate : triggerNew) {
            rrc_contractIds.add(regItemToCheckForRemitUpdate.Contract__c);
        }
    }

    public void rrc_identifyContractIds_Delete() {
        for (MeterRegistration__c regItemToCheckForRemitUpdate : triggerOld) {
            rrc_contractIds.add(regItemToCheckForRemitUpdate.Contract__c);
        }
    }

    public void rrc_identifyContractIds_Update() {
        for (MeterRegistration__c regItemToCheckForRemitUpdate : triggerNew) {
            if (regItemToCheckForRemitUpdate.Active__c != oldMap.get(regItemToCheckForRemitUpdate.Id).Active__c) {
                rrc_contractIds.add(regItemToCheckForRemitUpdate.Contract__c);
            }
        }
    }

    public void rrc_createRemitRelevancyDataModel() {
        for (Contract__c contractItem : contractMap.values()) {
            if (rrc_contractIds.contains(contractItem.Id)) {
                for (MeterRegistration__c regItem : contractItem.Meter_Registrations__r) {
                    if (regItem.Active__c
                            && !rrc_INACTIVE_METER_STATUS.contains(regItem.Meter__r.Status__c)) {
                        rrc_contractIdToMeterRegsOfActiveMeters.addToMap(contractItem.Id, regItem);
                    }
                }
            }
        }
    }

    public void rrc_setAndUpdateContractRemitRelevancy(MeterRegistration__c newMeterRegistration) {
        Contract__c contractToCheckForRemitUpdate = contractMap.get(newMeterRegistration.Contract__c);
        Boolean remitRelevancyBeforeCheck = contractToCheckForRemitUpdate.REMIT_Reporting_Relevant__c;
        msContractHelper.checkRemitRelevancy(contractToCheckForRemitUpdate, rrc_contractIdToMeterRegsOfActiveMeters.containsKey(contractToCheckForRemitUpdate.Id));
        if (remitRelevancyBeforeCheck != contractToCheckForRemitUpdate.REMIT_Reporting_Relevant__c) {
            contractUpdateMap.put(contractToCheckForRemitUpdate.Id, contractToCheckForRemitUpdate);
        }
    }

    public void rrc_checkSetAndUpdateContractRemitRelevancy(MeterRegistration__c oldMeterRegistration, MeterRegistration__c newMeterRegistration) {
        if (newMeterRegistration.Active__c != oldMeterRegistration.Active__c) {
            rrc_setAndUpdateContractRemitRelevancy(newMeterRegistration);
        }
    }

    //Capacity and Production methods
    public void cap_identifyContractsForCalculation_Insert() {
        for (MeterRegistration__c regItem : triggerNew) {
            if (regItem.Active__c) {
                cap_contractIdsToUpdate.add(regItem.Contract__c);
            }
        }
    }

    public void cap_identifyContractsForCalculation_Delete() {
        for (MeterRegistration__c regItem : triggerOld) {
            if (regItem.Active__c) {
                cap_contractIdsToUpdate.add(regItem.Contract__c);
            }
        }
    }

    public void cap_identifyContractsForCalculation_Update() {
        for (MeterRegistration__c regItem : triggerNew) {
            if (cap_isRelevantlyChanged(oldMap.get(regItem.Id), regItem)) {
                cap_contractIdsToUpdate.add(regItem.Contract__c);
                cap_contractIdsToUpdate.add(oldMap.get(regItem.Id).Contract__c);
            }
        }
    }

    private Boolean cap_isRelevantlyChanged(MeterRegistration__c oldReg, MeterRegistration__c newReg) {
        return oldReg.Active__c != newReg.Active__c
                || oldReg.Contract__c != newReg.Contract__c
                || oldReg.Meter__c != newReg.Meter__c
                || oldReg.Volume_Share__c != newReg.Volume_Share__c;
    }

    public void cap_buildDataModel() {
        for (Id contractId : cap_contractIdsToUpdate) {
            for (MeterRegistration__c regItem : contractMap.get(contractId).Meter_Registrations__r) {
                if (regItem.Active__c) {
                    cap_contractIdToMeterRegs.addToMap(contractId, regItem);
                }
            }
        }
    }

    public void cap_checkForContractUpdate(MeterRegistration__c registration) {
        if (registration.Active__c) {
            cap_updateContract(registration);
        }
    }

    public void cap_checkForContractUpdate(MeterRegistration__c oldRegistration, MeterRegistration__c newRegistration) {
        if (cap_isRelevantlyChanged(oldRegistration, newRegistration)) {
            if (oldRegistration.Contract__c != newRegistration.Contract__c) {
                cap_updateContract(oldRegistration);
            }
            cap_updateContract(newRegistration);
        }
    }

    private void cap_updateContract(MeterRegistration__c registration) {
        List<MeterRegistration__c> activeRegsOnContract = cap_contractIdToMeterRegs.get(registration.Contract__c);
        if (activeRegsOnContract == null) {
            activeRegsOnContract = new List<MeterRegistration__c>();
        }
        Contract__c contractToUpdate = contractMap.get(registration.Contract__c);
        if(cap_calculateContractValues(contractToUpdate, activeRegsOnContract)) {
            contractUpdateMap.put(contractToUpdate.Id, contractToUpdate);
        }
    }

    //Warning used by other class: msMeterHelper
    //Returns true if update happened
    public static Boolean cap_calculateContractValues(Contract__c contractToUpdate, List<MeterRegistration__c> activeRegsOnContract) {
        Boolean result = false;
        Decimal capacity = 0;
        Decimal production = 0;
        for (MeterRegistration__c regItem : activeRegsOnContract) {
            capacity += regItem.Installed_Capacity__c;
            production += regItem.Annual_Production__c;
        }
        if (contractToUpdate.Contracted_Capacity__c != capacity
                || contractToUpdate.Contracted_Annual_Production__c != production) {
            contractToUpdate.Contracted_Capacity__c = capacity;
            contractToUpdate.Contracted_Annual_Production__c = production;
            result = true;
        }
        return result;
    }
}
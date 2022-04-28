/****************************************************************************************************
* Class msMeterHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-08-19
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare AG)	            2021-08-19       	Init version.
*****************************************************************************************************/

public without sharing class msMeterHelper {
    private List<Meter__c> triggerOld;
    private List<Meter__c> triggerNew;
    private Map<Id, Meter__c> oldMap;
    private Map<Id, Meter__c> newMap;

    public msMeterHelper(
            List<Meter__c> oldList,
            List<Meter__c> newList,
            Map<Id, Meter__c> mapOld,
            Map<Id, Meter__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
        rrc_initialize();
    }

    //SOQL Maps
    private Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
    private Map<Id, Contract_Role__c> contractRoleMap = new Map<Id, Contract_Role__c>();
    private Map<Id, Meter__c> meterMap = new Map<Id, Meter__c>();
    private Map<Id, MeterRegistration__c> meterRegistrationMap = new Map<Id, MeterRegistration__c>();


    //DML Lists/Maps
    public Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();
    public Map<Id, Contract_Role__c> contractRoleUpdateMap = new Map<Id, Contract_Role__c>();
    public Map<Id, Meter__c> meterUpdateMap = new Map<Id, Meter__c>();

    //SOQL Methods
    public void load_Contracts() {
        if (!cap_contractsToUpdateIds.isEmpty()
                || !rrc_contractIdsToCheckForRemit.isEmpty()) {
            contractMap = new Map<Id, Contract__c>([
                    SELECT Id, Contracted_Capacity__c, Contracted_Annual_Production__c,Start_Date__c, Active_Installed_Capacity__c,
                            REMIT_Reporting_Relevant__c, Contract_Type_New__c, Product_Type_New__c, Legal_Capacity__c,
                            Country__c, Third_Party_Contract__c, (
                            SELECT Id, Active__c, Installed_Capacity__c, Annual_Production__c, Meter__r.Status__c
                            FROM Meter_Registrations__r
                    )
                    FROM Contract__c
                    WHERE Id IN :cap_contractsToUpdateIds
                    OR Id IN :rrc_contractIdsToCheckForRemit
            ]);
        }
    }

    public void load_ContractRoles() {
        if (!crr_contractIds.isEmpty()) {
            contractRoleMap = new Map<Id, Contract_Role__c>([
                    SELECT Id, Name, Contract__c
                    FROM Contract_Role__c
                    WHERE Contract__c IN :crr_contractIds
            ]);
        }
    }

    public void load_Meters() {
        if (fil_isControllableUnitSetupRelevant
                || !cap_relevantParentMeterIds.isEmpty()) {
            meterMap = new Map<Id, Meter__c>([
                    SELECT Controllable_Unit_ID__c, Installed_Capacity_of_Child_Meters__c, Installed_Capacity__c,
                            Country__c, Status__c, Parent_Meter__c
                    FROM Meter__c
                    WHERE (Country__c = 'France'
                    AND Controllable_Unit_ID__c != NULL
                    AND Controllable_Unit_ID__c != '')
                    OR (Id IN :cap_relevantParentMeterIds
                    OR Parent_Meter__c IN :cap_relevantParentMeterIds)
            ]);
        }
    }

    public void load_MeterRegs() {
        if (!cap_relevantMeterIds.isEmpty()
                || !crr_meterIds.isEmpty()
                || !rrc_meterToCheckForRemitIds.isEmpty()) {
            meterRegistrationMap = new Map<Id, MeterRegistration__c>([
                    SELECT Id, Installed_Capacity__c, Annual_Production__c, Contract__c, Meter__c, Active__c
                    FROM MeterRegistration__c
                    WHERE Meter__c IN :cap_relevantMeterIds
                    OR Meter__c IN :crr_meterIds
                    OR Meter__c IN :rrc_meterToCheckForRemitIds
            ]);
        }
    }

    //Capacity and Production variables
    private Set<Id> cap_relevantMeterIds = new Set<Id>();
    private Set<Id> cap_relevantParentMeterIds = new Set<Id>();
    private Set<Id> cap_contractsToUpdateIds = new Set<Id>();
    private Map<Id, Set<Id>> cap_meterIdToContractIds = new Map<Id, Set<Id>>();
    private ListMapContainer cap_contractIdToMeterRegs = new ListMapContainer(MeterRegistration__c.SObjectType);
    private ListMapContainer cap_parentMeterIdToChildren = new ListMapContainer(Meter__c.SObjectType);

    //France Id logic variables
    private Boolean fil_isControllableUnitSetupRelevant = false;
    private Integer fil_highestCounter = 0;
    private Map<Integer, Id> fil_countersInTheSystem = new Map<Integer, Id>();

    //Contract Role Renaming variables
    private Set<Id> crr_meterIds = new Set<Id>();
    private Set<Id> crr_contractIds = new Set<Id>();
    private Map<Id, Set<Id>> crr_meterIdToContractIds = new Map<Id, Set<Id>>();
    private ListMapContainer crr_contractIdToContractRoles = new ListMapContainer(Contract_Role__c.SObjectType);

    //Remit Relevancy Check variables
    private Set<Id> rrc_meterToCheckForRemitIds = new Set<Id>();
    private Set<Id> rrc_contractIdsToCheckForRemit = new Set<Id>();
    private Map<Id, Set<Id>> rrc_meterIdContractIds = new Map<Id, Set<Id>>();
    private Set<String> rrc_inactiveStatusSet = new Set<String>();
    private Set<String> rrc_activeStatusSet = new Set<String>();


    //Capacity and Production methods
    public void cap_identifyMeters() {
        for (Meter__c newMeter : triggerNew) {
            if (cap_isRelevantChange(oldMap.get(newMeter.Id), newMeter)) {
                cap_relevantMeterIds.add(newMeter.Id);
            }
        }
    }

    public void cap_identifyRelevantParents_Insert() {
        for (Meter__c newMeter : triggerNew) {
            if (newMeter.Parent_Meter__c != null) {
                cap_relevantParentMeterIds.add(newMeter.Parent_Meter__c);
            }
        }
    }

    public void cap_identifyRelevantParents_Delete() {
        for (Meter__c deletedMeter : triggerOld) {
            if (deletedMeter.Parent_Meter__c != null) {
                cap_relevantParentMeterIds.add(deletedMeter.Parent_Meter__c);
            }
        }
    }

    public void cap_identifyRelevantParents_Update() {
        for (Meter__c newMeter : triggerNew) {
            Meter__c oldMeter = oldMap.get(newMeter.Id);
            if (cap_newMeterUpdatesParent_Update(oldMeter, newMeter)) {
                if(oldMeter.Parent_Meter__c != null) {
                    cap_relevantParentMeterIds.add(oldMap.get(newMeter.Id).Parent_Meter__c);
                }
                if(newMeter.Parent_Meter__c != null) {
                    cap_relevantParentMeterIds.add(newMeter.Parent_Meter__c);
                }
            }
        }
    }

    private Boolean cap_newMeterUpdatesParent_Update(Meter__c oldMeter, Meter__c newMeter) {
        return oldMeter.Parent_Meter__c != newMeter.Parent_Meter__c
                || oldMeter.Installed_Capacity__c != newMeter.Installed_Capacity__c;
    }

    public void cap_updateParent(Meter__c meter) {
        if (meter.Parent_Meter__c != null) {
            cap_handleParentUpdate(meter);
        }
    }

    public void cap_updateParents(Meter__c oldMeter, Meter__c newMeter) {
        if (cap_newMeterUpdatesParent_Update(oldMeter, newMeter)) {
            if (newMeter.Parent_Meter__c != null) {
                cap_handleParentUpdate(newMeter);
            }
            if (oldMeter.Parent_Meter__c != newMeter.Parent_Meter__c) {
                if (oldMeter.Parent_Meter__c != null) {
                    cap_handleParentUpdate(oldMeter);
                }
            }
        }
    }

    private void cap_handleParentUpdate(Meter__c childMeter) {
        Meter__c parent = meterMap.get(childMeter.Parent_Meter__c);
        List<Meter__c> children = cap_parentMeterIdToChildren.get(childMeter.Parent_Meter__c);
        if (cap_calculateMeterUpdate(parent, children)) {
            meterUpdateMap.put(parent.Id, parent);
        }
    }

    private Boolean cap_calculateMeterUpdate(Meter__c meterToUpdate, List<Meter__c> children) {
        Boolean result = false;
        if (children == null) {
            children = new List<Meter__c>();
        }
        Decimal capacity = 0;
        for (Meter__c child : children) {
            capacity += child.Installed_Capacity__c;
        }
        if (meterToUpdate.Installed_Capacity_of_Child_Meters__c != capacity) {
            meterToUpdate.Installed_Capacity_of_Child_Meters__c = capacity;
            result = true;
        }
        return result;
    }

    private Boolean cap_isRelevantChange(Meter__c oldMeter, Meter__c newMeter) {
        return oldMeter.Installed_Capacity_total__c != newMeter.Installed_Capacity_total__c
                || oldMeter.Annual_Production_total__c != newMeter.Annual_Production_total__c;
    }

    public void cap_identifyContracts() {
        if (!cap_relevantMeterIds.isEmpty() && !meterRegistrationMap.isEmpty()) {
            for (MeterRegistration__c regItem : meterRegistrationMap.values()) {
                if (regItem.Active__c
                        && cap_relevantMeterIds.contains(regItem.Meter__c)) {
                    cap_contractsToUpdateIds.add(regItem.Contract__c);
                    msLepton.addToMap(regItem.Meter__c, regItem.Contract__c, cap_meterIdToContractIds);
                }
            }
        }
    }

    public void cap_buildDataModel() {
        if (!cap_contractsToUpdateIds.isEmpty()) {
            for (Id contractId : cap_contractsToUpdateIds) {
                for (MeterRegistration__c regItem : contractMap.get(contractId).Meter_Registrations__r) {
                    if (regItem.Active__c) {
                        cap_contractIdToMeterRegs.addToMap(contractId, regItem);
                    }
                }
            }
        }

        if (!cap_relevantParentMeterIds.isEmpty()) {
            for (Meter__c meterToSort : meterMap.values()) {
                if (cap_relevantParentMeterIds.contains(meterToSort.Parent_Meter__c)) {
                    cap_parentMeterIdToChildren.addToMap(meterToSort.Parent_Meter__c, meterToSort);
                }
            }
        }
    }

    public void cap_prepareContractUpdates(Meter__c oldMeter, Meter__c newMeter) {
        if (cap_isRelevantChange(oldMeter, newMeter)) {
            Set<Id> contractIds = cap_meterIdToContractIds.get(newMeter.Id);
            if (contractIds != null) {
                for (Id contractId : contractIds) {
                    Contract__c contractToUpdate = contractMap.get(contractId);
                    List<MeterRegistration__c> registrations = cap_contractIdToMeterRegs.get(contractId);
                    if (msMeterRegistrationHelper.cap_calculateContractValues(contractToUpdate, registrations)) {
                        contractUpdateMap.put(contractToUpdate.Id, contractToUpdate);
                    }
                }
            }
        }
    }

    //EMSYS population logic methods
    public void epl_ensureEMSYS_Insert(Meter__c meter) {
        if (meter.Portfolio_ID__c != null && meter.EMSYS_ID__c == null) {
            meter.EMSYS_ID__c = meter.Portfolio_ID__c;
        }
    }

    public void epl_ensureEMSYS_Update(Meter__c oldMeter, Meter__c newMeter) {
        if (oldMeter.EMSYS_ID__c == null && newMeter.EMSYS_ID__c == null) {
            if (newMeter.Portfolio_ID__c != null && oldMeter.Portfolio_ID__c != newMeter.Portfolio_ID__c) {
                newMeter.EMSYS_ID__c = newMeter.Portfolio_ID__c;
            }
        } else if (oldMeter.EMSYS_ID__c != null && newMeter.EMSYS_ID__c != oldMeter.EMSYS_ID__c) {
            newMeter.addError(Label.validationErrorMeterEmsysIdChanged);
        }
    }

    //France Id logic methods
    public void fil_checkIfRelevant() {
        for (Meter__c newMeter : triggerNew) {
            if (fil_isRelevant(newMeter)) {
                fil_isControllableUnitSetupRelevant = true;
                break;
            }
        }
    }

    public void fil_buildDataModel() {
        if (fil_isControllableUnitSetupRelevant) {
            for (Meter__c meterWithContUnitIdToCount : meterMap.values()) {
                if (fil_isRelevant(meterWithContUnitIdToCount)
                        && meterWithContUnitIdToCount.Controllable_Unit_ID__c != null
                        && meterWithContUnitIdToCount.Controllable_Unit_ID__c != ''
                        && meterWithContUnitIdToCount.Controllable_Unit_ID__c.isNumeric()) {
                    Integer currentCounter = Integer.valueOf(meterWithContUnitIdToCount.Controllable_Unit_ID__c);
                    fil_highestCounter = Math.max(fil_highestCounter, currentCounter);
                    fil_countersInTheSystem.put(currentCounter, meterWithContUnitIdToCount.Id);
                }
            }
        }
    }

    public void fil_populateIds(Meter__c meter) {
        if (fil_isRelevant(meter)) {
            meter.Meter_ID__c = meter.Alternative_Meter_ID__c;
            if (meter.Controllable_Unit_ID__c == null
                    || meter.Controllable_Unit_ID__c == '') {
                meter.Controllable_Unit_ID__c = fil_generateControllableUnitId();
            } else {
                fil_checkForDuplicatesAndListNewEntries(meter);
            }
        }
    }

    private Boolean fil_isRelevant(Meter__c meter) {
        return meter.Country__c == 'France';
    }

    private String fil_generateControllableUnitId() {
        fil_highestCounter++;
        String controllable_Unit_ID = fil_highestCounter + '';
        for (Integer i = controllable_Unit_ID.length(); i < 5; i++) {
            controllable_Unit_ID = '0' + controllable_Unit_ID;
        }
        return controllable_Unit_ID;
    }

    private void fil_checkForDuplicatesAndListNewEntries(Meter__c meter) {
        if (meter.Controllable_Unit_ID__c.isNumeric()) {
            Integer counter = Integer.valueOf(meter.Controllable_Unit_ID__c);
            if (fil_countersInTheSystem.containsKey(counter)
                    && meter.Id != fil_countersInTheSystem.get(counter)) {
                meter.addError(Label.validationErrorMeterContUnitIdDuplicate);
            } else {
                fil_countersInTheSystem.put(counter, meter.Id);
                fil_highestCounter = Math.max(fil_highestCounter, counter);
            }
        }
    }

    //Contract Role renaming methods
    public void crr_identifyMeters() {
        for (Meter__c newMeter : triggerNew) {
            if (crr_isRelevantChange(oldMap.get(newMeter.Id), newMeter)) {
                crr_meterIds.add(newMeter.Id);
            }
        }
    }

    private Boolean crr_isRelevantChange(Meter__c oldMeter, Meter__c newMeter) {
        return oldMeter.Name != newMeter.Name;
    }

    public void crr_identifyContracts() {
        if (!crr_meterIds.isEmpty()) {
            for (MeterRegistration__c regItem : meterRegistrationMap.values()) {
                if (regItem.Active__c
                        && crr_meterIds.contains(regItem.Meter__c)) {
                    msLepton.addToMap(regItem.Meter__c, regItem.Contract__c, crr_meterIdToContractIds);
                    crr_contractIds.add(regItem.Contract__c);
                }
            }
        }
    }

    public void crr_buildDataModel() {
        if (!crr_contractIds.isEmpty() && !contractRoleMap.isEmpty()) {
            for (Contract_Role__c roleItem : contractRoleMap.values()) {
                if (crr_contractIds.contains(roleItem.Contract__c)) {
                    crr_contractIdToContractRoles.addToMap(roleItem.Contract__c, roleItem);
                }
            }
        }
    }

    public void crr_renameContractRolesIfNecessary(Meter__c oldMeter, Meter__c newMeter) {
        if (crr_isRelevantChange(oldMeter, newMeter)) {
            crr_renameContractRoles(newMeter);
        }
    }

    public void crr_renameContractRoles(Meter__c meter) {
        Set<Id> contractIds = crr_meterIdToContractIds.get(meter.Id);
        if (contractIds != null) {
            for (Id contractId : contractIds) {
                List<Contract_Role__c> contractRoles = crr_contractIdToContractRoles.get(contractId);
                if (contractRoles != null) {
                    for (Contract_Role__c roleItem : contractRoles) {
                        if (roleItem.Name != 'Reinitialize') {
                            roleItem.Name = 'Reinitialize';
                            contractRoleUpdateMap.put(roleItem.Id, roleItem);
                        }
                    }
                }
            }
        }
    }

    //Remit Relevancy Check methods
    private void rrc_initialize() {
        rrc_inactiveStatusSet.add('Planned');
        rrc_inactiveStatusSet.add('Under Construction');
        rrc_activeStatusSet.add(null);
        rrc_activeStatusSet.add('Active');
        rrc_activeStatusSet.add('Retired');
    }

    private Boolean rrc_isStatusClassSwitched(Meter__c oldMeter, Meter__c newMeter) {
        return (rrc_inactiveStatusSet.contains(oldMeter.Status__c) && rrc_activeStatusSet.contains(newMeter.Status__c))
                || (rrc_activeStatusSet.contains(oldMeter.Status__c) && rrc_inactiveStatusSet.contains(newMeter.Status__c));
    }

    public void rrc_identifyMeters() {
        for (Meter__c newMeter : triggerNew) {
            if (rrc_isStatusClassSwitched(oldMap.get(newMeter.Id), newMeter)) {
                rrc_meterToCheckForRemitIds.add(newMeter.Id);
            }
        }
    }

    public void rrc_identifyContracts() {
        if (!rrc_meterToCheckForRemitIds.isEmpty() && !meterRegistrationMap.isEmpty()) {
            for (MeterRegistration__c regItem : meterRegistrationMap.values()) {
                if (regItem.Active__c && rrc_meterToCheckForRemitIds.contains(regItem.Meter__c)) {
                    rrc_contractIdsToCheckForRemit.add(regItem.Contract__c);
                    msLepton.addToMap(regItem.Meter__c, regItem.Contract__c, rrc_meterIdContractIds);
                }
            }
        }
    }

    public void rrc_checkMeterContractForRemitUpdate(Meter__c oldMeter, Meter__c newMeter) {
        if (rrc_isStatusClassSwitched(oldMeter, newMeter)) {
            Set<Id> contractIds = rrc_meterIdContractIds.get(newMeter.Id);
            if (contractIds != null) {
                for (Id contractId : contractIds) {
                    Contract__c contractToCheckForRemitUpdate = contractMap.get(contractId);
                    Boolean remitRelevancyBeforeCheck = contractToCheckForRemitUpdate.REMIT_Reporting_Relevant__c;
                    if (!(contractToCheckForRemitUpdate.Country__c != 'Germany' && remitRelevancyBeforeCheck)) {
                        Boolean contractHasActiveMeters = false;
                        for (MeterRegistration__c regItem : contractToCheckForRemitUpdate.Meter_Registrations__r) {
                            if (rrc_activeStatusSet.contains(regItem.Meter__r.Status__c)) {
                                contractHasActiveMeters = true;
                            }
                        }
                        msContractHelper.checkRemitRelevancy(contractToCheckForRemitUpdate, contractHasActiveMeters);
                        if (remitRelevancyBeforeCheck != contractToCheckForRemitUpdate.REMIT_Reporting_Relevant__c) {
                            contractUpdateMap.put(contractToCheckForRemitUpdate.Id, contractToCheckForRemitUpdate);
                        }
                    }
                }
            }
        }
    }
}
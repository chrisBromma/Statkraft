/****************************************************************************************************
* Class BatchCalculateCapAndProdOnContracts
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-05-26
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-05-26       	Init version.
*****************************************************************************************************/

global without sharing class BatchCalculateCapAndProdOnContracts
        extends BatchJobBase
        implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    private static final List<Schema.FieldSetMember> capAndProdFields = SObjectType.Contract__c.fieldSets.Capacity_and_Production_Fields.getFields();
    global BatchCalculateCapAndProdOnContracts() {
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        super.startLogging(batchableContext?.getJobId());
        String fieldQuery = getFieldQuery();
        return Database.getQueryLocator(
                'SELECT ' +
                        'Id, Country__c, Product_Type_New__c, Contract_Type_New__c ' +
                        fieldQuery +
                        ' FROM Contract__c ' +
                        'WHERE Parent_Contract__c = NULL');
    }

    global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        Set<Id> parentContractIds = new Set<Id>();
        for (Contract__c contractItem : (List<Contract__c>) scope) {
            parentContractIds.add(contractItem.Id);
        }
        ListMapContainer parentIdToChildContracts = queryChildContracts(parentContractIds);
        Set<Id> allContractIds = getAllContractIds(parentContractIds, parentIdToChildContracts);
        ListMapContainer contractIdToAssignments = queryAssignments(allContractIds);
        Map<Id, Contract__c> contractUpdateMap = checkForUpdate((List<Contract__c>) scope, parentIdToChildContracts, contractIdToAssignments);
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        if (!contractUpdateMap.isEmpty()) {
            results = Database.update(contractUpdateMap.values(), false);
            System.debug(results);
        }
        String comment = msLepton.generateCommentFromSaveResults(results);
        Boolean isSuccess = false;
        if (comment == Label.batchLoggingSuccessMessage) {
            isSuccess = true;
        }
        super.logEndOfBatch(scope, batchableContext.getJobId(), isSuccess, comment);
    }

    global void finish(Database.BatchableContext batchableContext) {
        super.finishBatch(batchableContext.getJobId());
    }

    //TODO: It is a bit messy to query Contracts twice, triggers are calling this. The class might need a rework because of this
    public static List<Database.SaveResult> checkForUpdateAndExecuteUpdate(Set<Id> contractIds) {
        List<Contract__c> contractParentsToCheck = queryParentContracts(contractIds);
        Set<Id> parentIds = new Set<Id>();
        for (Contract__c parentContract : contractParentsToCheck) {
            parentIds.add(parentContract.Id);
        }
        ListMapContainer parentIdToChildContracts = queryChildContracts(parentIds);
        Set<Id> allContractIds = getAllContractIds(parentIds, parentIdToChildContracts);
        ListMapContainer contractIdToAssignments = queryAssignments(allContractIds);
        Map<Id, Contract__c> contractUpdateMap = checkForUpdate(contractParentsToCheck, parentIdToChildContracts, contractIdToAssignments);
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        if (!contractUpdateMap.isEmpty()) {
            results = Database.update(contractUpdateMap.values(), false);
        }
        return results;
    }

    public static Map<Id, Contract__c> checkForUpdate(List<Contract__c> parentContracts,
            ListMapContainer parentIdToChildContracts, ListMapContainer contractIdToAssignments) {
        Map<Id, Contract__c> contractUpdateMap = new Map<Id, Contract__c>();

        for (Contract__c parentContract : parentContracts) {
            List<Contract__c> childContracts = parentIdToChildContracts.get(parentContract.Id);
            for (Contract__c childContract : childContracts) {
                List<Generation_Unit_Assignment__c> childAssignments = contractIdToAssignments.get(childContract.Id);
                Contract__c possibleChildUpdate = calculateCapAndProdValues(childAssignments);
                if (isDifferent(childContract, possibleChildUpdate)) {
                    passValues(childContract, possibleChildUpdate);
                    contractUpdateMap.put(childContract.Id, childContract);
                }
            }
            List<Generation_Unit_Assignment__c> parentAssignments = contractIdToAssignments.get(parentContract.Id);
            Contract__c possibleUpdate = calculateCapAndProdValues(parentAssignments);
            if (parentContract.Country__c == 'Germany') {
                aggregateChildrenOnTop(possibleUpdate, childContracts);
            }
            if (isDifferent(parentContract, possibleUpdate)) {
                passValues(parentContract, possibleUpdate);
                contractUpdateMap.put(parentContract.Id, parentContract);
            }
        }
        return contractUpdateMap;
    }

    private static Set<Id> getAllContractIds(Set<Id> parentIds, ListMapContainer parentIdToChildContracts) {
        Set<Id> allContractIds = new Set<Id>();
        allContractIds.addAll(parentIds);
        for (Id parentId : parentIdToChildContracts.keySet()) {
            List<Contract__c> childContracts = parentIdToChildContracts.get(parentId);
            for (Contract__c childContract : childContracts) {
                allContractIds.add(childContract.Id);
            }
        }
        return allContractIds;
    }

    private static ListMapContainer queryChildContracts(Set<Id> parentIds) {
        String fieldQuery = getFieldQuery();
        List<Contract__c> childContracts = Database.query(
                'SELECT ' +
                        'Id, Country__c, Product_Type_New__c, Contract_Type_New__c, Parent_Contract__c' +
                        fieldQuery +
                        ' FROM Contract__c ' +
                        'WHERE Parent_Contract__c IN :parentIds');
        ListMapContainer parentIdToChildContracts = new ListMapContainer(Contract__c.SObjectType);
        for (Contract__c childContract : childContracts) {
            parentIdToChildContracts.addToMap(childContract.Parent_Contract__c, childContract);
        }
        return parentIdToChildContracts;
    }

    private static void aggregateChildrenOnTop(Contract__c parentContract, List<Contract__c> childContracts) {
        for (Contract__c childUpdate : childContracts) {
            if (!(childUpdate.Contract_Type_New__c == 'Supply' && childUpdate.Product_Type_New__c == 'Bezugsstrom')) {
                parentContract.Installed_Capacity__c += childUpdate.Installed_Capacity__c;
                parentContract.Installed_Annual_Production__c += childUpdate.Installed_Annual_Production__c;
                parentContract.Active_Installed_Capacity__c += childUpdate.Active_Installed_Capacity__c;
                parentContract.Active_Installed_Annual_Production__c += childUpdate.Active_Installed_Annual_Production__c;
                parentContract.Active_Installed_Capacity_Conga__c += childUpdate.Active_Installed_Capacity_Conga__c;
                parentContract.Active_Installed_Production_Conga__c += childUpdate.Active_Installed_Production_Conga__c;
            }
        }
    }

    private static Contract__c calculateCapAndProdValues(List<Generation_Unit_Assignment__c> assignments) {
        Contract__c contractCalculated = new Contract__c();
        for (Schema.FieldSetMember field : capAndProdFields) {
            contractCalculated.put(field.getFieldPath(), 0);
        }

        Set<Id> countedGenerators = new Set<Id>();
        Set<Id> countedActiveGenerators = new Set<Id>();
        Set<Id> countedCongaActiveGenerators = new Set<Id>();
        for (Generation_Unit_Assignment__c assignmentItem : assignments) {
            if (!countedGenerators.contains(assignmentItem.Generation_Unit__c)) {
                countedGenerators.add(assignmentItem.Generation_Unit__c);
                contractCalculated.Installed_Capacity__c += assignmentItem.Installed_Capacity__c;
                contractCalculated.Installed_Annual_Production__c += assignmentItem.Annual_Production__c;
            }
            if (assignmentItem.Active__c
                    && !countedActiveGenerators.contains(assignmentItem.Generation_Unit__c)) {
                countedActiveGenerators.add(assignmentItem.Generation_Unit__c);
                contractCalculated.Active_Installed_Capacity__c += assignmentItem.Installed_Capacity__c;
                contractCalculated.Active_Installed_Annual_Production__c += assignmentItem.Annual_Production__c;
            }
            if (assignmentItem.Active_for_Conga_Context__c
                    && !countedCongaActiveGenerators.contains(assignmentItem.Generation_Unit__c)) {
                countedCongaActiveGenerators.add(assignmentItem.Generation_Unit__c);
                contractCalculated.Active_Installed_Capacity_Conga__c += assignmentItem.Installed_Capacity__c;
                contractCalculated.Active_Installed_Production_Conga__c += assignmentItem.Annual_Production__c;
            }
        }
        return contractCalculated;
    }

    private static Boolean isDifferent(Contract__c oldContract, Contract__c newContract) {
        Boolean different = false;
        for (Schema.FieldSetMember field : capAndProdFields) {
            String fieldName = field.getFieldPath();
            if (oldContract.get(fieldName) != newContract.get(fieldName)) {
                different = true;
                break;
            }
        }
        return different;
    }

    private static List<Contract__c> queryParentContracts(Set<Id> contractIds) {
        String fieldQuery = getFieldQuery();
        Set<Id> parentIds = new Set<Id>();
        for (Contract__c childContract : [SELECT Parent_Contract__c FROM Contract__c WHERE Id IN :contractIds AND Parent_Contract__c != NULL]) {
            parentIds.add(childContract.Parent_Contract__c);
        }
        return Database.query('SELECT ' +
                'Id, Country__c, Product_Type_New__c, Contract_Type_New__c ' +
                fieldQuery +
                ' FROM Contract__c ' +
                'WHERE (Id IN :contractIds AND Parent_Contract__c = NULL) ' +
                'OR Id IN :parentIds');
    }

    private static ListMapContainer queryAssignments(Set<Id> contractIds) {
        ListMapContainer contractIdToAssignments = new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);
        List<Generation_Unit_Assignment__c> relevantAssignments = [
                SELECT Id,
                        Contract__c,
                        Installed_Capacity__c,
                        Annual_Production__c,
                        Active__c,
                        Active_for_Conga_Context__c,
                        Generation_Unit__c
                FROM Generation_Unit_Assignment__c
                WHERE Contract__c IN :contractIds
        ];
        for (Generation_Unit_Assignment__c assignmentItem : relevantAssignments) {
            contractIdToAssignments.addToMap(assignmentItem.Contract__c, assignmentItem);
        }
        return contractIdToAssignments;
    }

    public static void passValues(Contract__c target, Contract__c source) {
        for (Schema.FieldSetMember field : capAndProdFields) {
            String fieldName = field.getFieldPath();
            target.put(fieldName, source.get(fieldName));
        }
    }

    private static String getFieldQuery() {
        String fieldQuery = ', ';
        for (Schema.FieldSetMember field : capAndProdFields) {
            fieldQuery += field.getFieldPath() + ', ';
        }
        fieldQuery = fieldQuery.removeEnd(', ');
        return fieldQuery;
    }
}
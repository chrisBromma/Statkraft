/****************************************************************************************************
* Class BatchAssignGenerationUnits
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-04-09
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-04-09       	Init version.
*****************************************************************************************************/

global without sharing class BatchAssignGenerationUnits
        extends BatchJobBase
        implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    private static final String DATE_FORMAT_STRING = 'dd.MM.yyyy';
    global BatchAssignGenerationUnits() {
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        super.startLogging(bc?.getJobId());
        return Database.getQueryLocator('SELECT ' +
                'Id, Name ' +
                'FROM Generation_Unit__c');
    }

    global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        String comment = assignGenerationUnits((List<Generation_Unit__c>) scope);
        Boolean isSuccess = false;
        if (comment == Label.batchLoggingSuccessMessage) {
            isSuccess = true;
        }
        super.logEndOfBatch(scope, batchableContext.getJobId(), isSuccess, comment);
    }

    global void finish(Database.BatchableContext bc) {
        super.finishBatch(bc.getJobId());
    }

    public static void assignGenerationUnits(Set<Id> genUnitIds) {
        List<Generation_Unit__c> scope = [SELECT Id, Name FROM Generation_Unit__c WHERE Id IN :genUnitIds];
        assignGenerationUnits(scope);
    }

    private static String assignGenerationUnits(List<Generation_Unit__c> scope) {
        Map<Id, Generation_Unit__c> generatorMap = new Map<Id, Generation_Unit__c>(scope);
        Set<Id> genUnitIds = generatorMap.keySet();
        List<Generation_Unit_Assignment__c> assignmentsToInsert = new List<Generation_Unit_Assignment__c>();
        List<Generation_Unit_Assignment__c> assignmentsToDelete = new List<Generation_Unit_Assignment__c>();
        List<Generation_Unit_Assignment__c> assignmentsToUpdate = new List<Generation_Unit_Assignment__c>();

        //Loading all information that we need for the Assignment Calculations
        Map<Id, ListMapContainer> generatorIdToContractIdToListOfCurrentAssignments =
                loadCurrentAssignments(genUnitIds);
        ListMapContainer generatorIdToListOfOwnerships = loadOwnerships(genUnitIds);

        Set<Id> relevantMeterIds = new Set<Id>();
        ListMapContainer generatorIdToRelationships =
                new ListMapContainer(Meter2GenerationUnitRelationship__c.SObjectType);
        loadMeterConnections(genUnitIds, relevantMeterIds, generatorIdToRelationships);

        ListMapContainer meterIdToMeterRegsMap = loadMeterRegistrations(relevantMeterIds);

        for (Generation_Unit__c generatorToAssign : scope) {
            List<Meter2GenerationUnitRelationship__c> relationships = generatorIdToRelationships.get(generatorToAssign.Id);

            if (relationships.size() != 0) {
                //For the individual generator, we first calculate all time intersections of their M2G and Meter Reg connection to a Contract and group these per ContractId
                //The Assignments are sorted with ascending Start Dates
                ListMapContainer contractIdToAssignmentsBeforeMerge =
                        calculateUnmergedAssignmentTimeline(generatorToAssign, relationships, meterIdToMeterRegsMap);
                //Since we might have overlapping/tangent on the same contract via different Meters or consecutive junctions, we merge the assignments if applicable
                ListMapContainer contractIdToAssignmentsAfterMerge =
                        mergeIntersectingTimelineItems(contractIdToAssignmentsBeforeMerge);
                //During their Lifetime, Generation Unit Ownership might change, hence we split the timeline per contract based on the Ownership timeline
                ListMapContainer contractIdToAssignmentsAfterSplit =
                        splitAssignmentsBasedOnOwnershipTimeline(
                                contractIdToAssignmentsAfterMerge,
                                generatorIdToListOfOwnerships.get(generatorToAssign.Id)
                        );
                //In order to minimise workload on the recycle bin, we update the already established assignments as good as we can
                //If additional assignments are required, we prepare an insert
                //If the assignments drop out, we prepare a deletion
                //We try to make only reasonable changes and not switch the assignments MD-Lookup, hence this is performed for
                //each Contract-Generation Unit pair individually
                ListMapContainer contractIdToCurrentAssignments
                        = generatorIdToContractIdToListOfCurrentAssignments.get(generatorToAssign.Id);
                if (contractIdToCurrentAssignments == null) {
                    contractIdToCurrentAssignments = new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);
                }
                Set<Id> combinedContractIds = new Set<Id>();
                combinedContractIds.addAll(msLepton.castToSetId(contractIdToAssignmentsAfterMerge.keySet()));
                combinedContractIds.addAll(msLepton.castToSetId(contractIdToCurrentAssignments.keySet()));
                for (Id contractId : combinedContractIds) {
                    List<Generation_Unit_Assignment__c> splitAssignments = contractIdToAssignmentsAfterSplit.get(contractId);
                    List<Generation_Unit_Assignment__c> currentAssignments = contractIdToCurrentAssignments.get(contractId);
                    for (Integer i = 0; i < splitAssignments.size(); i++) {
                        if (i < currentAssignments.size()) {
                            if (currentAssignments[i].Start_Date__c != splitAssignments[i].Start_Date__c
                                    || currentAssignments[i].End_Date__c != splitAssignments[i].End_Date__c
                                    || currentAssignments[i].Generation_Unit_Ownership__c != splitAssignments[i].Generation_Unit_Ownership__c) {
                                splitAssignments[i].Id = currentAssignments[i].Id;
                                assignmentsToUpdate.add(splitAssignments[i]);
                            }
                        } else {
                            assignmentsToInsert.add(splitAssignments[i]);
                        }
                    }
                    if (splitAssignments.size() < currentAssignments.size()) {
                        if (splitAssignments.size() == 0) {
                            assignmentsToDelete.addAll(currentAssignments);
                        } else {
                            for (Integer i = splitAssignments.size(); i < currentAssignments.size(); i++) {
                                assignmentsToDelete.add(currentAssignments[i]);
                            }
                        }
                    }
                }
            } else {
                ListMapContainer contractIdToCurrentAssignments
                        = generatorIdToContractIdToListOfCurrentAssignments.get(generatorToAssign.Id);
                if (contractIdToCurrentAssignments != null) {
                    for (Id contractId : contractIdToCurrentAssignments.keySet()) {
                        List<Generation_Unit_Assignment__c> currentAssignments = contractIdToCurrentAssignments.get(contractId);
                        assignmentsToDelete.addAll(currentAssignments);
                    }
                }
            }
        }
        //Assignments should have a reasonable name, we try to avoid workload on the trigger here to speed up the operation
        nameAssignments(assignmentsToInsert, generatorMap);
        nameAssignments(assignmentsToUpdate, generatorMap);
        Set<Id> affectedContractIds = new Set<Id>();
        for (Generation_Unit_Assignment__c assignment : assignmentsToDelete) {
            affectedContractIds.add(assignment.Contract__c);
        }
        for (Generation_Unit_Assignment__c assignment : assignmentsToInsert) {
            affectedContractIds.add(assignment.Contract__c);
        }
        for (Generation_Unit_Assignment__c assignment : assignmentsToUpdate) {
            affectedContractIds.add(assignment.Contract__c);
        }
        delete assignmentsToDelete;
        insert assignmentsToInsert;
        update assignmentsToUpdate;
        //If there was an assignment change on a Contract, its Cap and Prod values need to be recalculated, again we try to avoid triggering this via apex trigger
        //to speed up cpu runtime and minimize queries
        List<Database.SaveResult> results = BatchCalculateCapAndProdOnContracts.checkForUpdateAndExecuteUpdate(affectedContractIds);
        return msLepton.generateCommentFromSaveResults(results);
    }

    private static Map<Id, ListMapContainer> loadCurrentAssignments(Set<Id> genUnitIds) {
        Map<Id, ListMapContainer> generatorIdToContractIdToListOfCurrentAssignments =
                new Map<Id, ListMapContainer>();
        for (Generation_Unit_Assignment__c assignmentItem : [
                SELECT Start_Date__c, End_Date__c, Generation_Unit__c, Contract__c, Generation_Unit_Ownership__c
                FROM Generation_Unit_Assignment__c
                WHERE Generation_Unit__c IN :genUnitIds
                ORDER BY Start_Date__c ASC
        ]) {
            msLepton.addToMap(
                    assignmentItem.Generation_Unit__c,
                    assignmentItem.Contract__c,
                    assignmentItem,
                    generatorIdToContractIdToListOfCurrentAssignments);
        }
        return generatorIdToContractIdToListOfCurrentAssignments;
    }

    private static ListMapContainer loadOwnerships(Set<Id> genUnitIds) {
        ListMapContainer generatorIdToListOfOwnerships =
                new ListMapContainer(Generation_Unit_Ownership__c.SObjectType);
        for (Generation_Unit_Ownership__c ownershipItem : [
                SELECT Id, Start_Date__c, End_Date__c, Generation_Unit__c
                FROM Generation_Unit_Ownership__c
                WHERE Generation_Unit__c IN :genUnitIds
                AND Start_Date__c != NULL
                ORDER BY Start_Date__c ASC
        ]) {
            generatorIdToListOfOwnerships.addToMap(ownershipItem.Generation_Unit__c, ownershipItem);
        }
        return generatorIdToListOfOwnerships;
    }

    private static void loadMeterConnections(
            Set<Id> genUnitIds,
            Set<Id> relevantMeterIds,
            ListMapContainer generatorIdToRelationships) {
        for (Meter2GenerationUnitRelationship__c m2GUItem : [
                SELECT Valid_from__c, Valid_to__c, Meter__c, Generator_Unit__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Generator_Unit__c IN :genUnitIds
                AND Valid_from__c != NULL
                ORDER BY Valid_from__c ASC
        ]) {
            relevantMeterIds.add(m2GUItem.Meter__c);
            generatorIdToRelationships.addToMap(m2GUItem.Generator_Unit__c, m2GUItem);
        }
    }

    private static ListMapContainer loadMeterRegistrations(Set<Id> relevantMeterIds) {
        ListMapContainer meterIdToMeterRegsMap = new ListMapContainer(MeterRegistration__c.SObjectType);
        for (MeterRegistration__c regItem : [
                SELECT
                        Meter__c,
                        Contract__c,
                        Valid_to__c,
                        Valid_from__c,
                        Contract__r.Name
                FROM MeterRegistration__c
                WHERE Meter__c IN :relevantMeterIds
                AND Valid_from__c != NULL
                ORDER BY Valid_from__c ASC
        ]) {
            meterIdToMeterRegsMap.addToMap(regItem.Meter__c, regItem);
        }
        return meterIdToMeterRegsMap;
    }

    private static void nameAssignments(
            List<Generation_Unit_Assignment__c> assignmentsToName,
            Map<Id, Generation_Unit__c> generationUnitMap) {

        for (Generation_Unit_Assignment__c assignmentToName : assignmentsToName) {
            Generation_Unit__c generatorToAssign = generationUnitMap.get(assignmentToName.Generation_Unit__c);
            assignmentToName.Name = generatorToAssign.Name + ' - ' + msLepton.format(assignmentToName.Start_Date__c, DATE_FORMAT_STRING) + ' - ';
            if (assignmentToName.End_Date__c != null) {
                assignmentToName.Name += msLepton.format(assignmentToName.End_Date__c, DATE_FORMAT_STRING);
            } else {
                assignmentToName.Name += 'open End';
            }
            if (assignmentToName.Name.length() > 80) {
                assignmentToName.Name = assignmentToName.Name.left(76) + '...';
            }
        }
    }

    private static ListMapContainer calculateUnmergedAssignmentTimeline(
            Generation_Unit__c generatorToAssign,
            List<Meter2GenerationUnitRelationship__c> relationships,
            ListMapContainer meterIdToMeterRegsMap) {

        ListMapContainer contractIdToAssignmentsBeforeMerge =
                new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);

        for (Meter2GenerationUnitRelationship__c relationItem : relationships) {
            List<MeterRegistration__c> correspondingRegistrations = meterIdToMeterRegsMap.get(relationItem.Meter__c);
            for (MeterRegistration__c regItem : correspondingRegistrations) {
                Generation_Unit_Assignment__c newAssignment = new Generation_Unit_Assignment__c(
                        Generation_Unit__c = generatorToAssign.Id,
                        Contract__c = regItem.Contract__c
                );
                if (msLepton.checkDateIntersectionWithInfinity(
                        relationItem.Valid_from__c,
                        relationItem.Valid_to__c,
                        regItem.Valid_from__c,
                        regItem.Valid_to__c)) {
                    newAssignment.Start_Date__c = msLepton.max(regItem.Valid_from__c, relationItem.Valid_from__c);
                    newAssignment.End_Date__c = msLepton.min(regItem.Valid_to__c, relationItem.Valid_to__c);
                    contractIdToAssignmentsBeforeMerge.addToMap(regItem.Contract__c, newAssignment);
                }
            }
        }
        return contractIdToAssignmentsBeforeMerge;
    }

    private static ListMapContainer mergeIntersectingTimelineItems(
            ListMapContainer contractIdToAssignmentsBeforeMerge) {
        ListMapContainer contractIdToAssignmentsAfterMerge =
                new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);

        for (Id contractId : contractIdToAssignmentsBeforeMerge.keySet()) {
            List<Generation_Unit_Assignment__c> mergedAssignments = new List<Generation_Unit_Assignment__c>();
            List<Generation_Unit_Assignment__c> assignmentsBeforeMerge = contractIdToAssignmentsBeforeMerge.get(contractId);
            for (Generation_Unit_Assignment__c assignmentToMerge : assignmentsBeforeMerge) {
                if (mergedAssignments.isEmpty()) {
                    mergedAssignments.add(assignmentToMerge);
                } else {
                    Generation_Unit_Assignment__c lastElement =
                            (Generation_Unit_Assignment__c) msLepton.last(mergedAssignments);
                    if (lastElement.Start_Date__c == assignmentToMerge.Start_Date__c) {
                        lastElement.End_Date__c = msLepton.maxWithInfinity(assignmentToMerge.End_Date__c, lastElement.End_Date__c);
                    } else if (lastElement.End_Date__c != null) {
                        if (lastElement.End_Date__c >= assignmentToMerge.Start_Date__c.addDays(-1)) {
                            lastElement.End_Date__c = msLepton.maxWithInfinity(assignmentToMerge.End_Date__c, lastElement.End_Date__c);
                        } else {
                            mergedAssignments.add(assignmentToMerge);
                        }
                    }
                }
            }
            contractIdToAssignmentsAfterMerge.put(contractId, mergedAssignments);
        }
        return contractIdToAssignmentsAfterMerge;
    }

    private static ListMapContainer splitAssignmentsBasedOnOwnershipTimeline(
            ListMapContainer contractIdToAssignmentsAfterMerge,
            List<Generation_Unit_Ownership__c> ownerships
    ) {
        ListMapContainer contractIdToAssignmentsAfterSplits =
                new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);
        if (ownerships.size() != 0) {
            for (Id contractId : contractIdToAssignmentsAfterMerge.keySet()) {
                List<Generation_Unit_Assignment__c> splitAssignments = new List<Generation_Unit_Assignment__c>();
                List<Generation_Unit_Assignment__c> mergedAssignments = contractIdToAssignmentsAfterMerge.get(contractId);
                for (Generation_Unit_Assignment__c assignmentToSplit : mergedAssignments) {
                    Boolean matched = false;
                    for (Integer i = 0; i < ownerships.size(); i++) {
                        Generation_Unit_Assignment__c lastSplit = null;
                        if (matched) {
                            lastSplit = (Generation_Unit_Assignment__c) msLepton.last(splitAssignments);
                        }
                        if (msLepton.checkDateIntersectionWithInfinity(
                                assignmentToSplit.Start_Date__c,
                                assignmentToSplit.End_Date__c,
                                ownerships[i].Start_Date__c,
                                ownerships[i].End_Date__c)) {
                            if (msLepton.isLast(i, ownerships)
                                    || assignmentToSplit.Start_Date__c < ownerships[i + 1].Start_Date__c) {
                                //There is an actual intersection to be assigned
                                if (!matched && assignmentToSplit.Start_Date__c < ownerships[i].Start_Date__c) {
                                    //We need to assign a no Ownership period
                                    splitAssignments.add(new Generation_Unit_Assignment__c(
                                            Start_Date__c = assignmentToSplit.Start_Date__c,
                                            End_Date__c = ownerships[i].Start_Date__c.addDays(-1),
                                            Generation_Unit__c = assignmentToSplit.Generation_Unit__c,
                                            Contract__c = assignmentToSplit.Contract__c,
                                            Generation_Unit_Ownership__c = null
                                    ));
                                }
                                if (!msLepton.isLast(i, ownerships)) {
                                    //In Order to avoid Bad Data Overlaps
                                    ownerships[i].End_Date__c = msLepton.min(ownerships[i].End_Date__c, ownerships[i + 1].Start_Date__c.addDays(-1));
                                }
                                splitAssignments.add(new Generation_Unit_Assignment__c(
                                        Start_Date__c = msLepton.max(ownerships[i].Start_Date__c, assignmentToSplit.Start_Date__c),
                                        End_Date__c = msLepton.min(assignmentToSplit.End_Date__c, ownerships[i].End_Date__c),
                                        Generation_Unit__c = assignmentToSplit.Generation_Unit__c,
                                        Contract__c = assignmentToSplit.Contract__c,
                                        Generation_Unit_Ownership__c = ownerships[i].Id
                                ));
                                if (hasResidueOverlap(i, ownerships, assignmentToSplit)) {
                                    //If there is no Ownership period afterwards, we need to address it
                                    Date endDate = assignmentToSplit.End_Date__c;
                                    if (!msLepton.isLast(i, ownerships)) {
                                        endDate = ownerships[i + 1].Start_Date__c.addDays(-1);
                                    }
                                    splitAssignments.add(new Generation_Unit_Assignment__c(
                                            Start_Date__c = ownerships[i].End_Date__c.addDays(1),
                                            End_Date__c = endDate,
                                            Generation_Unit__c = assignmentToSplit.Generation_Unit__c,
                                            Contract__c = assignmentToSplit.Contract__c,
                                            Generation_Unit_Ownership__c = null
                                    ));
                                }
                                matched = true;
                            }
                        }
                    }
                }
                contractIdToAssignmentsAfterSplits.put(contractId, splitAssignments);
            }
        } else {
            contractIdToAssignmentsAfterSplits = contractIdToAssignmentsAfterMerge;
        }
        return contractIdToAssignmentsAfterSplits;
    }

    private static Boolean hasResidueOverlap(
            Integer i,
            List<Generation_Unit_Ownership__c> ownerships,
            Generation_Unit_Assignment__c assignment) {
        return ownerships[i].End_Date__c != null
                && ((msLepton.isLast(i, ownerships)
                && msLepton.checkDateIntersectionWithInfinity(
                ownerships[i].End_Date__c.addDays(1),
                null,
                assignment.Start_Date__c,
                assignment.End_Date__c))
                || (!msLepton.isLast(i, ownerships)
                && ownerships[i].End_Date__c.addDays(1) < ownerships[i + 1].Start_Date__c)
                && msLepton.checkDateIntersectionWithInfinity(
                ownerships[i].End_Date__c.addDays(1),
                ownerships[i + 1].Start_Date__c,
                assignment.Start_Date__c,
                assignment.End_Date__c));
    }
}
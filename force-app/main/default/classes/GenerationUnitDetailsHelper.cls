/**
 * Created by Steffen Naundorf on 07.09.2021.
 */

public with sharing class GenerationUnitDetailsHelper {
    private List<Generation_Unit_Details__c> triggerOld;
    private List<Generation_Unit_Details__c> triggerNew;
    private Map<Id, Generation_Unit_Details__c> oldMap;
    private Map<Id, Generation_Unit_Details__c> newMap;

    public GenerationUnitDetailsHelper(
            List<Generation_Unit_Details__c> oldList,
            List<Generation_Unit_Details__c> newList,
            Map<Id, Generation_Unit_Details__c> mapOld,
            Map<Id, Generation_Unit_Details__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //Static Infos
    private static final String x_51_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Generation_Unit_Details__c', 'x_51_Details').Id;
    private static final String Redispatch_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Generation_Unit_Details__c', 'Redispatch_Details').Id;
    private static final String DATE_TIME_FORMAT = 'dd.MM.yyyy';

    //SOQL Maps
    private Map<Id, Generation_Unit__c> generationUnitMap = new Map<Id, Generation_Unit__c>();
    private Map<Id, Generation_Unit_Details__c> generationUnitDetailsMap = new Map<Id, Generation_Unit_Details__c>();

    //DML Lists/Maps
    public Map<Id, Generation_Unit__c> generationUnitUpdateMap = new Map<Id, Generation_Unit__c>();

    //Generation Unit Details Timeline variables
    Set<Id> mdt_generationUnitIdsToCheckForGenerationUnitDetails = new Set<Id>();
    Set<Id> mdt_generationUnitIdsForUpdate = new Set<Id>();
    ListMapContainer mdt_generationUnitIdToGenerationUnitDetails = new ListMapContainer(Generation_Unit_Details__c.SObjectType);

    //All SOQL Methods (includes context specific ones)
    public void load_GenerationUnitDetails() {
        if (!mdt_generationUnitIdsToCheckForGenerationUnitDetails.isEmpty()) {
            generationUnitDetailsMap = new Map<Id, Generation_Unit_Details__c>(query_GenerationUnitDetails(mdt_generationUnitIdsToCheckForGenerationUnitDetails));
        }
    }

    public void load_GenerationUnits() {
        if (!mdt_generationUnitIdsForUpdate.isEmpty()) {
            generationUnitMap = new Map<Id, Generation_Unit__c>(query_GenerationUnits(mdt_generationUnitIdsForUpdate));
        }
    }

    public static List<Generation_Unit_Details__c> query_GenerationUnitDetails(Set<Id> generationUnitIds) {
        return [
                SELECT Start_Date__c, End_Date__c, RecordTypeId, Active__c, Generation_Unit__c, RecordType.DeveloperName,
                        MaStR_ID__c, TR_ID__c, X51_Compensation_3_1__c, X51_Compensation_4_2__c,
                        Generation_Unit__r.MaStR_ID__c, Generation_Unit__r.TR_ID__c, Generation_Unit__r.GU_X51_Compensation_3_1__c, Generation_Unit__r.GU_X51_Compensation_4_2__c
                FROM Generation_Unit_Details__c
                WHERE Generation_Unit__c IN :generationUnitIds
                ORDER BY Start_Date__c ASC
        ];
    }

    public static List<Generation_Unit__c> query_GenerationUnits(Set<Id> generationUnitIds) {
        return [
                SELECT Id, GU_X51_Compensation_4_2__c, GU_X51_Compensation_3_1__c, TR_ID__c, MaStR_ID__c,
                        Meter_ID__c
                FROM Generation_Unit__c
                WHERE Id IN :generationUnitIds
        ];
    }


    //GenerationUnit Details Timeline methods
    public void mdt_identifyGenerationUnitIds(Boolean forceListing) {
        for (Generation_Unit_Details__c detailItem : triggerNew) {
            if (forceListing || mdt_generationUnitDetailsHaveChangedContext(oldMap.get(detailItem.Id), detailItem)) {
                mdt_generationUnitIdsToCheckForGenerationUnitDetails.add(detailItem.Generation_Unit__c);
            }
            if (mdt_generationUnitNeedsUpdate(detailItem)) {
                mdt_generationUnitIdsForUpdate.add(detailItem.Generation_Unit__c);
            }
        }
    }

    public void mdt_NameRecord(Generation_Unit_Details__c newDetails) {
        if (newDetails.RecordTypeId == x_51_Details_RECORD_TYPE_ID) {
            newDetails.Name = '$51 Details: ';
        } else if (newDetails.RecordTypeId == Redispatch_Details_RECORD_TYPE_ID) {
            newDetails.Name = 'Redispatch Details: ';
        }

        newDetails.Name += msLepton.format(newDetails.Start_Date__c, DATE_TIME_FORMAT) + ' - ';
        if (newDetails.End_Date__c == null) {
            newDetails.Name += 'Open End';
        } else {
            newDetails.Name += msLepton.format(newDetails.End_Date__c, DATE_TIME_FORMAT);
        }
        if (newDetails.Name.length() > 80) {
            newDetails.Name = newDetails.Name.left(76) + '...';
        }
    }

    private Boolean mdt_generationUnitDetailsHaveChangedContext(Generation_Unit_Details__c oldDetails, Generation_Unit_Details__c newDetails) {
        return oldDetails.Start_Date__c != newDetails.Start_Date__c
                || oldDetails.End_Date__c != newDetails.End_Date__c
                || oldDetails.RecordTypeId != newDetails.RecordTypeId;
    }

    public void mdt_buildGenerationUnitDetailsTimelineDataModel() {
        if (!mdt_generationUnitIdsToCheckForGenerationUnitDetails.isEmpty()) {
            for (Generation_Unit_Details__c generationUnitDetailsItem : generationUnitDetailsMap.values()) {
                mdt_generationUnitIdToGenerationUnitDetails.addToMap(generationUnitDetailsItem.Generation_Unit__c, generationUnitDetailsItem);
            }
        }
    }

    public void mdt_checkTimeLineValidity(Generation_Unit_Details__c newDetails) {
        Generation_Unit_Details__c lastTimeLineItem = null;
        List<Generation_Unit_Details__c> orderedGenerationUnitDetailsTimeline = mdt_generationUnitIdToGenerationUnitDetails.get(newDetails.Generation_Unit__c);
        for (Generation_Unit_Details__c timeLineItem : orderedGenerationUnitDetailsTimeline) {
            if (timeLineItem.RecordTypeId == newDetails.RecordTypeId) {
                if (lastTimeLineItem == null) {
                    lastTimeLineItem = timeLineItem;
                } else if (lastTimeLineItem.End_Date__c != null
                        && lastTimeLineItem.End_Date__c < timeLineItem.Start_Date__c) {
                    lastTimeLineItem = timeLineItem;
                } else {
                    newDetails.addError(Label.Validation_GU_Details_Timeline);
                }
            }
        }
    }

    public void mdt_checkTimeLineValidityIfNecessary(Generation_Unit_Details__c oldDetails, Generation_Unit_Details__c newDetails) {
        if (mdt_generationUnitDetailsHaveChangedContext(oldDetails, newDetails)) {
            mdt_checkTimeLineValidity(newDetails);
        }
    }

    public void mdt_updateGenerationUnitIfNecessary(Generation_Unit_Details__c newDetails) {
        if (newDetails.Active__c && newDetails.getErrors().isEmpty() && mdt_generationUnitNeedsUpdate(newDetails)) {
            mdt_determineGenerationUnitUpdate(generationUnitMap.get(newDetails.Generation_Unit__c), newDetails);
            generationUnitUpdateMap.put(newDetails.Generation_Unit__c, generationUnitMap.get(newDetails.Generation_Unit__c));
        }
    }

    public static Boolean mdt_generationUnitNeedsUpdate(Generation_Unit_Details__c generationUnitDetailsToCheckForActivation) {
        Boolean updateRequired = false;
        if (generationUnitDetailsToCheckForActivation.Active__c) {
            if (generationUnitDetailsToCheckForActivation.RecordTypeId == x_51_Details_RECORD_TYPE_ID) {
                if (generationUnitDetailsToCheckForActivation.X51_Compensation_3_1__c != generationUnitDetailsToCheckForActivation.Generation_Unit__r.GU_X51_Compensation_3_1__c) {
                    updateRequired = true;
                }
                if (generationUnitDetailsToCheckForActivation.X51_Compensation_4_2__c != generationUnitDetailsToCheckForActivation.Generation_Unit__r.GU_X51_Compensation_4_2__c) {
                    updateRequired = true;
                }
            } else if (generationUnitDetailsToCheckForActivation.RecordTypeId == Redispatch_Details_RECORD_TYPE_ID) {
                if (generationUnitDetailsToCheckForActivation.TR_ID__c != generationUnitDetailsToCheckForActivation.Generation_Unit__r.TR_ID__c) {
                    updateRequired = true;
                }
                if (generationUnitDetailsToCheckForActivation.MaStR_ID__c != generationUnitDetailsToCheckForActivation.Generation_Unit__r.MaStR_ID__c) {
                    updateRequired = true;
                }
            }
        }
        return updateRequired;
    }

    public static void mdt_determineGenerationUnitUpdate(Generation_Unit__c generationUnitToUpdate, Generation_Unit_Details__c updateDetails) {
        if (updateDetails.Active__c && updateDetails.Generation_Unit__c == generationUnitToUpdate.Id) {
            if (updateDetails.RecordTypeId == x_51_Details_RECORD_TYPE_ID) {
                if (updateDetails.X51_Compensation_3_1__c != generationUnitToUpdate.GU_X51_Compensation_3_1__c) {
                    generationUnitToUpdate.GU_X51_Compensation_3_1__c = updateDetails.X51_Compensation_3_1__c;
                }
                if (updateDetails.X51_Compensation_4_2__c != generationUnitToUpdate.GU_X51_Compensation_4_2__c) {
                    generationUnitToUpdate.GU_X51_Compensation_4_2__c = updateDetails.X51_Compensation_4_2__c;
                }
            } else if (updateDetails.RecordTypeId == Redispatch_Details_RECORD_TYPE_ID) {
                if (updateDetails.TR_ID__c != generationUnitToUpdate.TR_ID__c) {
                    generationUnitToUpdate.TR_ID__c = updateDetails.TR_ID__c;
                }
                if (updateDetails.MaStR_ID__c != generationUnitToUpdate.MaStR_ID__c) {
                    generationUnitToUpdate.MaStR_ID__c = updateDetails.MaStR_ID__c;
                }
            }
        }
    }
}
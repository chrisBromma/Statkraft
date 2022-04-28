/****************************************************************************************************
* Class MeterDetailsHelper
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-07-08
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-07-08       	Init version.
*****************************************************************************************************/

public with sharing class MeterDetailsHelper {
    private List<Meter_Details__c> triggerOld;
    private List<Meter_Details__c> triggerNew;
    private Map<Id, Meter_Details__c> oldMap;
    private Map<Id, Meter_Details__c> newMap;

    public MeterDetailsHelper(
            List<Meter_Details__c> oldList,
            List<Meter_Details__c> newList,
            Map<Id, Meter_Details__c> mapOld,
            Map<Id, Meter_Details__c> mapNew
    ) {
        triggerOld = oldList;
        triggerNew = newList;
        oldMap = mapOld;
        newMap = mapNew;
    }

    //Static Infos
    private static final String Grid_Operator_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Grid_Operator_Details').Id;
    private static final String Metering_Point_Operator_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Metering_Point_Operator_Details').Id;
    private static final String MaLo_MeLo_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'MaLo_MeLo_Details').Id;
    private static final String Merit_Order_Mode_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Merit_Order_Mode_Details').Id;
    private static final String Redispatch_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Meter_Details__c', 'Redispatch_Details').Id;
    private static final String DATE_TIME_FORMAT = 'dd.MM.yyyy';

    //SOQL Maps
    private Map<Id, Meter__c> meterMap = new Map<Id, Meter__c>();
    private Map<Id, Meter_Details__c> meterDetailsMap = new Map<Id, Meter_Details__c>();

    //DML Lists/Maps
    public Map<Id, Meter__c> meterUpdateMap = new Map<Id, Meter__c>();

    //Meter Details Timeline variables
    Set<Id> mdt_meterIdsToCheckForMeterDetails = new Set<Id>();
    Set<Id> mdt_meterIdsForUpdate = new Set<Id>();
    ListMapContainer mdt_meterIdToMeterDetails = new ListMapContainer(Meter_Details__c.SObjectType);

    //All SOQL Methods (includes context specific ones)
    public void load_MeterDetails() {
        if (!mdt_meterIdsToCheckForMeterDetails.isEmpty()) {
            meterDetailsMap = new Map<Id, Meter_Details__c>(query_MeterDetails(mdt_meterIdsToCheckForMeterDetails));
        }
    }

    public void load_Meters() {
        if (!mdt_meterIdsForUpdate.isEmpty()) {
            meterMap = new Map<Id, Meter__c>(query_Meters(mdt_meterIdsForUpdate));
        }
    }

    public static List<Meter_Details__c> query_MeterDetails(Set<Id> meterIds) {
        return [
                SELECT Start_Date__c, End_Date__c, RecordTypeId, Active__c, Meter__c, RecordType.DeveloperName,
                        Meter__r.VPP_Type__c, Meter__r.Merit_Order_Mode__c, VPP_Type__c, Merit_Order_Mode__c,
                        Meter__r.DSO__c, Meter__r.TSO__c, DSO__c, TSO__c,
                        Meter__r.Alternative_Meter_ID__c, Meter__r.Meter_ID__c, MALO__c, MELO__c,
                        Meter__r.Metering_Point_Operator__c, Metering_Point_Operator__c,
                        Meter__r.Balancing_Model_Redispatch__c, Meter__r.Signal_Routing_Redispatch__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter_Details__c
                WHERE Meter__c IN :meterIds
                ORDER BY Start_Date__c ASC
        ];
    }

    public static List<Meter__c> query_Meters(Set<Id> meterIds) {
        return [
                SELECT Id, VPP_Type__c, Merit_Order_Mode__c, DSO__c, TSO__c,
                        Alternative_Meter_ID__c, Metering_Point_Operator__c, Meter_ID__c,
                        Balancing_Model_Redispatch__c, Signal_Routing_Redispatch__c
                FROM Meter__c
                WHERE Id IN :meterIds
        ];
    }


    //Meter Details Timeline methods
    public void mdt_identifyMeterIds(Boolean forceListing) {
        for (Meter_Details__c detailItem : triggerNew) {
            if (forceListing || mdt_meterDetailsHaveChangedContext(oldMap.get(detailItem.Id), detailItem)) {
                mdt_meterIdsToCheckForMeterDetails.add(detailItem.Meter__c);
            }
            if (mdt_meterNeedsUpdate(detailItem)) {
                mdt_meterIdsForUpdate.add(detailItem.Meter__c);
            }
        }
    }

    public void mdt_NameRecord(Meter_Details__c newDetails) {
        if (newDetails.RecordTypeId == Grid_Operator_Details_RECORD_TYPE_ID) {
            newDetails.Name = 'Grid Operator Details: ';
        } else if (newDetails.RecordTypeId == Metering_Point_Operator_Details_RECORD_TYPE_ID) {
            newDetails.Name = 'Metering Point Operator Details: ';
        } else if (newDetails.RecordTypeId == MaLo_MeLo_Details_RECORD_TYPE_ID) {
            newDetails.Name = 'MaLo, MeLo Details: ';
        } else if (newDetails.RecordTypeId == Merit_Order_Mode_Details_RECORD_TYPE_ID) {
            newDetails.Name = 'Merit Order Mode Details: ';
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

    private Boolean mdt_meterDetailsHaveChangedContext(Meter_Details__c oldDetails, Meter_Details__c newDetails) {
        return oldDetails.Start_Date__c != newDetails.Start_Date__c
                || oldDetails.End_Date__c != newDetails.End_Date__c
                || oldDetails.RecordTypeId != newDetails.RecordTypeId;
    }

    public void mdt_buildMeterDetailsTimelineDataModel() {
        if (!mdt_meterIdsToCheckForMeterDetails.isEmpty()) {
            for (Meter_Details__c meterDetailsItem : meterDetailsMap.values()) {
                mdt_meterIdToMeterDetails.addToMap(meterDetailsItem.Meter__c, meterDetailsItem);
            }
        }
    }

    public void mdt_checkTimeLineValidity(Meter_Details__c newDetails) {
        Meter_Details__c lastTimeLineItem = null;
        List<Meter_Details__c> orderedMeterDetailsTimeline = mdt_meterIdToMeterDetails.get(newDetails.Meter__c);
        for (Meter_Details__c timeLineItem : orderedMeterDetailsTimeline) {
            if (timeLineItem.RecordTypeId == newDetails.RecordTypeId) {
                if (lastTimeLineItem == null) {
                    lastTimeLineItem = timeLineItem;
                } else if (lastTimeLineItem.End_Date__c != null
                        && lastTimeLineItem.End_Date__c < timeLineItem.Start_Date__c) {
                    lastTimeLineItem = timeLineItem;
                } else {
                    newDetails.addError(Label.Validation_Meter_Details_Timeline);
                }
            }
        }
    }

    public void mdt_checkTimeLineValidityIfNecessary(Meter_Details__c oldDetails, Meter_Details__c newDetails) {
        if (mdt_meterDetailsHaveChangedContext(oldDetails, newDetails)) {
            mdt_checkTimeLineValidity(newDetails);
        }
    }

    public void mdt_updateMeterIfNecessary(Meter_Details__c newDetails) {
        if (newDetails.Active__c && newDetails.getErrors().isEmpty() && mdt_meterNeedsUpdate(newDetails)) {
            mdt_determineMeterUpdate(meterMap.get(newDetails.Meter__c), newDetails);
            meterUpdateMap.put(newDetails.Meter__c, meterMap.get(newDetails.Meter__c));
        }
    }

    public static Boolean mdt_meterNeedsUpdate(Meter_Details__c meterDetailsToCheckForActivation) {
        Boolean updateRequired = false;
        if (meterDetailsToCheckForActivation.Active__c) {
            if (meterDetailsToCheckForActivation.RecordTypeId == Grid_Operator_Details_RECORD_TYPE_ID) {
                if (meterDetailsToCheckForActivation.DSO__c != meterDetailsToCheckForActivation.Meter__r.DSO__c) {
                    updateRequired = true;
                }
                if (meterDetailsToCheckForActivation.TSO__c != meterDetailsToCheckForActivation.Meter__r.TSO__c) {
                    updateRequired = true;
                }
            } else if (meterDetailsToCheckForActivation.RecordTypeId == Metering_Point_Operator_Details_RECORD_TYPE_ID) {
                if (meterDetailsToCheckForActivation.Metering_Point_Operator__c
                        != meterDetailsToCheckForActivation.Meter__r.Metering_Point_Operator__c) {
                    updateRequired = true;
                }
            } else if (meterDetailsToCheckForActivation.RecordTypeId == MaLo_MeLo_Details_RECORD_TYPE_ID) {
                if (meterDetailsToCheckForActivation.MALO__c != meterDetailsToCheckForActivation.Meter__r.Alternative_Meter_ID__c) {
                    updateRequired = true;
                }
                if (meterDetailsToCheckForActivation.MELO__c != meterDetailsToCheckForActivation.Meter__r.Meter_ID__c) {
                    updateRequired = true;
                }
            } else if (meterDetailsToCheckForActivation.RecordTypeId == Merit_Order_Mode_Details_RECORD_TYPE_ID) {
                if (meterDetailsToCheckForActivation.VPP_Type__c != meterDetailsToCheckForActivation.Meter__r.VPP_Type__c) {
                    updateRequired = true;
                }
                if (meterDetailsToCheckForActivation.Merit_Order_Mode__c != meterDetailsToCheckForActivation.Meter__r.Merit_Order_Mode__c) {
                    updateRequired = true;
                }
            } else if (meterDetailsToCheckForActivation.RecordTypeId == Redispatch_Details_RECORD_TYPE_ID) {
                if (meterDetailsToCheckForActivation.Balancing_Model_Redispatch__c != meterDetailsToCheckForActivation.Meter__r.Balancing_Model_Redispatch__c) {
                    updateRequired = true;
                }
                if (meterDetailsToCheckForActivation.Signal_Routing_Redispatch__c != meterDetailsToCheckForActivation.Meter__r.Signal_Routing_Redispatch__c) {
                    updateRequired = true;
                }
            }
        }
        return updateRequired;
    }

    public static void mdt_determineMeterUpdate(Meter__c meterToUpdate, Meter_Details__c updateDetails) {
        if (updateDetails.Active__c && updateDetails.Meter__c == meterToUpdate.Id) {
            if (updateDetails.RecordTypeId == Grid_Operator_Details_RECORD_TYPE_ID) {
                if (updateDetails.DSO__c != meterToUpdate.DSO__c) {
                    meterToUpdate.DSO__c = updateDetails.DSO__c;
                }
                if (updateDetails.TSO__c != meterToUpdate.TSO__c) {
                    meterToUpdate.TSO__c = updateDetails.TSO__c;
                }
            } else if (updateDetails.RecordTypeId == Metering_Point_Operator_Details_RECORD_TYPE_ID) {
                if (updateDetails.Metering_Point_Operator__c
                        != meterToUpdate.Metering_Point_Operator__c) {
                    meterToUpdate.Metering_Point_Operator__c = updateDetails.Metering_Point_Operator__c;
                }
            } else if (updateDetails.RecordTypeId == MaLo_MeLo_Details_RECORD_TYPE_ID) {
                if (updateDetails.MALO__c != meterToUpdate.Alternative_Meter_ID__c) {
                    meterToUpdate.Alternative_Meter_ID__c = updateDetails.MALO__c;
                }
                if (updateDetails.MELO__c != meterToUpdate.Meter_ID__c) {
                    meterToUpdate.Meter_ID__c = updateDetails.MELO__c;
                }
            } else if (updateDetails.RecordTypeId == Merit_Order_Mode_Details_RECORD_TYPE_ID) {
                if (updateDetails.VPP_Type__c != meterToUpdate.VPP_Type__c) {
                    meterToUpdate.VPP_Type__c = updateDetails.VPP_Type__c;
                }
                if (updateDetails.Merit_Order_Mode__c != meterToUpdate.Merit_Order_Mode__c) {
                    meterToUpdate.Merit_Order_Mode__c = updateDetails.Merit_Order_Mode__c;
                }
            } else if (updateDetails.RecordTypeId == Redispatch_Details_RECORD_TYPE_ID) {
                if (updateDetails.Balancing_Model_Redispatch__c != meterToUpdate.Balancing_Model_Redispatch__c) {
                    meterToUpdate.Balancing_Model_Redispatch__c = updateDetails.Balancing_Model_Redispatch__c;
                }
                if (updateDetails.Signal_Routing_Redispatch__c != meterToUpdate.Signal_Routing_Redispatch__c) {
                    meterToUpdate.Signal_Routing_Redispatch__c = updateDetails.Signal_Routing_Redispatch__c;
                }
            }
        }
    }
}
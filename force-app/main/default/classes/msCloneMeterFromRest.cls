/****************************************************************************************************
* Class msCloneMeterFromRest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-05-26
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-05-26       	Init version.
*****************************************************************************************************/

@RestResource(UrlMapping='/Meter__c/Clone/*')

global without sharing class msCloneMeterFromRest {
    @HttpPut
    global static void cloneMeter() {
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, Object> params = new Map<String, Object>();
        responseWrapper wrapper = new responseWrapper();
        try {
            params = (Map<String, Object>) JSON.deserializeUntyped(request.requestBody.toString());
        } catch (Exception e) {
            wrapper.error = 'The JSON is malformed';
            wrapper.apexException = e.getMessage();
            res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
            res.statusCode = 500;
            return;
        }

        if (!params.containsKey('meter')) {
            wrapper.error = 'The key meter is not specified';

            res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
            res.statusCode = 500;
            return;
        }
        if (!params.containsKey('clone_date')) {
            wrapper.error = 'The key clone_date is not specified';

            res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
            res.statusCode = 500;
            return;
        }

        Id meterId = null;
        Date cloneDate = null;
        Boolean copyDataMigrationId = null;

        try {
            meterId = Id.valueOf(String.valueOf(params.get('meter')));
            Meter__c meterObj = new Meter__c();
            meterObj.Id = meterId;
        } catch (Exception e) {
            wrapper.error = 'The key meter is not a valid Meter Id';
            wrapper.apexException = e.getMessage();

            res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
            res.statusCode = 500;
            return;
        }

        try {
            cloneDate = Date.valueOf(String.valueOf(params.get('clone_date')));
        } catch (Exception e) {
            wrapper.error = 'The key clone_date is not a valid Date. Example of a Date: 2020-12-31';
            wrapper.apexException = e.getMessage();
            res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
            res.statusCode = 500;
            return;
        }

        try {
            if(params.containsKey('copy_Data_Migration_Id')) {
                copyDataMigrationId = Boolean.valueOf(params.get('copy_Data_Migration_Id'));
            } else {
                copyDataMigrationId = true;
            }
        } catch (Exception e) {
            wrapper.error = 'The key copy_Data_Migration_Id is not a valid Boolean.';
            wrapper.apexException = e.getMessage();
            res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
            res.statusCode = 500;
            return;
        }
        if(copyDataMigrationId == null) {
            copyDataMigrationId = true;
        }

        wrapper = cloneMeter(meterId, cloneDate, copyDataMigrationId);
        res.responseBody = Blob.valueOf(JSON.serialize(wrapper));
        res.statusCode = 200;
        return;

    }

    public static responseWrapper cloneMeter(Id meterId, Date cloneDate, Boolean copyDataMigrationId) {
        Map<Id, SObject> updateMap = new Map<Id, SObject>();
        List<SObject> insertList = new List<SObject>();
        List<SObject> deleteList = new List<SObject>();
        Map<Site_Role__c, Site_Role__c> updateOldWithNewSiteRolesAfterInsertMap = new Map<Site_Role__c, Site_Role__c>();
        Date dateBeforeCloneDate = cloneDate.addDays(-1);

        Meter__c meterToCloneCalled = [SELECT Id, Parent_Meter__c, (SELECT Id FROM Meters__r) FROM Meter__c WHERE Id = :meterId];
        Set<Id> meterIdsToClone = new Set<Id>();
        meterIdsToClone.add(meterId);
        if (!meterToCloneCalled.Meters__r.isEmpty()) {
            for (Meter__c childMeter : meterToCloneCalled.Meters__r) {
                meterIdsToClone.add(childMeter.Id);
            }
        } else if (meterToCloneCalled.Parent_Meter__c != null) {
            meterIdsToClone.add(meterToCloneCalled.Parent_Meter__c);
            for (Meter__c siblingMeter : [SELECT Id FROM Meter__c WHERE Parent_Meter__c = :meterToCloneCalled.Parent_Meter__c]) {
                meterIdsToClone.add(siblingMeter.Id);
            }
        }

        Map<String, Schema.SObjectField> fieldMapMeter = Meter__c.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNamesMeter = new List<String>(fieldMapMeter.keySet());
        List<Meter__c> metersToClone = Database.query(
                'SELECT ' + '(SELECT Id, Data_Migration_ID__c FROM Original_Meter__r ORDER BY CreatedDate DESC),'
                        + String.join(fieldNamesMeter, ',')
                        + ' FROM Meter__c WHERE Id IN :meterIdsToClone'
        );
        Map<Id, Id> meterToCloneIdToPreviouslyClonedMeterId = new Map<Id, Id>();
        Map<Id, Id> previouslyClonedMeterIdToMeterToCloneId = new Map<Id, Id>();
        for (Meter__c meterToClone : metersToClone) {
            if (!meterToClone.Original_Meter__r.isEmpty()) {
                meterToCloneIdToPreviouslyClonedMeterId.put(meterToClone.Id, meterToClone.Original_Meter__r[0].Id);
                previouslyClonedMeterIdToMeterToCloneId.put(meterToClone.Original_Meter__r[0].Id, meterToClone.Id);
            }
        }

        Map<String, Schema.SObjectField> fieldMapMeterReg = MeterRegistration__c.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNamesMeterReg = new List<String>(fieldMapMeterReg.keySet());

        Set<Id> meterIdsForQuerySet = new Set<Id>();
        meterIdsForQuerySet.addAll(meterIdsToClone);
        meterIdsForQuerySet.addAll(meterToCloneIdToPreviouslyClonedMeterId.values());

        List<MeterRegistration__c> meterRegs = Database.query(
                'SELECT ' + String.join(fieldNamesMeterReg, ',') +
                        ' FROM MeterRegistration__c ' +
                        'WHERE Meter__c IN :meterIdsForQuerySet'
        );
        Map<String, MeterRegistration__c> dataMigrationIdToMeterRegsToCloneMap = new Map<String, MeterRegistration__c>();
        List<MeterRegistration__c> meterRegsToClone = new List<MeterRegistration__c>();
        Map<Id, MeterRegistration__c> meterRegsToCloneIdsToPreviouslyClonedMeterRegsMap = new Map<Id, MeterRegistration__c>();

        for (MeterRegistration__c regToSort : meterRegs) {
            if (meterIdsToClone.contains(regToSort.Meter__c)) {
                meterRegsToClone.add(regToSort);
                if (regToSort.Data_Migration_ID__c != null) {
                    dataMigrationIdToMeterRegsToCloneMap.put(regToSort.Data_Migration_ID__c, regToSort);
                }
            }
        }
        for (MeterRegistration__c regToSort : meterRegs) {
            if (meterToCloneIdToPreviouslyClonedMeterId.values().contains(regToSort.Meter__c)
                    && regToSort.Data_Migration_ID__c != null
                    && regToSort.Data_Migration_ID__c.contains('_cloned')) {

                String dataMigrationId = null;
                String dataMigrationIdWithPotentialCounter = regToSort.Data_Migration_ID__c.left(regToSort.Data_Migration_ID__c.indexOf('_cloned'));
                if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                    dataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                } else {
                    dataMigrationId = dataMigrationIdWithPotentialCounter;
                }
                if (dataMigrationIdToMeterRegsToCloneMap.containsKey(dataMigrationId)) {
                    meterRegsToCloneIdsToPreviouslyClonedMeterRegsMap.put(dataMigrationIdToMeterRegsToCloneMap.get(dataMigrationId).Id, regToSort);
                }
            }
        }

        Map<String, Schema.SObjectField> fieldMapM2GUR = Meter2GenerationUnitRelationship__c.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNamesM2GUR = new List<String>(fieldMapM2GUR.keySet());
        List<Meter2GenerationUnitRelationship__c> m2GURs = Database.query(
                'SELECT ' + String.join(fieldNamesM2GUR, ',')
                        + ' FROM Meter2GenerationUnitRelationship__c ' +
                        'WHERE Meter__c IN :meterIdsForQuerySet'
        );
        Map<String, Meter2GenerationUnitRelationship__c> dataMigrationIdToGenRelsToCloneMap = new Map<String, Meter2GenerationUnitRelationship__c>();
        List<Meter2GenerationUnitRelationship__c> genRelsToClone = new List<Meter2GenerationUnitRelationship__c>();
        Map<Id, Meter2GenerationUnitRelationship__c> genRelsToCloneIdsToPreviouslyClonedGenRelsMap = new Map<Id, Meter2GenerationUnitRelationship__c>();

        for (Meter2GenerationUnitRelationship__c relToSort : m2GURs) {
            if (meterIdsToClone.contains(relToSort.Meter__c)) {
                genRelsToClone.add(relToSort);
                if (relToSort.Data_Migration_ID__c != null) {
                    dataMigrationIdToGenRelsToCloneMap.put(relToSort.Data_Migration_ID__c, relToSort);
                }
            }
        }
        for (Meter2GenerationUnitRelationship__c relToSort : m2GURs) {
            if (meterToCloneIdToPreviouslyClonedMeterId.values().contains(relToSort.Meter__c)) {
                if (relToSort.Data_Migration_ID__c != null
                        && relToSort.Data_Migration_ID__c.contains('_cloned')) {

                    String dataMigrationId = null;
                    String dataMigrationIdWithPotentialCounter = relToSort.Data_Migration_ID__c.left(relToSort.Data_Migration_ID__c.indexOf('_cloned'));
                    if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                        dataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                    } else {
                        dataMigrationId = dataMigrationIdWithPotentialCounter;
                    }
                    if (dataMigrationIdToGenRelsToCloneMap.containsKey(dataMigrationId)) {
                        genRelsToCloneIdsToPreviouslyClonedGenRelsMap.put(dataMigrationIdToGenRelsToCloneMap.get(dataMigrationId).Id, relToSort);
                    }
                }
            }
        }

        Map<String, Schema.SObjectField> fieldMapSiteRole = Site_Role__c.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNamesSiteRole = new List<String>(fieldMapSiteRole.keySet());
        List<Site_Role__c> siteRoles = Database.query(
                'SELECT ' + String.join(fieldNamesSiteRole, ',')
                        + ' FROM Site_Role__c ' +
                        'WHERE Meter__c IN :meterIdsForQuerySet'
        );
        Map<String, Site_Role__c> dataMigrationIdToRolesToCloneMap = new Map<String, Site_Role__c>();
        List<Site_Role__c> rolesToClone = new List<Site_Role__c>();
        Map<Id, Site_Role__c> rolesToCloneIdsToPreviouslyClonedRolesMap = new Map<Id, Site_Role__c>();



        for (Site_Role__c roleToSort : siteRoles) {
            if (meterIdsToClone.contains(roleToSort.Meter__c)) {
                rolesToClone.add(roleToSort);
                if (roleToSort.Data_Migration_ID__c != null) {
                    dataMigrationIdToRolesToCloneMap.put(roleToSort.Data_Migration_ID__c, roleToSort);
                }
            }
        }
        for (Site_Role__c roleToSort : siteRoles) {
            if (meterToCloneIdToPreviouslyClonedMeterId.values().contains(roleToSort.Meter__c)) {
                if (roleToSort.Data_Migration_ID__c != null
                        && roleToSort.Data_Migration_ID__c.contains('_cloned')) {
                    String dataMigrationId = null;
                    String dataMigrationIdWithPotentialCounter = roleToSort.Data_Migration_ID__c.left(roleToSort.Data_Migration_ID__c.indexOf('_cloned'));
                    if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                        dataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                    } else {
                        dataMigrationId = dataMigrationIdWithPotentialCounter;
                    }
                    if (dataMigrationIdToRolesToCloneMap.containsKey(dataMigrationId)) {
                        rolesToCloneIdsToPreviouslyClonedRolesMap.put(dataMigrationIdToRolesToCloneMap.get(dataMigrationId).Id, roleToSort);
                    }
                }
            }
        }



        Map<Id, Meter__c> originalIdToCloneMetersMap = new Map<Id, Meter__c>();
        for (Meter__c meterToClone : metersToClone) {
            Meter__c cloneMeter = meterToClone.clone(false, false, false, false);
            cloneMeter.Portfolio_ID__c = null;
            cloneMeter.EMSYS_ID__c = null;
            cloneMeter.Sandbox_Migration_Id__c = null;
            cloneMeter.Data_Migration_ID__c = null;
            cloneMeter.Scheduled_for_Activation_on__c = cloneDate;
            if(!copyDataMigrationId) {
                cloneMeter.Data_Migration_ID__c = null;
            }
            originalIdToCloneMetersMap.put(meterToClone.Id, cloneMeter);
        }
        insert originalIdToCloneMetersMap.values();


        for (Meter__c meterToClone : metersToClone) {
            meterToClone.Succeeding_Clone__c = originalIdToCloneMetersMap.get(meterToClone.Id).Id;
            meterToClone.Scheduled_Cloning_Date__c = cloneDate;
            if (copyDataMigrationId && meterToClone.Data_Migration_ID__c != null) {
                originalIdToCloneMetersMap.get(meterToClone.Id).Data_Migration_ID__c = meterToClone.Data_Migration_ID__c;
                updateMap.put(originalIdToCloneMetersMap.get(meterToClone.Id).Id, originalIdToCloneMetersMap.get(meterToClone.Id));
                if (!meterToClone.Original_Meter__r.isEmpty()) {
                    Meter__c previousClonedMeter = meterToClone.Original_Meter__r[0];
                    if (previousClonedMeter.Data_Migration_ID__c != null) {
                        if (previousClonedMeter.Data_Migration_ID__c.contains('_cloned')) {
                            String dataMigrationIdWithPotentialCounter = previousClonedMeter.Data_Migration_ID__c.left(previousClonedMeter.Data_Migration_ID__c.indexOf('_cloned'));
                            if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                                Integer counter = Integer.valueOf(dataMigrationIdWithPotentialCounter.right(dataMigrationIdWithPotentialCounter.length() - (dataMigrationIdWithPotentialCounter.indexOf('_CC') + 3)));
                                counter++;
                                String realDataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                                meterToClone.Data_Migration_ID__c = realDataMigrationId + '_CC' + counter + '_cloned';
                            } else {
                                meterToClone.Data_Migration_ID__c = dataMigrationIdWithPotentialCounter + '_CC2_cloned';
                            }
                        } else {
                            meterToClone.Data_Migration_ID__c += '_cloned';
                        }
                    } else {
                        meterToClone.Data_Migration_ID__c += '_cloned';
                    }
                } else {
                    meterToClone.Data_Migration_ID__c += '_cloned';
                }
            }
            if (meterToClone.Parent_Meter__c != null) {
                if (updateMap.containsKey(originalIdToCloneMetersMap.get(meterToClone.Id).Id)) {
                    Meter__c cloneMeter = (Meter__c) updateMap.get(originalIdToCloneMetersMap.get(meterToClone.Id).Id);
                    cloneMeter.Parent_Meter__c = originalIdToCloneMetersMap.get(meterToClone.Parent_Meter__c).Id;
                } else {
                    Meter__c cloneMeter = originalIdToCloneMetersMap.get(meterToClone.Id);
                    cloneMeter.Parent_Meter__c = originalIdToCloneMetersMap.get(meterToClone.Parent_Meter__c).Id;
                    updateMap.put(cloneMeter.Id, cloneMeter);
                }

            }
            updateMap.put(meterToClone.Id, meterToClone);
        }

        for (MeterRegistration__c regItem : meterRegsToClone) {
            if (regItem.Valid_to__c == null || cloneDate <= regItem.Valid_to__c) {
                MeterRegistration__c cloneReg = regItem.clone(false, false, false, false);
                cloneReg.Sandbox_Migration_Id__c = null;
                if(!copyDataMigrationId) {
                    cloneReg.Data_Migration_ID__c = null;
                }
                regItem.Valid_to__c = dateBeforeCloneDate;
                if (copyDataMigrationId && regItem.Data_Migration_ID__c != null) {
                    if (meterRegsToCloneIdsToPreviouslyClonedMeterRegsMap.get(regItem.Id) != null) {
                        MeterRegistration__c previousClonedMeterReg = meterRegsToCloneIdsToPreviouslyClonedMeterRegsMap.get(regItem.Id);
                        if (previousClonedMeterReg.Data_Migration_ID__c != null) {
                            if (previousClonedMeterReg.Data_Migration_ID__c.contains('_cloned')) {
                                String dataMigrationIdWithPotentialCounter = previousClonedMeterReg.Data_Migration_ID__c.left(previousClonedMeterReg.Data_Migration_ID__c.indexOf('_cloned'));
                                if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                                    Integer counter = Integer.valueOf(dataMigrationIdWithPotentialCounter.right(dataMigrationIdWithPotentialCounter.length() - (dataMigrationIdWithPotentialCounter.indexOf('_CC') + 3)));
                                    counter++;
                                    String realDataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                                    regItem.Data_Migration_ID__c = realDataMigrationId + '_CC' + counter + '_cloned';
                                } else {
                                    regItem.Data_Migration_ID__c = dataMigrationIdWithPotentialCounter + '_CC2_cloned';
                                }
                            } else {
                                regItem.Data_Migration_ID__c += '_cloned';
                            }
                        } else {
                            regItem.Data_Migration_ID__c += '_cloned';
                        }
                    } else {
                        regItem.Data_Migration_ID__c += '_cloned';
                    }
                }
                cloneReg.Meter__c = originalIdToCloneMetersMap.get(regItem.Meter__c).Id;
                if (regItem.Valid_from__c < cloneDate) {
                    cloneReg.Valid_from__c = cloneDate;
                } else {
                    regItem.Valid_from__c = dateBeforeCloneDate;
                }
                updateMap.put(regItem.Id, regItem);
                insertList.add(cloneReg);
            }
        }


        for (Meter2GenerationUnitRelationship__c relItem : genRelsToClone) {
            if (relItem.Valid_to__c == null || cloneDate <= relItem.Valid_to__c) {
                Meter2GenerationUnitRelationship__c cloneRel = relItem.clone(false, false, false, false);
                relItem.Valid_to__c = dateBeforeCloneDate;
                cloneRel.Sandbox_Migration_Id__c = null;
                if(!copyDataMigrationId) {
                    cloneRel.Data_Migration_ID__c = null;
                }
                if (copyDataMigrationId && relItem.Data_Migration_ID__c != null) {
                    if (genRelsToCloneIdsToPreviouslyClonedGenRelsMap.get(relItem.Id) != null) {
                        Meter2GenerationUnitRelationship__c previousClonedM2GURel = genRelsToCloneIdsToPreviouslyClonedGenRelsMap.get(relItem.Id);
                        if (previousClonedM2GURel.Data_Migration_ID__c != null) {
                            if (previousClonedM2GURel.Data_Migration_ID__c.contains('_cloned')) {
                                String dataMigrationIdWithPotentialCounter = previousClonedM2GURel.Data_Migration_ID__c.left(previousClonedM2GURel.Data_Migration_ID__c.indexOf('_cloned'));
                                if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                                    Integer counter = Integer.valueOf(dataMigrationIdWithPotentialCounter.right(dataMigrationIdWithPotentialCounter.length() - (dataMigrationIdWithPotentialCounter.indexOf('_CC') + 3)));
                                    counter++;
                                    String realDataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                                    relItem.Data_Migration_ID__c = realDataMigrationId + '_CC' + counter + '_cloned';
                                } else {
                                    relItem.Data_Migration_ID__c = dataMigrationIdWithPotentialCounter + '_CC2_cloned';
                                }
                            } else {
                                relItem.Data_Migration_ID__c += '_cloned';
                            }
                        } else {
                            relItem.Data_Migration_ID__c += '_cloned';
                        }
                    } else {
                        relItem.Data_Migration_ID__c += '_cloned';
                    }
                }
                cloneRel.Meter__c = originalIdToCloneMetersMap.get(relItem.Meter__c).Id;
                cloneRel.Sandbox_Migration_Id__c = null;
                if (relItem.Valid_from__c < cloneDate) {
                    cloneRel.Valid_from__c = cloneDate;
                } else {
                    relItem.Valid_from__c = dateBeforeCloneDate;
                }
                updateMap.put(relItem.Id, relItem);
                insertList.add(cloneRel);
            }
        }

        for (Site_Role__c roleItem : rolesToClone) {
            Boolean deleteRole = false;
            if (roleItem.End_Date__c == null || cloneDate <= roleItem.End_Date__c) {
                Site_Role__c cloneRole = roleItem.clone(false, false, false, false);
                cloneRole.Meter__c = originalIdToCloneMetersMap.get(roleItem.Meter__c).Id;
                cloneRole.Sandbox_Migration_Id__c = null;
                if(!copyDataMigrationId) {
                    cloneRole.Data_Migration_ID__c = null;
                }
                if (copyDataMigrationId && roleItem.Data_Migration_ID__c != null) {
                    if (rolesToCloneIdsToPreviouslyClonedRolesMap.get(roleItem.Id) != null) {
                        Site_Role__c previousSiteRole = rolesToCloneIdsToPreviouslyClonedRolesMap.get(roleItem.Id);
                        if (previousSiteRole.Data_Migration_ID__c != null) {
                            if (previousSiteRole.Data_Migration_ID__c.contains('_cloned')) {
                                String dataMigrationIdWithPotentialCounter = previousSiteRole.Data_Migration_ID__c.left(previousSiteRole.Data_Migration_ID__c.indexOf('_cloned'));
                                if (dataMigrationIdWithPotentialCounter.contains('_CC')) {
                                    Integer counter = Integer.valueOf(dataMigrationIdWithPotentialCounter.right(dataMigrationIdWithPotentialCounter.length() - (dataMigrationIdWithPotentialCounter.indexOf('_CC') + 3)));
                                    counter++;
                                    String realDataMigrationId = dataMigrationIdWithPotentialCounter.left(dataMigrationIdWithPotentialCounter.indexOf('_CC'));
                                    roleItem.Data_Migration_ID__c = realDataMigrationId + '_CC' + counter + '_cloned';
                                } else {
                                    roleItem.Data_Migration_ID__c = dataMigrationIdWithPotentialCounter + '_CC2_cloned';
                                }
                            } else {
                                roleItem.Data_Migration_ID__c += '_cloned';
                            }
                        } else {
                            roleItem.Data_Migration_ID__c += '_cloned';
                        }
                    } else {
                        roleItem.Data_Migration_ID__c += '_cloned';
                    }
                }
                if (roleItem.Start_Date__c == null || roleItem.Start_Date__c < cloneDate) {
                    cloneRole.Start_Date__c = cloneDate;
                }
                if (roleItem.Role__c != null && roleItem.Role__c.contains('Customer Portal')) {
                    if (roleItem.Start_Date__c >= cloneDate) {
                        deleteRole = true;
                    } else {
                        roleItem.End_Date__c = dateBeforeCloneDate;
                    }
                }
                if (deleteRole) {
                    deleteList.add(roleItem);
                } else {
                    updateMap.put(roleItem.Id, roleItem);
                    updateOldWithNewSiteRolesAfterInsertMap.put(roleItem, cloneRole);
                }
                insertList.add(cloneRole);
            }
        }

        update updateMap.values();
        delete deleteList;
        insert insertList;
        List<Site_Role__c> updateSiteRolesList = new List<Site_Role__c>();
        for (Site_Role__c oldRoleItem : updateOldWithNewSiteRolesAfterInsertMap.keySet()) {
            oldRoleItem.Succeeding_Clone__c = updateOldWithNewSiteRolesAfterInsertMap.get(oldRoleItem).Id;
            updateSiteRolesList.add(oldRoleItem);
        }
        update updateSiteRolesList;

        responseWrapper wrapper = new responseWrapper();
        wrapper.isSharedMeter = false;
        for (Meter__c cloneMeter : originalIdToCloneMetersMap.values()) {
            if (cloneMeter.Parent_Meter__c == null) {
                wrapper.parent = cloneMeter.Id;
            } else {
                if (wrapper.children == null) {
                    wrapper.children = new Set<String>();
                    wrapper.isSharedMeter = true;
                }
                wrapper.children.add(cloneMeter.Id);
            }
        }

        return wrapper;
    }


    public class responseWrapper {
        String parent { get; set; }
        Set<String> children { get; set; }
        Boolean isSharedMeter { get; set; }
        String error { get; set; }
        String apexException { get; set; }

        responseWrapper() {
            parent = null;
            children = null;
            isSharedMeter = null;
            error = null;
            apexException = null;
        }
    }
}
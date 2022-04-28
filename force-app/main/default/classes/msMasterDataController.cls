/****************************************************************************************************
* Class msMasterDataController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   23.08.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   23.08.2018      	    Init version.
*****************************************************************************************************/

public without sharing class msMasterDataController {

    @AuraEnabled
    public static MasterDataWrapper getMasterData(Id plantId) {

        MasterDataWrapper masterDataWrapper = new MasterDataWrapper();
        if (plantId != null && msUtility.checkObjectAccess(plantId, 'Meter__c')) {
            msUtility.FeatureSetting meterFeatureSetting = msUtility.getMeterFeatures(new Meter__c(Id = plantId));
            if (meterFeatureSetting != null && meterFeatureSetting.isMasterData) {

                List<Meter2GenerationUnitRelationship__c> masterData = getGUnitRelationships(plantId, false);
                List<GUnitMasterData> gUnitMasterDataList = new List<GUnitMasterData>();
                MeterMasterData meter = new MeterMasterData();
                Boolean haveSubMeters = false;

                if (masterData != null && !masterData.isEmpty()) {

                    if (masterData[0].Meter__r != null) {

                        haveSubMeters = masterData[0].Meter__r.Parent_Meter__r != null;
                        Meter__c parentMeter = haveSubMeters
                                ? masterData[0].Meter__r.Parent_Meter__r
                                : masterData[0].Meter__r;

                        if (parentMeter != null) {
                            meter.meterId = parentMeter.Id;
                            meter.meterName = parentMeter.Name;
                            meter.alternativeMeterId = parentMeter.Alternative_Meter_ID__c;
                            meter.meterCapacityMw = parentMeter.Installed_Capacity__c;
                            meter.dsoName = parentMeter.DSO_Name__c;
                            meter.SRId = parentMeter.SR_ID__c;
                            meter.redispatchBalancingModel = parentMeter.Balancing_Model_Redispatch__c;
                            meter.redispatchSignalRouting = parentMeter.Signal_Routing_Redispatch__c;
                            masterDataWrapper.redispatchBillingModel = masterData[0].Meter__r.Current_Contract__r.Billing_Model_Redispatch__c;

                            Account btrAccount = getBtrAccountInfo(parentMeter.Id, haveSubMeters);
                            if (btrAccount != null) {
                                masterDataWrapper.BTRId = btrAccount.BTR_ID__c;
                                masterDataWrapper.BTRName = btrAccount.Name;
                            }
                        }
                    }

                    for (Meter2GenerationUnitRelationship__c generationUnitRelationship : masterData) {
                        GUnitMasterData gUnitMasterData = new GUnitMasterData();
                        if (generationUnitRelationship.Generator_Unit__r != null) {
                            Generation_Unit__c gu = generationUnitRelationship.Generator_Unit__r;
                            if (gu != null) {
                                gUnitMasterData.guId = gu.Id;
                                gUnitMasterData.name = gu.Name;
                                gUnitMasterData.unitId = gu.Unit_ID__c;
                                gUnitMasterData.capacity = gu.Installed_Capacity__c;
                                gUnitMasterData.manufacturer = gu.Manufacturer__c != null ? gu.Manufacturer__r.Name : '';
                                gUnitMasterData.manufacturerNumber = gu.Manufacturer_Number__c;
                                gUnitMasterData.TRId = gu.TR_ID__c;
                                gUnitMasterData.generatorModel = gu.Generator_Model__c;
                                gUnitMasterData.SRId = generationUnitRelationship.SR_ID__c;
                                gUnitMasterDataList.add(gUnitMasterData);
                            }
                        }
                    }
                    masterDataWrapper.parentMeter = meter;
                    masterDataWrapper.gUnits = gUnitMasterDataList;
                    masterDataWrapper.redispatchBillingModelOptions = getPickListValues(Contract__c.Billing_Model_Redispatch__c);
                }
            }
        }
        return masterDataWrapper;
    }

    @AuraEnabled
    public static void saveMasterData(Id meterId, String redispatchBillingModel, Map<Id, String> guIdToTrIdMap, Map<Id, String> guIdToSrIdMap) {

        if (meterId != null && msUtility.checkObjectAccess(meterId, 'Meter__c') && guIdToTrIdMap != null && guIdToSrIdMap != null) {

            List<Meter2GenerationUnitRelationship__c> guMasterData = getGUnitRelationships(meterId, true);
            List<SObject> objectsToUpdate = new List<SObject>();
            MasterDataActivityLog masterDataActivityLog = new MasterDataActivityLog();
            masterDataActivityLog.parentMeterId = meterId;

            Meter__c parentMeter;
            parentMeter = guMasterData[0].Meter__r.Parent_Meter__r;
            parentMeter = parentMeter == null ? guMasterData[0].Meter__r : parentMeter;
            if (parentMeter != null && parentMeter.Current_Contract__r != null
                    && parentMeter.Current_Contract__r.Billing_Model_Redispatch__c != redispatchBillingModel
                    ) {
                masterDataActivityLog.redispatchBillingModel_old = parentMeter.Current_Contract__r.Billing_Model_Redispatch__c;
                masterDataActivityLog.redispatchBillingModel_new = redispatchBillingModel;
            }

            objectsToUpdate.addAll(updateRedispatchBillingModel(parentMeter, redispatchBillingModel));

            for (Meter2GenerationUnitRelationship__c generationUnitRelationship : guMasterData) {
                if (parentMeter != null) {
                    List<SObject> updatedObjects = updateRedispatchBillingModel(generationUnitRelationship.Meter__r, redispatchBillingModel);
                    objectsToUpdate.addAll(updatedObjects);
                }

                if (generationUnitRelationship.Generator_Unit__r != null) {
                    String trId = guIdToTrIdMap.get(generationUnitRelationship.Generator_Unit__r.Id);
                    String srId = guIdToSrIdMap.get(generationUnitRelationship.Generator_Unit__r.Id);
                    Generation_Unit__c generationUnit = generationUnitRelationship.Generator_Unit__r;

                    if (generationUnit.TR_ID__c != trId) {
                        masterDataActivityLog.guIdToTrIdMap_old.put(generationUnit.Id, generationUnit.TR_ID__c);
                        masterDataActivityLog.guIdToTrIdMap_new.put(generationUnit.Id, trId);
                        generationUnit.TR_ID__c = trId;
                        objectsToUpdate.add(generationUnit);
                    }

                    if (generationUnitRelationship.SR_ID__c != srId) {
                        masterDataActivityLog.guRelationshipIdToSrIdMap_old.put(generationUnitRelationship.Id, generationUnitRelationship.SR_ID__c);
                        masterDataActivityLog.guRelationshipIdToSrIdMap_new.put(generationUnitRelationship.Id, srId);
                        generationUnitRelationship.SR_ID__c = srId;
                        objectsToUpdate.add(generationUnitRelationship);
                    }
                }
            }

            //Sorting the sobjects list as they will be segregated as minimum number of chunks for update operation
            objectsToUpdate.sort();

            //to remove duplicates
            Map<Id, SObject> objectsToUpdateMap = new Map<Id, SObject>();
            objectsToUpdateMap.putAll(objectsToUpdate);

            update objectsToUpdateMap.values();

            logActivity(masterDataActivityLog);
        }
    }

    @AuraEnabled
    public static void submitChangeRequest(Id meterId, MasterDataChangeRequest existingValues, MasterDataChangeRequest newValues) {
        if (meterId != null && newValues != null && (newValues.btrId != null || newValues.btrName != null)) {
            String queueName = msUtility.SALES_COORDINATORS_EEG_QUEUE_API_NAME;
            List<QueueSobject> queueList = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = :queueName];

            if (queueList.size() > 0) {

                Id userId = UserInfo.getUserId();
                User user = [SELECT ContactId FROM User WHERE Id = :userId];
                Meter__c meter = [SELECT Current_Contract__c, (SELECT Current_Contract__c FROM Meters__r) FROM Meter__c WHERE Id = :meterId];
                Id contractId = meter.Current_Contract__c != null ? meter.Current_Contract__c : meter.Meters__r[0].Current_Contract__c;

                Case newCase = new Case(
                        RecordTypeId = msUtility.CASE_STANDARD_REC_TYPE_ID,
                        Contract__c = contractId,
                        OwnerId = queueList.get(0).QueueId,
                        Case_Creator__c = msUtility.getSystemUserId(),
                        ContactId = user.ContactId,
                        Origin = msUtility.CASE_ORIGIN_WEB,
                        Reason = msUtility.CASE_REASON_MASTER_DATA_CHANGE,
                        Subject = 'Master Data Change request via portal',
                        Description = composeCaseDescription(existingValues, newValues)
                );
                insert newCase;
            } else {
                throw new AuraHandledException(Label.msMasterDataErrorMessage);
            }
        } else {
            throw new AuraHandledException(Label.msMasterDataErrorMessage);
        }
    }

    public static String composeCaseDescription(MasterDataChangeRequest existingValues, MasterDataChangeRequest newValues) {

        String template = '{0} - {1}';
        String[] descriptionText = new String[]{
        };

        descriptionText.add('Current values:');
        descriptionText.add(String.format(template, new String[]{
                Label.MasterDataBtrName, existingValues.btrName != null ? existingValues.btrName : ''
        }));
        descriptionText.add(String.format(template, new String[]{
                Label.MasterDataBTRId, existingValues.btrId != null ? existingValues.btrId : ''
        }));

        descriptionText.add('\nChange request from the user:');
        descriptionText.add(String.format(template, new String[]{
                Label.MasterDataBtrName, newValues.btrName != null ? newValues.btrName : ''
        }));
        descriptionText.add(String.format(template, new String[]{
                Label.MasterDataBTRId, newValues.btrId != null ? newValues.btrId : ''
        }));

        String tasksToPerformString = '\nTasks:\n' +
                'Account - check/create account for BTR and maintain BTR-ID\n' +
                'Offer - update Offer with the respective BTR information\n' +
                'Meter - create/update site role for BTR\n';

        descriptionText.add(tasksToPerformString);

        String result = String.join(descriptionText, '\n');
        return result;
    }

    private static List<Site_Role__c> getBtrSiteRoles(Id meterId, Boolean needSubMeterRolesOnly) {
        /* Getting all BTR site roles which are not expired (current and future) as we have to show the BTR account info
           for the user to verify even when the btr site role starts in future date. */
        if (needSubMeterRolesOnly) {
            return [
                    SELECT Account__r.BTR_ID__c, Account__r.Name, Role__c, Start_Date__c, End_Date__c
                    FROM Site_Role__c
                    WHERE Meter__c IN (SELECT Id FROM Meter__c WHERE Parent_Meter__c = :meterId)
                    AND Role__c = :msUtility.BTR_SITE_ROLE
                    AND (End_Date__c = NULL OR End_Date__c >= TODAY)
                    ORDER BY Start_Date__c
            ];
        } else {
            return [
                    SELECT Id, Contact__c, Account__c, Account__r.BTR_ID__c, Account__r.Name, Role__c, Start_Date__c, End_Date__c
                    FROM Site_Role__c
                    WHERE Meter__c = :meterId
                    AND Role__c = :msUtility.BTR_SITE_ROLE
                    AND (End_Date__c = NULL OR End_Date__c >= TODAY)
                    ORDER BY Start_Date__c
            ];
        }
    }

    private static Account getBtrAccountInfo(Id meterId, Boolean haveSubMeters) {
        List<Site_Role__c> btrSiteRoles = haveSubMeters ? getBtrSiteRoles(meterId, true) :
                getBtrSiteRoles(meterId, false);

        if (!btrSiteRoles.isEmpty()) {
            Account btrAccount = btrSiteRoles[0].Account__r;
            return btrAccount != null ? btrAccount : null;
        } else {
            return null;
        }
    }

    private static List<SObject> updateRedispatchBillingModel(Meter__c meter, String redispatchBillingModel) {

        List<SObject> objectsToUpdate = new List<SObject>();

        if (meter.Current_Contract__r != null) {
            //Save redispatch billing model only when there is no existing value
            if (String.isBlank(meter.Current_Contract__r.Billing_Model_Redispatch__c)) {
                meter.Current_Contract__r.Billing_Model_Redispatch__c = redispatchBillingModel;
                objectsToUpdate.add(meter.Current_Contract__r);
            }
        }

        return objectsToUpdate;
    }

    private static List<Meter2GenerationUnitRelationship__c> getGUnitRelationships(Id meterId, Boolean includeFutureGuRelationships) {

        List<Meter2GenerationUnitRelationship__c> currentAndFutureGuRelationships = [
                SELECT
                        Generator_Unit__r.Name,
                        Generator_Unit__r.Unit_ID__c,
                        Generator_Unit__r.Manufacturer__c,
                        Generator_Unit__r.Manufacturer__r.Name,
                        Generator_Unit__r.Generator_Model__c,
                        Generator_Unit__r.Manufacturer_Number__c,
                        Generator_Unit__r.Installed_Capacity__c,
                        Generator_Unit__r.GPS_Location__Latitude__s,
                        Generator_Unit__r.GPS_Location__Longitude__s,
                        Generator_Unit__r.TR_ID__c,
                        Meter__c,
                        Meter__r.Name,
                        Meter__r.Installed_Capacity__c,
                        Meter__r.Alternative_Meter_ID__c,
                        Meter__r.DSO_Name__c,
                        Meter__r.SR_ID__c,
                        Meter__r.Balancing_Model_Redispatch__c,
                        Meter__r.Signal_Routing_Redispatch__c,
                        Meter__r.Current_Contract__c,
                        Meter__r.Current_Contract__r.Billing_Model_Redispatch__c,
                        Meter__r.Parent_Meter__c,
                        Meter__r.Parent_Meter__r.Name,
                        Meter__r.Parent_Meter__r.Installed_Capacity__c,
                        Meter__r.Parent_Meter__r.Alternative_Meter_ID__c,
                        Meter__r.Parent_Meter__r.DSO_Name__c,
                        Meter__r.Parent_Meter__r.SR_ID__c,
                        Meter__r.Parent_Meter__r.Balancing_Model_Redispatch__c,
                        Meter__r.Parent_Meter__r.Signal_Routing_Redispatch__c,
                        Meter__r.Parent_Meter__r.Current_Contract__c,
                        Meter__r.Parent_Meter__r.Current_Contract__r.Billing_Model_Redispatch__c,
                        SR_ID__c,
                        Valid_from__c,
                        Valid_to__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE (Meter__c = :meterId OR Meter__r.Parent_Meter__c = :meterId)
                AND (Valid_to__c = NULL OR Valid_to__c >= TODAY)
                AND (Active__c = TRUE OR Valid_from__c > TODAY)
                ORDER BY Generator_Unit__r.Name
        ];

        if (includeFutureGuRelationships) {
            return currentAndFutureGuRelationships;
        } else {
            List<Meter2GenerationUnitRelationship__c> currentGuRelationships = new List<Meter2GenerationUnitRelationship__c>();
            for (Meter2GenerationUnitRelationship__c m2g : currentAndFutureGuRelationships) {
                if (m2g.Valid_from__c <= Date.today()) {
                    currentGuRelationships.add(m2g);
                }
            }
            return currentGuRelationships;
        }
    }

    private static List<msUtility.LabelValuePair> getPickListValues(SObjectField field) {
        List<msUtility.LabelValuePair> options = new List<msUtility.LabelValuePair>();
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : picklistEntries) {
            options.add(new msUtility.LabelValuePair(f.getLabel(), f.getValue()));
        }
        return options;
    }

    private static void logActivity(MasterDataActivityLog masterDataActivityLog) {
        String changedDetailsJson = JSON.serialize(masterDataActivityLog, true);
        Logger.info(changedDetailsJson, masterDataActivityLog.parentMeterId);
        Logger.saveLog('Master Data update via customer portal');
    }

    public class MeterMasterData {
        @AuraEnabled public Id meterId { get; set; }
        @AuraEnabled public String meterName { get; set; }
        @AuraEnabled public Decimal meterCapacityMw { get; set; }
        @AuraEnabled public String alternativeMeterId { get; set; }
        @AuraEnabled public String dsoName { get; set; }
        @AuraEnabled public String SRId { get; set; }
        @AuraEnabled public String redispatchBalancingModel { get; set; }
        @AuraEnabled public String redispatchSignalRouting { get; set; }
    }

    public class GUnitMasterData {
        @AuraEnabled public String guId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String unitId { get; set; }
        @AuraEnabled public String manufacturer { get; set; }
        @AuraEnabled public String manufacturerNumber { get; set; }
        @AuraEnabled public String generatorModel { get; set; }
        @AuraEnabled public Decimal capacity { get; set; }
        @AuraEnabled public String coordinates { get; set; }
        @AuraEnabled public String TRId { get; set; }
        @AuraEnabled public String SRId { get; set; }
    }

    public class MasterDataWrapper {
        @AuraEnabled public MeterMasterData parentMeter { get; set; }
        @AuraEnabled public String redispatchBillingModel { get; set; }
        @AuraEnabled public String BTRName { get; set; }
        @AuraEnabled public String BTRId { get; set; }
        @AuraEnabled public List<GUnitMasterData> gUnits { get; set; }
        @AuraEnabled public List<msUtility.LabelValuePair> redispatchBillingModelOptions { get; set; }
        @AuraEnabled public Map<String, String> labels { get; set; }

        public MasterDataWrapper() {
            labels = new Map<String, String>{
                    'msMasterDataTableEEGPlantKey' => Label.msMasterDataTableEEGPlantKey,
                    'mMasterDataTableManufacturer' => Label.mMasterDataTableManufacturer,
                    'msMasterDataManufacturerNo' => Label.msMasterDataManufacturerNo,
                    'msMasterDataGeneratorModel' => Label.msMasterDataGeneratorModel,
                    'msMasterDataInstalledCapacity' => Label.msMasterDataInstalledCapacity,
                    'msMasterDataTrId' => Label.msMasterDataTrId,
                    'msMasterDataSrId' => Label.msMasterDataSrId,
                    'msMasterDataValidationMsg' => Label.msMasterDataValidationMsg,
                    'msMasterDataErrorMessage' => Label.msMasterDataErrorMessage,
                    'MasterDataChangeReqSubmittedMessage' => Label.MasterDataChangeReqSubmittedMessage
            };
        }
    }

    public class MasterDataChangeRequest {
        @AuraEnabled public String btrName { get; set; }
        @AuraEnabled public String btrId { get; set; }
    }

    private class MasterDataActivityLog {

        MasterDataActivityLog() {
            guIdToTrIdMap_old = new Map<Id, String>();
            guRelationshipIdToSrIdMap_old = new Map<Id, String>();
            guIdToTrIdMap_new = new Map<Id, String>();
            guRelationshipIdToSrIdMap_new = new Map<Id, String>();
        }

        public String parentMeterId { get; set; }
        public String redispatchBillingModel_old { get; set; }
        public String redispatchBillingModel_new { get; set; }
        public Map<Id, String> guIdToTrIdMap_old { get; set; }
        public Map<Id, String> guRelationshipIdToSrIdMap_old { get; set; }
        public Map<Id, String> guIdToTrIdMap_new { get; set; }
        public Map<Id, String> guRelationshipIdToSrIdMap_new { get; set; }
    }
}
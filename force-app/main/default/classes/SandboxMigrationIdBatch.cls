/**
 * @description       :
 * @author            : Dennis Grzyb
 * @group             :
 * @last modified on  : 2021-04-19
 * @last modified by  : Dennis Grzyb
 * Modifications Log
 * Ver   Date         Author         Modification
 * 1.0   2021-04-19   Dennis Grzyb   Initial Version
 **/
public with sharing class SandboxMigrationIdBatch extends BatchJobBase implements Database.Batchable<SObject>, Database.RaisesPlatformEvents, Database.Stateful {
    //Controls the dynamic part of our query.
    @TestVisible
    private String sobjectName;
    //Determines if we are disabling the Process Settings for the Object we update
    @TestVisible
    private String disabledSetting;
    @TestVisible
    private ProcessSettings__c setting;
    @TestVisible
    private Boolean settingWasInactive;
    //Controls the list index of SObjects to go through
    public Integer index;

    //The sobject names in fields.getMap() are all lower case --> we need to use the lower case notation too.
    public static final String FIELDNAME_SANDBOX_MIGRATION_ID = 'sandbox_migration_id__c';
    public static Map<String, String> MAP_DISABLED_PROCESSES = new Map<String, String>();
    public static final List<String> LIST_ALL_OBJECT_TYPES_TO_POPULATE = getAllSObjectNamesToUpdate();

    //Tests if the next Batch Job has been found so as to not trigger it.
    @TestVisible
    private static Boolean nextObjectFoundInTest = false;

    public static List<String> getAllSObjectNamesToUpdate() {
        List<String> sobjectNames = new List<String>();
        List<SandboxMigrationIdObject__mdt> sobjectsForBatchPopulation = [
            SELECT Id, ObjectName__c, DeactivatedProcessSetting__c
            FROM SandboxMigrationIdObject__mdt
            ORDER BY ObjectName__c ASC
        ];
        if (!sobjectsForBatchPopulation.isEmpty()) {
            for (SandboxMigrationIdObject__mdt smidObject : sobjectsForBatchPopulation) {
                sobjectNames.add(smidObject.ObjectName__c);
                MAP_DISABLED_PROCESSES.put(smidObject.ObjectName__c, smidObject.DeactivatedProcessSetting__c);
            }
        } else {
            throw new NoObjectFoundException('No Objects were found for Batch Population of Sandbox Migration Id.');
        }
        return sobjectNames;
    }

    public SandboxMigrationIdBatch() {
        this(0);
    }

    //This constructor can selectively be used for single runs of the Batch Job, also on Objects that might be running on Triggers otherwise.
    public SandboxMigrationIdBatch(String sobjectName) {
        //Check if SObjectType has Sandbox Migration Id Field
        if (!fflib_SObjectDescribe.getDescribe(sobjectName).getFields().containsKey(FIELDNAME_SANDBOX_MIGRATION_ID)) {
            throw new InvalidFieldException(
                'The SObject Type you have specified does not have a Sandbox_Migration_Id__c field.'
            );
        }

        this.sobjectName = sobjectName;
    }

    //This constructor will be called for our normal Batch Job chain.
    public SandboxMigrationIdBatch(Integer index) {
        this.index = index;
        String sobjectName;
        if (!LIST_ALL_OBJECT_TYPES_TO_POPULATE.isEmpty() && LIST_ALL_OBJECT_TYPES_TO_POPULATE.size() > index) {
            sobjectName = LIST_ALL_OBJECT_TYPES_TO_POPULATE[index];
        }
        if (sobjectName != null) {
            //Check if SObjectType has Sandbox Migration Id Field
            if (
                !fflib_SObjectDescribe.getDescribe(sobjectName).getFields().containsKey(FIELDNAME_SANDBOX_MIGRATION_ID)
            ) {
                throw new InvalidFieldException(
                    'The SObject Type you have specified does not have a Sandbox_Migration_Id__c field.'
                );
            }

            this.sobjectName = sobjectName;
            this.className = 'SandboxMigrationIdBatch for ' + this.sobjectName;
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        super.startLogging(BC?.getJobId());
        String baseQuery = 'SELECT Id, Sandbox_Migration_Id__c FROM {0} WHERE Sandbox_Migration_Id__c = null ORDER BY CreatedDate ASC';
        String formattedQuery = String.format(baseQuery, new List<String>{ this.sobjectName });

        disabledSetting = MAP_DISABLED_PROCESSES.get(this.sobjectName);
        if (disabledSetting != null) {
            setting = ProcessSettings__c.getInstance();
            settingWasInactive = setting.get(disabledSetting) == false;
            if (settingWasInactive) {
                super.logStartInformation(BC?.getJobId(), 'Found a Process Setting to deactivate: ' + disabledSetting);
                setting.put(disabledSetting, true);
                upsert setting;
            }
        }

        return Database.getQueryLocator(formattedQuery);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        super.logInformation(scope, BC?.getJobId(), 'Found ' + scope.size() + ' records.');

        //Avoid generic List<Sobject> to get proper Sandbox Migration Id in Generator
        Type sobjectListType = Type.forName('List<' + this.sobjectName + '>');
        List<Sobject> sobjectList = (List<SObject>) sobjectListType.newInstance();

        //This sobjectList now has the proper type innately available. getSObjectType() will return the actual SObject Type and NOT null.

        sobjectList.addAll(scope);

        SandboxMigrationIdGenerator.populate(sobjectList, true);

        super.logEndOfBatch(scope, BC?.getJobId(), true, 'Finished processing.');
    }

    public void finish(Database.BatchableContext BC) {
        //Reacticate Process Setting, we don't want it to stay inactive forever.
        if (disabledSetting != null && settingWasInactive) {
            super.logFinishInformation(BC?.getJobId(), 'Reactivating Process Setting: ' + disabledSetting);
            setting.put(disabledSetting, false);
            update setting;
        }
        //Iterate index up if it was used (only in Batch Chain)
        //If list size is still larger than index, then we can continue as there is another object to populate.
        if (this.index != null) {
            this.index++;
            if (LIST_ALL_OBJECT_TYPES_TO_POPULATE.size() > this.index) {
                SandboxMigrationIdBatch batchForNextObject = new SandboxMigrationIdBatch(this.index);
                batchForNextObject.batchJobScheduler = this.batchJobScheduler;
                batchForNextObject.ExecuteNextJob = true;
                batchForNextObject.jobId = this.jobId;
                batchForNextObject.scheduleId = this.scheduleId;
                batchForNextObject.enhancedLoggingEnabled = true;
                batchForNextObject.jobType = 'Batchable';

                Batch_Apex_Job__c sandboxMigrationIdJob = [
                    SELECT Id, Batch_Size__c
                    FROM Batch_Apex_Job__c
                    WHERE Batch_Class_Name__c = 'SandboxMigrationIdBatch' AND Enabled__c = TRUE
                    LIMIT 1
                ];
                integer batchSize = 200;
                if (sandboxMigrationIdJob != null) {
                    batchSize = Integer.valueOf(sandboxMigrationIdJob.Batch_Size__c);
                }
                if (!Test.isRunningTest()) {
                    ((BatchJobBase) batchForNextObject).enqueue(batchSize);
                }

                nextObjectFoundInTest = true;

                //this ensures that we get a log for each run of the Batch Job without skipping directly to the next Batch
                this.executeNextJob = false;
            }
            //will continue to next job group if the last Batch in chain has run, and otherwise only log the result.
            super.finishBatch(BC.getJobId());
        }
    }

    public class InvalidFieldException extends Exception {
    }
    public class NoObjectFoundException extends Exception {
    }
}
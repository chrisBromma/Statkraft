/**
 * This class is part of the sfdx-batch-orchestrator package, released under the MIT license.
 *
 * @description       : Apex Controller responsible for Running a Single Apex Job from the Related List.
 * @author            : dschibster
 * @group             : Batch Job Management
 * @last modified on  : 2021-08-27
 * @last modified by  : dschibster
 **/

public with sharing class RunBatchApexJobController {
    BatchJobBase batchJobToRun;
    Batch_Apex_Job__c jobRecord;
    public static final List<String> REQUIRED_FIELDS_APEX_JOB = new List<String>{
        'Batch_Class_Name__c',
        'Batch_Job_Schedule__c',
        'EnhancedLogging__c',
        'Batch_Size__c',
        'RecordType.DeveloperName'
    };

    public RunBatchApexJobController(ApexPages.StandardController stdCtrl) {
        if (!Test.isRunningTest()) {
            stdCtrl.addFields(REQUIRED_FIELDS_APEX_JOB);
        }
        Batch_Apex_Job__c batchApexJob = (Batch_Apex_Job__c) stdCtrl.getRecord();

        batchJobToRun = (BatchJobBase) Type.forName(batchApexJob.Batch_Class_Name__c).newInstance();
        batchJobToRun.jobType = batchApexJob.RecordType.DeveloperName;
        batchJobToRun.executeNextJob = false;
        batchJobToRun.jobId = batchApexJob.Id;
        batchJobToRun.scheduleId = batchApexJob.Batch_Job_Schedule__c;
        batchJobToRun.className = batchApexJob.Batch_Class_Name__c;
        batchJobToRun.enhancedLoggingEnabled = batchApexJob.EnhancedLogging__c;

        jobRecord = batchApexJob;
    }

    public PageReference runJob() {
        batchJobToRun.enqueue(Integer.valueOf(jobRecord.Batch_Size__c));
        PageReference ref = new PageReference('/' + jobRecord.Batch_Job_Schedule__c);
        ref.setRedirect(true);
        return ref;
    }

    @InvocableMethod(label='Run Single Apex Job in Scheduler' category='Apex Scheduler')
    public static void runBatchApexJob(Input[] input) {
        //Let's trust that we are not running Batch Jobs from more than one flow interview at a time.
        Id batchApexId = input[0].recordId;
        String query = String.format(
            'SELECT {0} FROM Batch_Apex_Job__c WHERE Id = :batchApexId',
            new List<String>{ String.join(REQUIRED_FIELDS_APEX_JOB, ',') }
        );
        Batch_Apex_Job__c apexJob = (Batch_Apex_Job__c) Database.query(query);
        RunBatchApexJobController ctrl = new RunBatchApexJobController(new ApexPages.StandardController(apexJob));
        ctrl.runJob();
    }

    public class Input {
        @InvocableVariable(label='Id of the Batch Apex Job record you want to run' required=true)
        public String recordId;
    }
}
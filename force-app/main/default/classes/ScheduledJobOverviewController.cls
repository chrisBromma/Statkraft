public without sharing class ScheduledJobOverviewController {
    public List<ScheduledApexJob> scheduledApexJobs { get; set; }
    public List<ScheduledFlow> scheduledFlows { get; set; }
    public List<ScheduledMassAction> scheduledMassActions { get; set; }

    Map<Id, CronTrigger> cronTriggerMap = new Map<Id, CronTrigger>();
    Map<Id, CronTrigger> massActionMap = new Map<Id, CronTrigger>();
    Map<Id, CronTrigger> flowMap = new Map<Id, CronTrigger>();


    public static final String CRONTRIGGER_JOBTYPE_SCHEDULED_APEX = '7';
    public static final String CRONTRIGGER_JOBTYPE_SCHEDULED_FLOW = '6';

    public ScheduledJobOverviewController() {
        cronTriggerMap = retrieveCronTriggerMap();
        structureCronTriggers();
        getScheduledApexJobs();
        getScheduledMassActions();
        getScheduledFlows();

    }

    private Map<Id, CronTrigger> retrieveCronTriggerMap() {
        Map<Id, CronTrigger> result = new Map<Id, CronTrigger>(
            [
                SELECT
                    Id,
                    CronExpression,
                    CronJobDetailId,
                    NextFireTime,
                    PreviousFireTime,
                    StartTime,
                    EndTime,
                    State,
                    TimesTriggered,
                    CronJobDetail.Name, 
                    CronJobDetail.JobType
                FROM CronTrigger
                WHERE CronJobDetail.JobType IN (:CRONTRIGGER_JOBTYPE_SCHEDULED_APEX, :CRONTRIGGER_JOBTYPE_SCHEDULED_FLOW)
            ]
        );

        return result;
    }

    private void structureCronTriggers(){
        for(CronTrigger ct : cronTriggerMap.values()){
            if(ct.CronJobDetail.Name.startsWith('MA_MassAction')){
                List<String> dividedName = ct.CronJobDetail.Name.split('_');
                massActionMap.put(dividedName[dividedName.size()-1], ct);
            }
            if(ct.CronJobDetail.JobType == '6'){
                flowMap.put(ct.Id, ct);
            }
        }
    }

    private void getScheduledApexJobs() {

        scheduledApexJobs = new List<ScheduledApexJob>();

        List<Batch_Job_Schedule__c> batchJobSchedules = [
            SELECT Id, Name, Cron_Trigger_Id__c, Cron_Expression__c, RecordType.Name
            FROM Batch_Job_Schedule__c
            WHERE Cron_Trigger_Id__c != null
            ORDER BY Name, CreatedDate
            LIMIT 2000
        ];

        for (Batch_Job_Schedule__c sch : batchJobSchedules) {
            if (cronTriggerMap.containsKey(sch.Cron_Trigger_Id__c)) {
                scheduledApexJobs.add(new ScheduledApexJob(sch, cronTriggerMap.get(sch.Cron_Trigger_Id__c)));
            }
        }

    }

    private void getScheduledMassActions() {
        scheduledMassActions = new List<ScheduledMassAction>();
       
        if(!massActionMap.isEmpty()){
            List<Mass_Action_Configuration__c> configurations = [
                SELECT Id, Name
                FROM Mass_Action_Configuration__c
                WHERE Schedule_Frequency__c IN ('Scheduled', 'Custom')
                AND Active__c = true
            ];

            for(Mass_Action_Configuration__c ma : configurations){
                if(massActionMap.containsKey(ma.Id)){
                    scheduledMassACtions.add(new ScheduledMassAction(ma, massActionMap.get(ma.Id)));
                }
            }
        }
    }

    public void getScheduledFlows(){
        scheduledFlows = new List<ScheduledFlow>();
        if(!flowMap.isEmpty()){
            for(CronTrigger ct : flowMap.values()){
                scheduledFlows.add(new ScheduledFlow(ct.CronJobDetail.Name, ct));
            }
        }
    }

    public class ScheduledMassAction {
        public Mass_Action_Configuration__c config {get; set;}
        public CronTrigger CronTrigger {get; set;}

        public ScheduledMassAction(Mass_Action_Configuration__c config, CronTrigger schedule){
            this.config = config;
            this.CronTrigger = schedule;
        }
    }

    public class ScheduledFlow {
        public String name {get; set;}
        public CronTrigger CronTrigger {get; set;}

        public ScheduledFlow(String name, CronTrigger schedule){
            this.name = name;
            this.CronTrigger = schedule;
        }
    }
}
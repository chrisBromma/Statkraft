/*
Copyright (c) Ian Huang Salesforce
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.
*/

public inherited sharing class GlobalConstants {
    
    public static Id SCHEDULER_RECORD_TYPE_HOURLY_JOB  = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Hourly_Job').Id;
    public static Id SCHEDULER_RECORD_TYPE_DAILY_JOB   = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Daily_Job').Id;
    public static Id SCHEDULER_RECORD_TYPE_WEEKLY_JOB  = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Weekly_Job').Id;
    public static Id SCHEDULER_RECORD_TYPE_MONTHLY_JOB = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Monthly_Job').Id;
    public static Id SCHEDULER_RECORD_TYPE_YEARLY_JOB  = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Yearly_Job').Id;
    public static Id SCHEDULER_RECORD_TYPE_CUSTOM_CRON_EXPRESSION_JOB = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Custom_Cron_Expression_Job').Id;
    public static Id SCHEDULER_RECORD_TYPE_EXISTING_SCHEDULED_JOB_JOB = Application.RecordTypes.byDeveloperName('Batch_Job_Schedule__c','Existing_Scheduled_Job').Id;

}
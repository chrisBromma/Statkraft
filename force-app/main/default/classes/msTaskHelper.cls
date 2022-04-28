public with sharing class msTaskHelper {

    public static void validateAMCTasks(Map<Id, Task> oldTasksByIds, List<Task> newTasks) {
        if(UserInfo.getProfileId() != [SELECT Id FROM Profile WHERE Name = 'KAM AMC' LIMIT 1].Id) {
            Map<String, Account_KAM_Tasks_Configuration__mdt> configMap = getAccountKamTasksConfigurationsBySubjects();
            for(Task t : newTasks) {
                if(configMap.containsKey(t.Subject) && oldTasksByIds.get(t.Id).ActivityDate != t.ActivityDate
                        && oldTasksByIds.get(t.Id).OwnerId == t.OwnerId) {
                    t.addError(Label.Task_Deadline_AMC_Error_Message);
                }
            }
        }
    }

    public static Map<String, Account_KAM_Tasks_Configuration__mdt> getAccountKamTasksConfigurationsBySubjects() {
        Map<String, Account_KAM_Tasks_Configuration__mdt> taskConfigByTaskSubjectMap = new Map<String, Account_KAM_Tasks_Configuration__mdt>();
        for(Account_KAM_Tasks_Configuration__mdt config : [
                SELECT Id, Subject__c, Description__c, Deadline_in_days__c, Priority__c, Send_Notification__c
                FROM Account_KAM_Tasks_Configuration__mdt
        ]) {
            taskConfigByTaskSubjectMap.put(config.Subject__c, config);
        }
        return taskConfigByTaskSubjectMap;
    }

    public static Task extractTaskFromKAMConfig(Account_KAM_Tasks_Configuration__mdt config) {
        Task kamTask = new Task();
        kamTask.Subject = config.Subject__c;
        kamTask.Description = config.Description__c;
        kamTask.ActivityDate = Date.today().addDays(Integer.valueOf(config.Deadline_in_days__c));
        kamTask.Priority = config.Priority__c;
        return kamTask;
    }

    public static Task extractTaskFromKAMConfig(Id newOwnerId, Id accId, Account_KAM_Tasks_Configuration__mdt config) {
        Task kamTask = extractTaskFromKAMConfig(config);
        kamTask.OwnerId = newOwnerId;
        kamTask.WhatId = accId;
        return kamTask;
    }
}
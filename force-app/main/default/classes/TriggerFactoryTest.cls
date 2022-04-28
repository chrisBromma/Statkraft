@isTest
public with sharing class TriggerFactoryTest {
    @isTest
    static void executeDummyTrigger_throwException() {
        Exception ex;
        if (TriggerMapping.getInstance().containsKey('LEAD')) {
            TriggerMapping.getInstance().remove('LEAD');
        }
        try {
            TriggerFactory.executeTriggerHandlers(Lead.SObjectType);
        } catch (Exception e) {
            ex = e;
        }
        System.assert(ex != null, 'TriggerException was not thrown');
    }

    @isTest
    static void executeDummyTrigger() {
        TriggerMapping.getInstance().put('LEAD', new List<String>{ 'TriggerHandlerExtension' });
        try {
            TriggerFactory.executeTriggerHandlers(Lead.SObjectType);
        } catch (Exception e) {
            //supposed to fail gracefully as soon as we don't have a Trigger for Leads.
        }
    }

    @isTest
    static void executeDummyFactoryMethods() {
        //Dependency Inject into the Trigger Factory in order to have our methods run even though they are not called via Trigger
        TriggerMapping.getInstance().put('LEAD', new List<String>{ 'TriggerHandlerExtension' });
        List<ITrigger> triggerHandlers = TriggerFactory.getHandlers(Lead.SObjectType);
        ITrigger handler = triggerHandlers[0];

        //to inject into the triggerNew/triggerOld parameters.
        Lead testLead = new Lead(LastName = 'Test', Company = 'mindsquare');
        List<Lead> leadList = new List<Lead>{ testLead };
        insert leadList;
        Map<Id, Lead> leadMap = new Map<Id, Lead>(leadList);

        TriggerFactory.execute(handler, 'BEFORE_INSERT', leadList, null);
        TriggerFactory.execute(handler, 'BEFORE_DELETE', null, leadMap);
        TriggerFactory.execute(handler, 'BEFORE_UPDATE', leadList, leadMap);
        TriggerFactory.execute(handler, 'AFTER_INSERT', leadList, null);
        TriggerFactory.execute(handler, 'AFTER_DELETE', null, leadMap);
        TriggerFactory.execute(handler, 'AFTER_UPDATE', leadList, leadMap);
        TriggerFactory.execute(handler, 'AFTER_UNDELETE', leadList, leadMap);
    }

    @isTest
    static void testDataLoaderUsageIsPrevented() {
        //no visualforce, no UserId (because Connected App)
        String dummyRequestUrl = 'Soap/';

        User standardUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard Origination' AND isActive = TRUE LIMIT 1];
        Exception ex;
        System.runAs(standardUser) {
            try {
                TriggerFactory.preventDataLoaderUsage(dummyRequestUrl);
            } catch (Exception e) {
                ex = e;
            }
        }
        System.assert(ex != null, 'Data Loader usage was not prevented');
    }

    @isTest
    static void testDataLoaderUsageIsNotPrevented() {
        //no visualforce, no UserId (because Connected App)
        String dummyRequestUrl = 'Soap/';

        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        msTestDataFactory.activateCustomPerm(u.Id, 'Can_Use_Dataloader');

        Exception ex;
        System.runAs(u) {
            try {
                TriggerFactory.preventDataLoaderUsage(dummyRequestUrl);
            } catch (Exception e) {
                ex = e;
            }
        }

        System.assert(ex == null, 'Data Loader usage was prevented, although executed as Administrator');
    }
}
/**
 * @description       : Used to create Migration Ids for SObjects that need them populated for Sandbox Seeding
 * @author            : Dennis Grzyb
 * @group             : 
 * @last modified on  : 2021-04-14
 * @last modified by  : Dennis Grzyb
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   2021-04-14   Dennis Grzyb   Initial Version
**/


public without sharing class SandboxMigrationIdGenerator {

    /**
    * Create a Sandbox Migration Id for new SObjects based on the Sandbox Migration Setting (called like the SObject)
    * Only applies to data that doesn't already have a populated Migration Id 
    * @author Dennis Grzyb | 2021-04-14 
    * @param sobjects --> The SObjects you want to have the Ids populated for
    * @param dmlUpdate --> Leave this false if you are in Before Insert Context, true if you want the method to do the updating.
    **/
    public static void populate(List<SObject> sobjects, Boolean dmlUpdate) {
        if (sobjects.getSObjectType() == null) {
            throw new MigrationIdGeneratorException('You have not specified a clear SObject Type for the Generation of a Sandbox Migration Id. Please type your List correctly before using the populate() command.');
        }
        String sobjectName = sobjects.getSObjectType().getDescribe().getName();
        SandboxMigrationSettings__c setting = SandboxMigrationSettings__c.getInstance(sobjectName);

        /**
         * This if-clause should ideally only be reached on fresh Sandboxes, so that we don't hinder production of data on them
         * If you want to create a Migration Id for a new Object, it's HIGHLY suggested to create the setting beforehand.
         */
        if (setting == null) {
            setting = new SandboxMigrationSettings__c(Name = sobjectName, RunningNumber__c = 0, Prefix__c = sobjectName.left(3).toUpperCase() + '_');
        }

        String preFix = setting.Prefix__c;
        Integer currentNumber = Integer.valueOf(setting.RunningNumber__c);

        for (SObject sObj : sobjects) {
            //If we have a preset Sandbox Migration Id, we do nothing. Otherwise: Increase iterator and set Id on Object.
            if (sObj.get('Sandbox_Migration_Id__c') == null) {
                currentNumber++;
                String newMigrationId = preFix + String.valueOf(currentNumber).leftPad(18, '0');
                sObj.put('Sandbox_Migration_Id__c', newMigrationId);
            }
        }

        /**
         * No usage of Unit of Work to maintain dynamic entry of new Objects to track 
         * without needing to insert them into the Unit of Work SObject List.
         */

        if (currentNumber != setting.RunningNumber__c) {
            setting.RunningNumber__c = currentNumber;
            upsert setting;
        }

        if (dmlUpdate) {
            update sobjects;
        }
    }

    public class MigrationIdGeneratorException extends Exception {
    }
}
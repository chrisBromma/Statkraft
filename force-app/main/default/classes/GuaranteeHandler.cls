/**
 * Created by Steffen Naundorf on 07.09.2021.
 */

public without sharing class GuaranteeHandler extends TriggerHandlerExtension {
    public static Map<Id, Security_Limits__c> limits = new Map<Id, Security_Limits__c>();
    public static Map<Id, Boolean> modifiedLimits = new Map<Id, Boolean>();

    public GuaranteeHandler() {
        super();
    }

    // This TriggerHandler is currently only here to calculate Rollups (which is done prior the Handler even being called). Future additions may override methods for actual functionality.
}
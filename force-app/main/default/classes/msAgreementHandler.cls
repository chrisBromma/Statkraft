/****************************************************************************************************
* Class msAccountHandler
*
*   Create By	:   Mandy Bebenroth (mindsquare GmbH)
*   Create Date	:   14.05.2020
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                          	Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Mandy Bebenroth (mindsquare GmbH)		14.05.2020       	Init version.
*****************************************************************************************************/

public without sharing class msAgreementHandler extends TriggerHandlerExtension {


    // Constructor
    public msAgreementHandler() {
        super();

    }

    public override void afterInsert(SObject obj) {
        if (isDisabled) {
            return;
        } else {
            addToLoopCount();
        }
        Apttus__APTS_Agreement__c agreement = (Apttus__APTS_Agreement__c) obj;
        if (agreement.Contract__c != null) {
            msAgreementHelper.generateAgreementConnections(agreement);
            msAgreementHelper.populateAgreement(agreement);
        }

    }


    public override void afterUpdate(SObject oldObj, SObject obj) {
        if (isDisabled) {
            return;
        } else {
            addToLoopCount();
        }
        Apttus__APTS_Agreement__c agreementOld = (Apttus__APTS_Agreement__c) oldObj;
        Apttus__APTS_Agreement__c agreement = (Apttus__APTS_Agreement__c) obj;
        if(agreement.Contract__c!=null){
            if(agreement.Apttus__Status__c=='Activated' && agreementOld.Apttus__Status__c != agreement.Apttus__Status__c){
                msAgreementHelper.updateContract(agreement, agreementOld);
            }
            if (agreementOld.Contract__c != agreement.Contract__c) {
                msAgreementHelper.generateAgreementConnections(agreement);
            }
        }

    }

    public override void andFinally() {
        if (isDisabled) {
            return;
        }

    }
}
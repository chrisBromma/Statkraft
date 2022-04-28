/**
* @Name: APTS_RecallSignaturesController
* @Author: APTTUS
* @CreateDate: 13th Jan 2021
* @Description: Controller to call Adobe ESign - Recall Signature.
* @modified by: Sreenath, added as part of SCQ-113
-----------------------------------------------------------------------------------------------
**/

public class APTS_RecallSignaturesController {
    
    private final Apttus__APTS_Agreement__c agreement;
    private String instanceURL = null;
    
    public PageReference redirect(){
        
        Apttus__ComplySystemProperties__c csValue = Apttus__ComplySystemProperties__c.getValues('System Properties');
        if(csValue != null){
            instanceURL = csValue.Apttus__InstanceUrl__c;
        }
        List<echosign_dev1__SIGN_Agreement__c> cancelREcords = [SELECT id from echosign_dev1__SIGN_Agreement__c 
                                                                WHERE Apttus_Echosign__Apttus_Agreement__c =: agreement.id 
                                                                AND echosign_dev1__Status__c =: APTS_Constants.OUT_OF_SIGNATURE ];
        if(cancelREcords.size() > 0){
            try{                
                for(echosign_dev1__SIGN_Agreement__c rec : cancelREcords ){
                    echosign_dev1.EchoSignApiService.cancelDocument(rec.id);
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Signature Recalled'));
                //Added as part of SCQ-113 request
                agreement.APTS_Recall_Signature_Flag__c = true;
                update agreement;
            }catch(Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
            System.debug('Completed') ;
        }
        //Added else block as part of SCQ-113 request
        else {
            agreement.Apttus__Status__c = 'Signatures Recalled';
            agreement.Apttus__Status_Category__c = 'In Signatures';
            update agreement;
        }
        PageReference returnTo = new PageReference(instanceURL + '/' + agreement.id);
        returnTo.setRedirect(true);
        return returnTo;
    }
    
    public APTS_RecallSignaturesController( ApexPages.StandardController stdController){
        this.agreement = (Apttus__APTS_Agreement__c)stdController.getRecord();
    }
    
    
}
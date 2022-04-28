public class UnitOfWork extends fflib_SObjectUnitOfWork{
    
    public UnitOfWork() {
        super(new List<SObjectType>{
            Account.SObjectType,
            Contact.SObjectType,
            Opportunity.SObjectType,
            //Contract Mgmt
            Offer__c.SObjectType,
            Ammendment__c.SObjectType,
            //Market Access
            Contract__c.SObjectType,
            Case.SObjectType,
            Meter__c.SObjectType,
            Generation_Unit__c.SObjectType,
            Meter2GenerationUnitRelationship__c.SObjectType,
            Generation_Unit_Ownership__c.SObjectType,
            MeterRegistration__c.SObjectType,
            Site_Role__c.SObjectType,
            Contract_Role__c.SObjectType,
            Pricing_Component__c.SObjectType,
            //Bryt and Portal
            Bryt_Reference_Capacity__c.SObjectType,
            PortalSettings__c.SObjectType,
            //NPAI
            NPC_Cases__c.SObjectType,
            NPAI_Container__c.SObjectType,
            NPC_Survey__c.SObjectType,
            NPC_Assessment__c.SObjectType,
            //Could depend on everything
            Task.SObjectType,
            Entity__c.SObjectType,
            Generator_Type__c.SObjectType,
            User.SObjectType
        });
    }

    public UnitOfWork(List<SObjectType> sobjectTypes){
        super(sobjectTypes);
    }

    public List<SObjectType> getSObjectTypeList(){
        return this.m_sObjectTypes;
    }
}
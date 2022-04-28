public class Application {
    
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
				new UnitOfWork().getSObjectTypeList());

    public static final RecordTypeCachedProvider RecordTypes = RecordTypeCachedProvider.getInstance();

    public static final fflib_Application.SelectorFactory Selector = new fflib_Application.SelectorFactory(
        new Map<SObjectType, Type> {
            Account.SObjectType => AccountSelector.class,
            Case.SObjectType => CaseSelector.class,
            ContentDocument.SObjectType => ContentDocumentSelector.class,
            ContentVersion.SObjectType => ContentVersionSelector.class,
            ContentDocumentLink.SObjectType => ContentDocumentLinkSelector.class,
            CombinedAttachment.SObjectType => CombinedAttachmentSelector.class,
            Contract__c.SObjectType => ContractSelector.class,
            CountryContactDetails__c.SObjectType => CountryContactDetailsSelector.class,
            EmailTemplate.SObjectType => EmailTemplateSelector.class,
            Generation_Unit__c.SObjectType => GenerationUnitSelector.class,
            KAM_Documents_Link__c.SObjectType => KAMDocumentsLinkSelector.class,
            Meter__c.SObjectType => MeterSelector.class,
            MeterRegistration__c.SObjectType => MeterRegistrationSelector.class,
            NPC_Assessment__c.SObjectType => NPAIAssessmentSelector.class,
            NPC_Cases__c.SObjectType => NPAICaseSelector.class,
            NPAI_Container__c.SObjectType => NPAIContainerSelector.class,
            OrgWideEmailAddress.SObjectType => OrgWideEmailAddressSelector.class,
            PortalSettings__c.SObjectType => PortalSettingSelector.class,
            Pricing_Component__c.SObjectType => PricingComponentSelector.class,
            Product_Need_Link__c.SObjectType => ProductNeedLinkSelector.class,
            msUserNotificationSetting__c.SObjectType => UserNotificationSettingsSelector.class,
            User.SObjectType => UserSelector.class,
                Task.SObjectType => TaskSelector.class
        });
    
}
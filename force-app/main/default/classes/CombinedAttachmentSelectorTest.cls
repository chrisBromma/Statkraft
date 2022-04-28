@isTest
private class CombinedAttachmentSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        CombinedAttachmentSelector caSelector = (CombinedAttachmentSelector) Application.Selector.newInstance(CombinedAttachment.SObjectType);
        System.assertEquals('CombinedAttachment', String.valueOf(caSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        CombinedAttachmentSelector caSelector = (CombinedAttachmentSelector) Application.Selector.newInstance(CombinedAttachment.SObjectType);
        System.assertEquals(5, caSelector.getSObjectFieldList().size());
    }
}
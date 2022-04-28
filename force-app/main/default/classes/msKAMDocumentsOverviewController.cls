/****************************************************************************************************
* Class msKAMDocumentsOverviewController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   13.10.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   13.10.2020      	    Init version.
*****************************************************************************************************/

public with sharing class msKAMDocumentsOverviewController {

    @AuraEnabled
    public static KAMDocumentsWrapper getItems(Id recordId) {
        KAMDocumentsWrapper result = new KAMDocumentsWrapper();


        List<KAM_Documents_Link__c> allLinks = [
                SELECT Id, Name, Url__c, Description__c, Category__c, SubCategory__c, (SELECT Id, Product_Need__c FROM Product_Need_Link__r)
                FROM KAM_Documents_Link__c
                WHERE IsActive__c = true
        ];
        List<KAM_Documents_Link__c> documentsLinks = new List<KAM_Documents_Link__c>();

        Map<String, SubCategory> subCategoryMap = new Map<String, SubCategory>();
        Map<String, Category> categoryMap = new Map<String, Category>();

        String objectType = 'General';
        if (recordId != null) {
            objectType = recordId.getSobjectType().getDescribe().getName();

            List<Product_Need_Link__c> existingLinks = msKAMProductNeedSelectorController.getLinks(recordId);
            Set<Id> productNeedIds = new Set<Id>();
            for (Product_Need_Link__c tmpLink : existingLinks) {
                productNeedIds.add(tmpLink.Product_Need__c);
            }

            for (KAM_Documents_Link__c tmpLink : allLinks) {
                if (tmpLink.Product_Need_Link__r.size() != 0) {
                    for (Product_Need_Link__c tmpPNLink : tmpLink.Product_Need_Link__r) {
                        if (productNeedIds.contains(tmpPNLink.Product_Need__c)) {
                            documentsLinks.add(tmpLink);
                            break;
                        }
                    }
                } else {
                    documentsLinks.add(tmpLink);
                }
            }
        } else {
            documentsLinks = allLinks;
        }


        for (KAM_Documents_Link__c tmpLink : documentsLinks) {
            for (String categoryPart : tmpLink.Category__c.split(';')) {
                if (tmpLink.SubCategory__c == null) {
                    tmpLink.SubCategory__c = '';
                }
                String key = categoryPart + tmpLink.SubCategory__c;
                SubCategory tmpSubCategory = subCategoryMap.get(key);
                if (tmpSubCategory == null) {
                    tmpSubCategory = new SubCategory();
                    tmpSubCategory.category = categoryPart;
                    tmpSubCategory.title = tmpLink.SubCategory__c;
                    tmpSubCategory.isOpen = false;
                    tmpSubCategory.items = new List<Item>();
                }
                Item tmpItem = new Item(tmpLink);
                tmpItem.category = categoryPart;
                tmpSubCategory.items.add(tmpItem);

                subCategoryMap.put(key, tmpSubCategory);
            }
        }

        for (SubCategory tmpSubCategory : subCategoryMap.values()) {
            Category tmpCategory = categoryMap.get(tmpSubCategory.category);
            if (tmpCategory == null) {
                tmpCategory = new Category();
                tmpCategory.title = tmpSubCategory.category;
                tmpCategory.isOpen = false;
                if (tmpSubCategory.category.contains(objectType)) {
                    tmpCategory.isOpen = true;
                }
                tmpCategory.subcategories = new List<SubCategory>();
            }

            tmpCategory.subcategories.add(tmpSubCategory);
            categoryMap.put(tmpSubCategory.category, tmpCategory);
        }
        result.files = categoryMap.values();


        Profile userProfile = [Select Name from Profile where Id = :UserInfo.getProfileId()];
        if (userProfile.Name == 'KAM AMC' || userProfile.Name == 'System Administrator') {
            result.allowEdit = true;
        }

        return result;
    }

    @AuraEnabled
    public static void deleteItem(Id recordId) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        if (objectType == 'KAM_Documents_Link__c') {
            KAM_Documents_Link__c entry = new KAM_Documents_Link__c();
            entry.Id = recordId;
            delete entry;
        }
    }

    @AuraEnabled
    public static void countView(Id recordId) {
        KAM_Documents_Link__c documentsLink = [
                SELECT Id, Name, Views__c
                FROM KAM_Documents_Link__c
                WHERE Id = :recordId
        ];
        if (documentsLink.Views__c == null) {
            documentsLink.Views__c = 0;
        }
        documentsLink.Views__c = documentsLink.Views__c + 1;
        update documentsLink;
    }

    @AuraEnabled
    public static void addProducts(Id documentId, List<Product_Need__c>newUnsavedProductNeeds) {
        List<Product_Need_Link__c>existingLinks = [
                SELECT Id, Account__c, Opportunity__c, KAM_Documents_Link__c, Product_Need__c,
                        Product_Need__r.Country__c, Product_Need__r.Product_Line__c,
                        Product_Need__r.Product_Category__c, Product_Need__r.Product__c, Product_Need__r.Product_Owner__c, Product_Need__r.IsActive__c
                FROM Product_Need_Link__c
                WHERE KAM_Documents_Link__c = :documentId
                AND Product_Need__c IN :newUnsavedProductNeeds
        ];
        Set<String> duplicateCheck = new Set<String>();
        for (Product_Need_Link__c tmpLink : existingLinks) {
            duplicateCheck.add(tmpLink.Product_Need__c + '' + tmpLink.KAM_Documents_Link__c);
        }

        List<Product_Need_Link__c> linksToInsert = new List<Product_Need_Link__c>();
        for (Product_Need__c tmProductNeed : newUnsavedProductNeeds) {
            if (duplicateCheck.contains(newUnsavedProductNeeds + '' + documentId)) {
                throw new AuraHandledException('There is already a link for this product need');
            }

            Product_Need_Link__c newProductNeedLink = new Product_Need_Link__c();
            newProductNeedLink.Product_Need__c = tmProductNeed.Id;
            newProductNeedLink.KAM_Documents_Link__c = documentId;
            linksToInsert.add(newProductNeedLink);
        }
        insert linksToInsert;
    }


    public static String formatURL(String urlString) {
        if (urlString.contains('sharepoint.com')) {
            urlString = urlString.left(urlString.indexOf('?'));
        }
        return urlString;
    }

    public static String getType(String urlString) {
        if (urlString.contains('.pdf'))
            return 'doctype:pdf';
        if (urlString.contains('.xls') || urlString.contains('.xlsx'))
            return 'doctype:excel';
        if (urlString.contains('.ppt') || urlString.contains('.pptx'))
            return 'doctype:ppt';
        if (urlString.contains('.doc') || urlString.contains('.docx'))
            return 'doctype:word';
        return 'doctype:link';
    }

    public class Category {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public Boolean isOpen { get; set; }
        @AuraEnabled public List<SubCategory> subcategories { get; set; }
    }
    public class SubCategory {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public Boolean isOpen { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public List<Item> items { get; set; }
    }
    public class KAMDocumentsWrapper {
        @AuraEnabled public List<Category> files { get; set; }
        @AuraEnabled public Boolean allowEdit { get; set; }
    }
    public class Item {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String subcategory { get; set; }

        public Item(KAM_Documents_Link__c entry) {
            title = entry.Name;
            id = entry.Id;
            subcategory = entry.SubCategory__c;
            url = formatURL(entry.Url__c);
            description = entry.Description__c;
            type = getType(url);
        }
    }
}
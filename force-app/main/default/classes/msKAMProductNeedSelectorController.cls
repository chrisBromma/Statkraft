/****************************************************************************************************
 * Class msKAMProductNeedSelectorController
 *
 *   Create By	:   Steffen Naundorf (mindsquare GmbH)
 *   Create Date	:   21.10.2020
 *   Description	:
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	   Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Steffen Naundorf (mindsquare GmbH)   21.10.2020      	    Init version.
 *****************************************************************************************************/

public without sharing class msKAMProductNeedSelectorController {
    public static boolean disableOpportunityTriggerToUpdateLinks = false;

    @AuraEnabled
    public static ProductNeedControllerWrapper getProductMatrix(Id recordId) {
        ProductNeedControllerWrapper result = new ProductNeedControllerWrapper();
        result.hasProducts = false;

        String marketPresence;
        if (recordId.getSobjectType() == Account.SObjectType) {
            marketPresence = [SELECT Id, Market_Presence__c From Account WHERE Id = :recordId].Market_Presence__c;
        }
        if (recordId.getSobjectType() == Opportunity.SObjectType) {
            marketPresence = [SELECT Id, Account.Market_Presence__c From Opportunity WHERE Id = :recordId].Account.Market_Presence__c;
        }
        if (marketPresence == null)marketPresence = '';


        try {
            //we need to get picklist values dependig on the controlling field. There are two different approaches.
            // Both return the same results, but unfortunately sometimes, the approches don't work and fail.
            // There is no clear indicator when which approach works. #1 works nearly everytime on prod, but fails often on sandboxes.
            result.productCategoryPicklistValues = getDependentPicklistValuesForProductCategory();
        } catch (Exception e) {
            result.productCategoryPicklistValues = getDependentPicklistValuesForProductCategory2();
        }


        List<String>countryPicklistValues = getPicklistValuesForCountry();
        result.countryPicklistValues=new List<String>();
        result.countryPicklistValuesMarketPresence=new List<String>();
        for(String country:countryPicklistValues){
            if(marketPresence.contains(country)){
                result.countryPicklistValuesMarketPresence.add(country);
            }else{
                result.countryPicklistValues.add(country);
            }
        }

        result.productLinePicklistValues = result.productCategoryPicklistValues.keySet();

        List<Product_Need__c> productNeeds = [
            SELECT Id, Country__c, Parent_Product_Need__c, Product_Category__c, Product_Line__c, Product__c, Name
            FROM Product_Need__c
            WHERE IsActive__c = TRUE
        ];
        Map<String, Product> productMap = new Map<String, Product>();
        Map<String, ProductCategory> productCategoryMap = new Map<String, ProductCategory>();
        Map<String, ProductLine> productLineMap = new Map<String, ProductLine>();
        Map<String, Country> countryMap = new Map<String, Country>();

        for (Product_Need__c productNeed : productNeeds) {
            String productId = productNeed.Country__c + productNeed.Product_Line__c + productNeed.Product_Category__c;

            Product product = productMap.get(productId);
            if (product == null) {
                product = new Product();
                product.productCategory = productNeed.Product_Category__c;
                product.productLine = productNeed.Product_Line__c;
                product.country = productNeed.Country__c;
                product.hasAvailableProducts = false;
                //product.isAvailable = false;
                product.values = new List<Product_Need__c>();
            }

            if (productNeed.Product__c != null) {
                result.hasProducts = true;
                product.values.add(productNeed);
                product.hasAvailableProducts = true;
                //product.isAvailable = true;
            } else {
                product.productNeed = productNeed;
                //product.isAvailable = true;
            }

            productMap.put(productId, product);
        }
        for (Product product : productMap.values()) {
            String productCategoryId = product.country + product.productLine + product.productCategory;
            ProductCategory productCategory = productCategoryMap.get(productCategoryId);
            if (productCategory == null) {
                productCategory = new ProductCategory();
                productCategory.productCategory = product.productCategory;
                productCategory.productLine = product.productLine;
                productCategory.country = product.country;
                //productCategory.isAvailable = false;
            }
            productCategory.product = product;
            /*if (product.isAvailable == true) {
                productCategory.isAvailable = true;
            }*/

            productCategoryMap.put(productCategoryId, productCategory);
        }

        for (ProductCategory productCategory : productCategoryMap.values()) {
            String productLineId = productCategory.country + productCategory.productLine;
            ProductLine productLine = productLineMap.get(productLineId);
            if (productLine == null) {
                productLine = new ProductLine();
                productLine.productLine = productCategory.productLine;
                productLine.country = productCategory.country;
                productLine.values = new List<ProductCategory>();
                //productLine.isAvailable = false;
            }
            productLine.values.add(productCategory);
            /*if (productCategory.isAvailable == true) {
                productLine.isAvailable = true;
            }*/
            productLineMap.put(productLineId, productLine);
        }

        for (ProductLine productLine : productLineMap.values()) {
            Country country = countryMap.get(productLine.country);
            if (country == null) {
                country = new Country();
                country.country = productLine.country;
                country.values = new List<ProductLine>();
                country.isMarketPresence = marketPresence.contains(country.country);
            }
            country.values.add(productLine);
            /*if (productLine.isAvailable == true) {
                country.isAvailable = true;
            }*/
            countryMap.put(productLine.country, country);
        }
        result.countryWrappers = countryMap.values();

        if (recordId != null) {
            result.existingLinks = getLinks(recordId);
            String objectType = recordId.getSobjectType().getDescribe().getName();
            result.objectName = objectType;
        } else {
            result.existingLinks = new List<Product_Need_Link__c>();
        }

        return result;
    }

    @AuraEnabled
    public static List<Product_Need_Link__c> getLinks(Id recordId) {
        List<Product_Need_Link__c> existingLinks = [
            SELECT
                Id,
                Account__c,
                Account__r.Name,
                Opportunity__c,
                Opportunity__r.Name,
                KAM_Documents_Link__c,
                Product_Need__c,
                Country__c,
                Product_Line__c,
                Name,
                Product_Category__c,
                Product_Need__r.Product__c,
                Product_Need__r.Product_Owner__c,
                Product_Need__r.Name,
                Product_Need__r.IsAvailable__c,
                Product_Need__r.Contact_Person__r.Name,
                Comment__c,
                Product_Need__r.Contact_Person__r.Email,
                Product_Need__r.Contact_Email__c,
                Is_Primary__c
            FROM Product_Need_Link__c
            WHERE Account__c = :recordId OR Opportunity__c = :recordId OR KAM_Documents_Link__c = :recordId
        ];

        return existingLinks;
    }

    @AuraEnabled
    public static ProductNeedControllerWrapper saveLink(Id recordId, Id productNeedId, String comment) {
        List<Product_Need_Link__c> existingLinks = [
            SELECT Id
            FROM Product_Need_Link__c
            WHERE
                (Account__c = :recordId
                OR Opportunity__c = :recordId
                OR KAM_Documents_Link__c = :recordId)
                AND Product_Need__c = :productNeedId
        ];
        if (existingLinks.size() != 0 && productNeedId != null) {
            throw new AuraHandledException('There is already a link for this product need');
        }

        String objectType = recordId.getSobjectType().getDescribe().getName();
        Product_Need_Link__c newProductNeedLink = new Product_Need_Link__c();
        newProductNeedLink.Product_Need__c = productNeedId;
        newProductNeedLink.Comment__c = comment;

        switch on objectType {
            when 'Opportunity' {
                newProductNeedLink.Opportunity__c = recordId;
                Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :recordId];
                newProductNeedLink.Account__c = opp.AccountId;

                if (
                    [
                        SELECT Id
                        FROM Product_Need_Link__c
                        WHERE Account__c = :opp.AccountId AND Opportunity__c = NULL AND Product_Need__c = :productNeedId
                    ]
                    .size() == 0
                ) {
                    Product_Need_Link__c newProductNeedLinkAccount = (Product_Need_Link__c) JSON.deserializeStrict(
                        JSON.serialize(newProductNeedLink),
                        Product_Need_Link__c.class
                    );
                    newProductNeedLinkAccount.Opportunity__c = null;
                    insert newProductNeedLinkAccount;
                }
            }
            when 'KAM_Documents_Link__c' {
                newProductNeedLink.KAM_Documents_Link__c = recordId;
            }
            when 'Account' {
                newProductNeedLink.Account__c = recordId;
            }
        }
        insert newProductNeedLink;

        if (objectType == 'Opportunity') {
            Opportunity opp = [SELECT Id, Customer_Need_in_scope_primary__c FROM Opportunity WHERE Id = :recordId];
            if (opp.Customer_Need_in_scope_primary__c == null) {
                opp.Customer_Need_in_scope_primary__c = newProductNeedLink.Id;
                disableOpportunityTriggerToUpdateLinks = true;
                update opp;
            }
        }

        return getProductMatrix(recordId);
    }

    @AuraEnabled
    public static ProductNeedControllerWrapper saveLinkOther(
        Id recordId,
        String country,
        String productLine,
        String productCategory,
        String comment
    ) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        Product_Need_Link__c newProductNeedLink = new Product_Need_Link__c();
        newProductNeedLink.Country__c = country;
        newProductNeedLink.Product_Line__c = productLine;
        newProductNeedLink.Product_Category__c = productCategory;
        newProductNeedLink.Comment__c = comment;
        newProductNeedLink.Name = (productCategory + ' - ' + country).abbreviate(80);

        switch on objectType {
            when 'Opportunity' {
                newProductNeedLink.Opportunity__c = recordId;
                Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :recordId];
                newProductNeedLink.Account__c = opp.AccountId;

                if (
                    [
                        SELECT Id
                        FROM Product_Need_Link__c
                        WHERE
                            Account__c = :opp.AccountId
                            AND Opportunity__c = NULL
                            AND Country__c = :country
                            AND Product_Line__c = :productLine
                            AND Product_Category__c = :productCategory
                    ]
                    .size() == 0
                ) {
                    Product_Need_Link__c newProductNeedLinkAccount = (Product_Need_Link__c) JSON.deserializeStrict(
                        JSON.serialize(newProductNeedLink),
                        Product_Need_Link__c.class
                    );
                    newProductNeedLinkAccount.Opportunity__c = null;
                    insert newProductNeedLinkAccount;
                }
            }
            when 'Account' {
                newProductNeedLink.Account__c = recordId;
            }
        }

        insert newProductNeedLink;

        if (objectType == 'Opportunity') {
            Opportunity opp = [SELECT Id, Customer_Need_in_scope_primary__c FROM Opportunity WHERE Id = :recordId];
            if (opp.Customer_Need_in_scope_primary__c == null) {
                opp.Customer_Need_in_scope_primary__c = newProductNeedLink.Id;
                disableOpportunityTriggerToUpdateLinks = true;
                update opp;
            }
        }
        return getProductMatrix(recordId);
    }

    @AuraEnabled
    public static Map<Id, Product_Need_Link__c> saveLinks(Map<Id, Id> oppIdToCustomerNeed) {
        Map<Id, Product_Need_Link__c> resultMap = new Map<Id, Product_Need_Link__c>();
        Map<Id, Product_Need_Link__c> existingLinks = new Map<Id, Product_Need_Link__c>(
            [
                SELECT
                    Id,
                    Name,
                    Country__c,
                    Product_Line__c,
                    Product_Category__c,
                    Comment__c,
                    Product_Need__c,
                    Opportunity__c,
                    Account__c
                FROM Product_Need_Link__c
                WHERE Id IN :oppIdToCustomerNeed.values()
            ]
        );

        for (Id oppId : oppIdToCustomerNeed.keySet()) {
            Product_Need_Link__c tempLink = existingLinks.get(oppIdToCustomerNeed.get(oppId));
            System.debug(oppIdToCustomerNeed.get(oppId));
            System.debug(tempLink);
            String tempLinkString = JSON.serialize(tempLink);

            Product_Need_Link__c newLink = (Product_Need_Link__c) System.JSON.deserializeStrict(
                tempLinkString,
                Product_Need_Link__c.class
            );

            newLink.Id = null;
            newLink.Opportunity__c = oppId;
            resultMap.put(oppId, newLink);
        }
        insert resultMap.values();
        return resultMap;
    }

    @AuraEnabled
    public static ProductNeedControllerWrapper deleteLink(Id recordId, Id productNeedLinkId) {
        Product_Need_Link__c linkToDelete = new Product_Need_Link__c();
        linkToDelete.Id = productNeedLinkId;

        delete linkToDelete;
        return getProductMatrix(recordId);
    }

    @AuraEnabled
    public static ProductNeedControllerWrapper setPrimary(Id recordId, Id productNeedLinkId) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        if (objectType == 'Opportunity') {
            Opportunity opp = new Opportunity();
            opp.Id = recordId;
            opp.Customer_Need_in_scope_primary__c = productNeedLinkId;
            disableOpportunityTriggerToUpdateLinks = true;
            update opp;
        }
        return getProductMatrix(recordId);
    }

    public static Map<String, List<String>> getDependentPicklistValuesForProductCategory() {
        SObjectType pnl = Schema.getGlobalDescribe().get('Product_Need__c');
        Schema.SObjectField dependentField = pnl.getDescribe().fields.getMap().get('product_category__c');

        Map<String, List<String>> dependentPicklistValues = new Map<String, List<String>>();
        Schema.DescribeFieldResult dependentFieldResult = dependentField.getDescribe();
        Schema.sObjectField controllerField = dependentFieldResult.getController();
        if (controllerField == null) {
            return null;
        }

        Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
        List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean
            ? null
            : controllerFieldResult.getPicklistValues());

        //It is used to decode the characters of the validFor fields.
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        for (Schema.PicklistEntry entry : dependentFieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                //The PicklistEntry is serialized and deserialized using the Apex JSON class and it will check to have a 'validFor' field
                List<String> base64chars = String.valueOf(
                        ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')
                    )
                    .split('');
                for (Integer i = 0; i < controllerValues.size(); i++) {
                    Object controllerValue = (controllerValues == null
                        ? (Object) (i == 1)
                        : (Object) (controllerValues[i].isActive() ? controllerValues[i].getLabel() : null));
                    Integer bitIndex = i / 6;
                    Integer bitShift = 5 - Math.mod(i, 6);
                    if (controllerValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0) {
                        continue;
                    }
                    if (!dependentPicklistValues.containsKey(String.valueOf(controllerValue))) {
                        dependentPicklistValues.put(String.valueOf(controllerValue), new List<String>());
                    }
                    dependentPicklistValues.get(String.valueOf(controllerValue)).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
    public static Map<String, List<String>> getDependentPicklistValuesForProductCategory2() {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Product_Need__c');

        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap()
            .get('Product_Line__c')
            .getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap()
            .get('Product_Category__c')
            .getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for (Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getLabel(), new List<String>());
        }

        for (Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;

            for (Integer curr : hexString.getChars()) {
                Integer val = 0;

                if (curr >= 65)
                    val = curr - 65 + 10;
                else
                    val = curr - 48;

                if ((val & 8) == 8) {
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                }
                if ((val & 4) == 4) {
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());
                }
                if ((val & 2) == 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());
                }
                if ((val & 1) == 1) {
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());
                }

                baseCount += 4;
            }
        }

        return controllingInfo;
    }

    public static List<String> getPicklistValuesForCountry() {
        String objectName = 'Product_Need__c';
        String fieldName = 'Country__c';
        List<String> result = new List<String>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult r = s.getDescribe();
        Map<String, Schema.SObjectField> fields = r.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            result.add(pickListVal.getValue());
        }

        return result;
    }

    public class Product {
        @AuraEnabled
        public List<Product_Need__c> values { get; set; }
        @AuraEnabled
        public Product_Need__c productNeed { get; set; }
        @AuraEnabled
        public String productCategory { get; set; }
        @AuraEnabled
        public String productLine { get; set; }
        @AuraEnabled
        public String country { get; set; }
        @AuraEnabled
        public Boolean isAvailable { get; set; }
        @AuraEnabled
        public Boolean hasAvailableProducts { get; set; }
        @AuraEnabled
        public String id { get; set; }
    }
    public class ProductCategory {
        @AuraEnabled
        public Product product { get; set; }
        @AuraEnabled
        public String productCategory { get; set; }
        @AuraEnabled
        public String productLine { get; set; }
        @AuraEnabled
        public String country { get; set; }
        @AuraEnabled
        public Boolean isAvailable { get; set; }
        @AuraEnabled
        public String id { get; set; }
    }
    public class ProductLine {
        @AuraEnabled
        public List<ProductCategory> values { get; set; }
        @AuraEnabled
        public String productLine { get; set; }
        @AuraEnabled
        public String country { get; set; }
        @AuraEnabled
        public Boolean isAvailable { get; set; }
        @AuraEnabled
        public String id { get; set; }
    }
    public class Country {
        @AuraEnabled
        public List<ProductLine> values { get; set; }
        @AuraEnabled
        public String country { get; set; }
        @AuraEnabled
        public Boolean isAvailable { get; set; }
        @AuraEnabled
        public Boolean isMarketPresence { get; set; }
        @AuraEnabled public String id { get; set; }
    }

    public class ProductNeedControllerWrapper {
        @AuraEnabled
        public List<Country> countryWrappers { get; set; }
        @AuraEnabled
        public List<Product_Need_Link__c> existingLinks { get; set; }
        @AuraEnabled
        public String objectName { get; set; }
        @AuraEnabled
        public List<String> countryPicklistValues { get; set; }
        @AuraEnabled
        public List<String> countryPicklistValuesMarketPresence { get; set; }
        @AuraEnabled public Set<String> productLinePicklistValues { get; set; }
        @AuraEnabled
        public Map<String, List<String>> productCategoryPicklistValues { get; set; }
        @AuraEnabled
        public Boolean hasProducts { get; set; }
    }
    public class MyPickListInfo {
        public String validFor;
    }
}
/****************************************************************************************************
* Class msLepton
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-04-08
*   Description	:	Lepton Library for reusable Code Snippets
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-04-08       	Init version.
*****************************************************************************************************/

public without sharing class msLepton {

    /**
     * @description Salesforce Flows have the known issue that returned SObjects have illegally defined Picklist entries.
     *              This method is a workaround that composes the returned SObjects into proper ones.
     *
     * @param sObjectsFromFlow List of SObjects as returned from a flow
     *
     * @return Well defined SObjects, in particular the Picklist entries will now be proper.
     */
    public static List<SObject> flowObjectComposer(List<SObject> sObjectsFromFlow) {
        Set<SObjectType> containedTypes = new Set<SObjectType>();

        for (SObject sObjectFromFlow : sObjectsFromFlow) {
            containedTypes.add(sObjectFromFlow.getSObjectType());
        }

        Map<SObjectType, Set<String>> sObjectTypesToPicklistFieldsMap = new Map<SObjectType, Set<String>>();

        for (SObjectType containedType : containedTypes) {
            Map<String, Schema.SObjectField> fieldsMap = containedType.getDescribe().fields.getMap();
            Set<String> picklistFieldSet = new Set<String>();
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
                Schema.DisplayType displayType = fieldDescribe.getType();
                String fieldType = String.valueOf(displayType);
                if (fieldType == 'PICKLIST') {
                    picklistFieldSet.add(fieldName);
                }
            }
            sObjectTypesToPicklistFieldsMap.put(containedType, picklistFieldSet);
        }

        for (SObject sObjectFromFlow : sObjectsFromFlow) {
            for (String picklistFieldName : sObjectTypesToPicklistFieldsMap.get(sObjectsFromFlow.getSObjectType())) {
                sObjectFromFlow.put(picklistFieldName, String.valueOf(sObjectFromFlow.get(picklistFieldName)));
            }
        }
        return sObjectsFromFlow;
    }

    /**
     * @description When retrieving SObjects via Apex Action, null fields get swallowed unless explicitly set.
     *              This method sets null fields
     *
     * @param sObjectsFromFlow List of SObjects as returned from a flow
     * @param fieldSet field Set that is in the SELECT Statement of the SOQL Query
     *
     * @return SObjects that include null fields
     */
    public static List<SObject> setFieldsFromFieldSet(List<SObject> sObjectsFromFlow, List<String> fieldSet) {
        for (SObject sObj : sObjectsFromFlow) {
            for (String field : fieldSet) {
                field = field.trim();
                if (fflib_SObjectDescribe.getDescribe(sObj.getSObjectType()).getField(field).getDescribe().isUpdateable()) {
                    sObj.put(field, sObj.get(field));
                }
            }
        }
        return sObjectsFromFlow;
    }


    /**
     * @description Apex currently has no built in feature to determine the max of two dates. This method returns this.
     *              Note that null values will be interpreted as lower than any possible Date here.
     *
     * @param d1 Date entry to be compared
     * @param d2 Date entry to be compared
     *
     * @return The max of d1 and d2, if one is null, the other is returned
     */
    public static Date max(Date d1, Date d2) {
        if (d1 != null && d2 != null) return d1 > d2 ? d1 : d2; else if (d1 != null) return d1; else if (d2 != null) return d2; else return null;
    }

    /**
     * @description Apex currently has no built in feature to determine the max of two dates. This method returns this.
     *              Note that null values will be interpreted as higher than any possible Date here.
     *
     * @param d1 Date entry to be compared
     * @param d2 Date entry to be compared
     *
     * @return The max of d1 and d2, if one is null, null is returned
     */
    public static Date maxWithInfinity(Date d1, Date d2) {
        if (d1 != null && d2 != null) return d1 > d2 ? d1 : d2; else return null;
    }

    /**
     * @description Apex currently has no built in feature to determine the min of two dates. This method returns this.
     *              Note that null values will be interpreted as higher than any possible Date here.
     *
     * @param d1 Date entry to be compared
     * @param d2 Date entry to be compared
     *
     * @return The max of d1 and d2, if one is null, the other is returned
     */
    public static Date min(Date d1, Date d2) {
        if (d1 != null && d2 != null) return d1 < d2 ? d1 : d2; else if (d1 != null) return d1; else if (d2 != null) return d2; else return null;
    }

    /**
     * @description Checks if the compared time intervals have an intersection. Start Dates might be open (null).
     *              The end dates might be open (null). The algorithm assumes syntactic realistic time intervals.
     *
     * @param startDate1 Start Date of first interval
     * @param endDate1 End Date of first interval
     *
     * @param startDate2 Start Date of second interval
     * @param endDate2 End Date of second interval
     *
     * @return The max of d1 and d2, if one is null, the other is returned
     */
    public static Boolean checkDateIntersectionWithInfinity(Date startDate1, Date endDate1, Date startDate2, Date endDate2) {
        if (startDate1 != null && endDate1 != null && endDate1 < startDate1) {
            throw new msLeptonException('End Date 1 needs to be equal or greater of Start Date 1');
        }
        if (startDate2 != null && endDate2 != null && endDate2 < startDate2) {
            throw new msLeptonException('End Date 2 needs to be equal or greater of Start Date 2');
        }
        return (startDate1 == null //1.0 We compare all possible cases where interval 1 is open to the left (-inf)
                && (startDate2 == null //If both start dates are -inf then there is an intersection on the left
                || endDate1 == null //If the first interval is all time, then there is always an intersection
                || startDate2 <= endDate1) //otherwise we can compare to see if the second interval starts before the first ends (intersection on the right)
        )//Otherwise endDate1 < startDate2, so no intersection.
                || (startDate1 != null //2.0 We compare all possible cases where interval 1 is closed/finite to the left
                && ((endDate1 == null //2.1 In case that the first interval is inf to the right
                && (endDate2 == null //Both intervals are inf on the right, intersection on the right
                || (startDate1 <= endDate2)) //The second interval ended before the first started (intersection on the left side)
        )//Otherwise endDate2 < startDate1, so no intersection.
                || endDate1 != null //2.2 We compare all cases where interval 1 is finite to left and right
                && ((startDate2 == null && endDate2 == null) //If the second interval is infinite in total it will always overlap the finite interval 1
                //Otherwise at least one side of interval 2 is finite
                || (startDate2 != null //2.2.1 Assuming startDate2 is finite
                && startDate2 <= endDate1 //In order to have an intersection it must start before interval 1 ends
                && (endDate2 == null //And the second interval must either be infinite to the right
                || startDate1 <= endDate2)//Or end after the first one starts
        )//Otherwise interval 2 is entirely before interval 1
                || (startDate2 == null //2.2.2 Assuming that startDate2 is infinite
                && endDate2 != null //Then endDate2 must be finite
                && startDate1 <= endDate2 //And the second interval must end after the first one starts
        )//Otherwise interval 2 is entirely before interval 1
        )));//There are no other cases possible for an intersection
    }

    /**
     * @description Date formatter, lifts Datetime Class
     *
     * @param dateToFormat Date to be formatted
     * @param dateFormatString String that specifies the Date format, see Class Datetime for specifics
     *
     * @return The formatted Date as String
     */
    public static String format(Date dateToFormat, String dateFormatString) {
        Time zero = Time.newInstance(0, 0, 0, 0);
        return Datetime.newInstanceGmt(dateToFormat, zero).formatGmt(dateFormatString);
    }

    /**
     * @description Reverses a List. Returns null if the initial List is null
     *
     * @param listToReverse List of Objects to reverse
     *
     * @return The reverse of the inserted List
     */
    public static List<Object> reverseList(List<Object> listToReverse) {
        List<Object> reversed = new List<Object>();
        if (listToReverse == null) {
            reversed = null;
        } else {
            for (Integer i = listToReverse.size() - 1; i >= 0; i--) {
                reversed.add(listToReverse[i]);
            }
        }
        return reversed;
    }

    /**
     * @description Method returns the last Item of a List.
     *
     * @param listOfThings List<Object> where the last entry is requested
     *
     * @return Object that is placed in the last position of the List
     */
    public static Object last(List<Object> listOfThings) {
        Integer indexLastItem = listOfThings.size() - 1;
        Object result = null;
        if (indexLastItem != -1) {
            result = listOfThings[indexLastItem];
        }
        return result;
    }

    /**
     * @description Method returns if the index is the last of that List
     *
     * @param index Integer to be compared
     * @param listOfThings List<Object> List to check for Index
     *
     *
     * @return  true if the index is identical to the last index. If no list/null is passed,
     *          it is assumed to be an empty list
     */
    public static Boolean isLast(Integer index, List<Object> listOfThings) {
        if (listOfThings == null) {
            listOfThings = new List<Object>();
        }
        Integer indexLastItem = listOfThings.size() - 1;
        return index == indexLastItem;
    }

    /**
     * @description Casts a Set of Strings to a Set of Ids. Non valid entries will be filtered out!
     *
     * @param setOfIds Set of Ids stored in String format
     *
     * @return The Set of Ids contained in the Set of Strings
     */
    public static Set<Id> castToSetId(Set<String> setOfIds) {
        Set<Id> result = new Set<Id>();
        for (String stringItem : setOfIds) {
            if (stringItem instanceof Id) {
                result.add(stringItem);
            } else {
                System.debug('ERROR: msLepton.castToSetId: Attempted to add invalid Id: ' + stringItem);
            }
        }
        return result;
    }

    /**
     * @description Casts a List of Strings to a Set of Ids. Non valid entries will be filtered out!
     *
     * @param listOfIds List of Ids stored in String format
     *
     * @return The Set of Ids contained in the Set of Strings
     */
    public static Set<Id> castToSetId(List<String> listOfIds) {
        Set<Id> result = new Set<Id>();
        for (String stringItem : listOfIds) {
            if (stringItem instanceof Id) {
                result.add(stringItem);
            } else {
                System.debug('ERROR: msLepton.castToSetId: Attempted to add invalid Id: ' + stringItem);
            }
        }
        return result;
    }

    /**
    *
    * @param key Id key where to store the entry in the map
    * @param entry Entry to store in the deeper List
    * @param mapToAddTo Map that that Entry is to be stored in
    *
    * @return The map with the added entry, optional to use since call by reference is in action
    */
    public static Map<Id, Set<String>> addToMap(
            Id key, String entry, Map<Id, Set<String>> mapToAddTo) {
        if (!mapToAddTo.containsKey(key)) {
            mapToAddTo.put(key, new Set<String>());
        }
        mapToAddTo.get(key).add(entry);
        return mapToAddTo;
    }

    /**
    *
    * @param key Id key where to store the entry in the map
    * @param entry Entry to store in the deeper List
    * @param mapToAddTo Map that that Entry is to be stored in
    *
    * @return The map with the added entry, optional to use since call by reference is in action
    */
    public static Map<Id, Set<Id>> addToMap(
            Id key, String entry, Map<Id, Set<Id>> mapToAddTo) {
        if (!mapToAddTo.containsKey(key)) {
            mapToAddTo.put(key, new Set<Id>());
        }
        mapToAddTo.get(key).add(entry);
        return mapToAddTo;
    }

    /**
     *
     * @param outerKey Id key where to store the entry in the outer Map
     * @param innerKey String key where to store the entry in the inner Map
     * @param entry Entry to store in the deeper List
     * @param mapToAddTo Map that that Entry is to be stored in
     *
     * @return The map with the added entry, optional to use since call by reference is in action
     */
    public static Map<Id, ListMapContainer> addToMap(
            Id outerKey, String innerKey, SObject entry, Map<Id, ListMapContainer> mapToAddTo) {
        if (!mapToAddTo.containsKey(outerKey)) {
            SObjectType entryType = entry.getSObjectType();
            mapToAddTo.put(outerKey, new ListMapContainer(entryType));
        }
        mapToAddTo.get(outerKey).addToMap(innerKey, entry);
        return mapToAddTo;
    }

    /**
     *
     * @param results List of Save Results that are being examined for errors
     *
     * @return String comment that either states all errors or a generic success message
     */
    public static String generateCommentFromSaveResults(List<Database.SaveResult> results) {
        Boolean errorEncountered = false;
        String comment = '';
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                errorEncountered = true;
                comment += Label.batchLoggingErrorMessage + ' ' +  result.getId() + '\n';
                for (Database.Error error : result.getErrors()) {
                    comment += error.getStatusCode() + ' - ' + error.getMessage() + '\n';
                }
            }
        }
        if (!errorEncountered) {
            comment = Label.batchLoggingSuccessMessage;
        }
        return comment;
    }

    public class msLeptonException extends Exception {
    }
}
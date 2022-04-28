/**
 * Created by frank on 25.07.2018.
 *
 * This Class can be used in Flow Designer to lock a record
 */

public class msLockRecord {

    @InvocableMethod(label = 'Lock record' description= 'This method will lock the record')
    public static void lock(List<List<String>> inputList) {
        list<String> contractList = inputList[0];
        String contract = contractList[0];
        Approval.lock(contract);
    }
}
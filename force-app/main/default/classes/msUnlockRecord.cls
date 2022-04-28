/**
 * Created by frank on 25.07.2018.
 *
 * This Class can be used in Flow Designer to undlock a record
 */

public class msUnlockRecord {
    @InvocableMethod(Label = 'Unlock record' Description= 'This method will unlock the record')
    public static void unlock(List<List<String>> inputList) {
        List<String> contractList = inputList[0];
        String record = contractList[0];
        Approval.unlock(record);
    }
}
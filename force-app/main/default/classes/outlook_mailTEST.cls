@isTest
public class outlook_mailTEST {
    static testmethod void testInsertMail() {
        Task tmpTask = new Task();
        tmpTask.Subject = 'TEST';
        insert tmpTask;
    }
}
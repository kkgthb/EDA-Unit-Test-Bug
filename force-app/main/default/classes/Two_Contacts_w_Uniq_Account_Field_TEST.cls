@isTest
public class Two_Contacts_w_Uniq_Account_Field_TEST {
    
    static testMethod void runTest() {
        
        Contact c1 = new Contact(LastName='C1');
        Contact c2 = new Contact(LastName='C2');
        INSERT new List<Contact>{c1, c2}; // Fails with stack trace as follows:

        // Two_Contacts_w_Uniq_Account_Field_TEST.runTest - Fail
        // Message: System.DmlException: Insert failed. First exception on row 0; first error: 
        // CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, hed.TDTM_Contact: execution of AfterInsert  
        // 
        // caused by: System.DmlException: Insert failed. First exception on row 1; first error: 
        // DUPLICATE_VALUE, duplicate value found: <unknown> duplicates value on record with id:   
        // <unknown>: []
        // 
        // Class.hed.ACCT_IndividualAccounts_TDTM.insertContactAccount: line 759, column 1
        // Class.hed.ACCT_IndividualAccounts_TDTM.handleInsertProcessing: line 375, column 1
        // Class.hed.ACCT_IndividualAccounts_TDTM.handlesAfterInsertUpdate: line 270, column 1
        // Class.hed.ACCT_IndividualAccounts_TDTM.run: line 118, column 1
        // Class.hed.TDTM_TriggerHandler.runClass: line 145, column 1
        // Class.hed.TDTM_TriggerHandler.run: line 75, column 1
        // Class.hed.TDTM_Global_API.run: line 61, column 1
        // Trigger.hed.TDTM_Contact: line 33, column 1: []
            // StackTrace: Class.Two_Contacts_w_Uniq_Account_Field_TEST.runTest: line 8, column 1

    }
    
}
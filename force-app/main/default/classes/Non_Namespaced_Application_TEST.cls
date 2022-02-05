@isTest
public class Non_Namespaced_Application_TEST {
    
    static testMethod void runTest() {
        
        Contact c1 = new Contact(LastName='C1');
        INSERT c1;
        
        Application__c c1a = new Application__c(Contact__c = c1.Id);
        INSERT c1a; // Fails with stack trace as follows:

        // Non_Namespaced_Application_TEST.runTest - Fail
        // Message: System.DmlException: Insert failed. First exception on row 0; first error: 
        // CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, ApplicationTrigger: execution of BeforeInsert
        // caused by: System.TypeException: Invalid conversion from runtime type List<Application__c> to List<hed__Application__c>
        // 
        // Class.hed.Application_TDTM.handleBeforeInsert: line 77, column 1
        // Class.hed.Application_TDTM.run: line 57, column 1
        // Class.hed.TDTM_TriggerHandler.runClass: line 145, column 1
        // Class.hed.TDTM_TriggerHandler.run: line 75, column 1
        // Class.hed.TDTM_Global_API.run: line 61, column 1
        // Trigger.ApplicationTrigger: line 2, column 1: []
        //         StackTrace: Class.Non_Namespaced_Application_TEST.runTest: line 10, column 1

    }
    
}
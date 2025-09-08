/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TaskServiceTest {

     @testSetup
    static void setupData() {

        Map<String, SObject> personAccount = TestData.createPersonAccountBorrower();

        // Minimal Contact (Borrower)
        Contact borrower = (Contact) personAccount.get('Contact');

        // Minimal Product
        Product__c product = new Product__c(
            Name = 'Conv 30Y',
            Min_Credit_Score__c = 620,
            Base_Rate__c = 6.00
        );
        insert product;

        // Draaft to Approve Loan Application 
        insert new Loan_Application__c(
            Borrower__c = borrower.Id,
            Selected_Product__c = product.Id,
            Amount__c = 500000,
            Status__c = 'Draft'
        );
    }
  
    // Create a new task for the Loan Application
    @IsTest(SeeAllData=false)
    private static void testPreparesTaskForApprovedLoan() {
        List<Loan_Application__c> approvedLApps = new List<Loan_Application__c>();
        
        Loan_Application__c la = [
            SELECT Id, Status__c, OwnerId
            FROM Loan_Application__c
            LIMIT 1
        ];
        approvedLApps.add(la);

        Test.startTest();
        TaskService.prepareDocsTasks(approvedLApps, 'testSubject', 'Loan Application');
        Test.stopTest();

        // Assert a Task was created for this loan
        List<Task> tasks = [
            SELECT Id, WhatId, Subject, Status, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :la.Id
        ];
        System.assertEquals(1, tasks.size(), 'Exactly one Task should be created for Approved loan.');
        System.assertEquals(la.Id, tasks[0].WhatId, 'Task.WhatId should reference the Loan Application.');
        System.assertEquals(true, String.isNotBlank(tasks[0].Subject), 'Task subject should be set.');
    }

    
    // Negative senario when passing null loan application Id
    @IsTest
    private static void negativeNullLoanId() {
        String error;

        Test.startTest();
        try {
            TaskService.prepareDocsTasks(null, 'testSubject', 'Loan Application');
        }catch (Exception exp) {
            System.debug('exp-->' + exp.getMessage());
            error = exp.getMessage();
        }
        Test.stopTest();
        System.assertEquals(error, 'Attempt to de-reference a null object');
    }

}
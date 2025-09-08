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
private class LoanApplicationsTest {

    @TestSetup
    static void setupData() {
        // Create test Products 
        insert new List<Product__c>{
            new Product__c(Name='Conventional 30yr', Min_Credit_Score__c=620, Base_Rate__c=6.00),
            new Product__c(Name='Jumbo 30yr',        Min_Credit_Score__c=700, Base_Rate__c=6.75),
            new Product__c(Name='Jumbo 35yr',        Min_Credit_Score__c=700, Base_Rate__c=5.15)
        };

        // Create Test Borrowers
        insert new List<Contact>{
            new Contact( // fully valid
                LastName='Valid Borrower', Email='valid@example.com',
                Annual_Income__c=120000, Credit_Score__c=730
            ),
            new Contact( // missing email
                LastName='No Email', Email=null,
                Annual_Income__c=120000, Credit_Score__c=720
            ),
            new Contact( // zero income
                LastName='Zero Income', Email='zeroincome@example.com',
                Annual_Income__c=0, Credit_Score__c=720
            ),
            new Contact( // missing credit score
                LastName='No Credit', Email='nocredit@example.com',
                Annual_Income__c=120000, Credit_Score__c=null
            )
        };
    }

    // Valid Loan but with valid Borrower the test should allow to sumbit the Loan Application
    // The Status of Loan Application will change to Approved and Select the best eligible Product
    // Also the task should be created for the Owner of Loan Application
    @IsTest(SeeAllData=false)
    private static void testCreateLoanAndSubmitApproved() {

        Map<String, SObject> personAccount = TestData.createPersonAccountBorrower();
        Contact bValid = (Contact) personAccount.get('Contact');

        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bValid.Id, Amount__c=650000,
                Status__c='Draft');

        Test.startTest();
        insert testLoan;
        testLoan.Status__c = 'Submitted';
        update testLoan;
        Test.stopTest();

        testLoan = [SELECT Id, Selected_Product__c, Status__c FROM Loan_Application__c WHERE Id = :testLoan.Id];
        System.assertEquals('Approved', testLoan.Status__c, 'Status should be Submitted and no validation errors');

        // Assert the Product Selection
        Product__c eligibleProduct= [SELECT Id, Name, Min_Credit_Score__c, Base_Rate__c FROM Product__c WHERE Id=:testLoan.Selected_Product__c LIMIT 1];
        System.assertEquals(5.15, eligibleProduct.Base_Rate__c, 'As per the test data Base Rate will be 5.15');
        System.assertEquals(700, eligibleProduct.Min_Credit_Score__c, 'As per the test data Base Rate will be 5.15');
        System.assertEquals('Jumbo 35yr', eligibleProduct.Name, 'As per the test data Base Rate will be 5.15');

        // Assert the Task creation
        List<Task> tasks = [SELECT Id, Subject, Status, OwnerId FROM Task WHERE WhatId = :testLoan.Id];
        System.assertEquals(1, tasks.size(), 'Only 1 task will be created for the approved loan application.');
    }

    // Valid Loan but with Borrower has low credit score the test should allow to sumbit the Loan Application
    // The Status of Loan Application will change to Rejected as there is no eligible Product
    // Also the task should not created
    @IsTest(SeeAllData=false)
    private static void testCreateLoanAndSubmitRejected() {

        Map<String, SObject> personAccount = TestData.createPersonAccountBorrower();
        Contact bBadCreditScore = (Contact) personAccount.get('Contact');
        bBadCreditScore.Credit_Score__c = 300;
        update bBadCreditScore;

        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bBadCreditScore.Id, Amount__c=650000,
                Status__c='Draft');

        Test.startTest();
        insert testLoan;
        testLoan.Status__c = 'Submitted';
        update testLoan;
        Test.stopTest();

        testLoan = [SELECT Id, Selected_Product__c, Status__c, Rejection_Reason__c FROM Loan_Application__c WHERE Id = :testLoan.Id];
        System.assertEquals('Rejected', testLoan.Status__c, 'Status should be Submitted and no validation errors');

        // Assert the Product Selection
        List<Product__c> eligibleProduct= [SELECT Id, Name, Min_Credit_Score__c, Base_Rate__c FROM Product__c WHERE Id=:testLoan.Selected_Product__c];
        System.assertEquals(true, eligibleProduct.size()==0, 'No product is selected');
        System.assertEquals(true, String.isNotBlank(testLoan.Rejection_Reason__c), 'Rejection reason is set');

        // Assert the Task creation
        List<Task> tasks = [SELECT Id, Subject, Status, OwnerId FROM Task WHERE WhatId = :testLoan.Id];
        System.assertEquals(0, tasks.size(), 'No task will be created for the rejected loan application.');
    }

    // Valid Loan but invalid Borrower with missing email, requires no validation
    @IsTest(SeeAllData=false)
    private static void testDraftValidationSkiped() {

        Map<String, SObject> personAccount = TestData.createPersonAccountBorrower();
        Contact bNoEmail = (Contact) personAccount.get('Contact');
        bNoEmail.Email = null;
        update bNoEmail;

        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bNoEmail.Id, Amount__c=650000,
                Status__c='Draft');

        Test.startTest();
        insert testLoan;
        Test.stopTest();

        testLoan = [SELECT Status__c FROM Loan_Application__c WHERE Id = :testLoan.Id];
        System.assertEquals('Draft', testLoan.Status__c, 'Status should be Draft and no validation occur');
    }

    // InValid Loan status but valid Borrower, it should not allow to create new Loan Application
    @IsTest
    private static void negativeOnlyStatusWithDraftSubmit() {

        Map<String, SObject> personAccount = TestData.createPersonAccountBorrower();
        Contact bValid = (Contact) personAccount.get('Contact');

        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bValid.Id, Amount__c=650000,
                Status__c='Submitted');
        try{
            Test.startTest();
            insert testLoan;
            Test.stopTest();
        }catch(Exception exp){
            System.assert(true, exp.getMessage().contains('Loan Application must created at Draft Status'));
        }   
    }

    //Create a Laon record in Draft status with no Borrower record. 
    //Load record will create but fail when try to submit the application
     @IsTest
    private static void negativeMissingBorrowerFails() {
        Loan_Application__c testLoan = new Loan_Application__c( 
                Amount__c=650000, Status__c='Draft');
        
        try{
            Test.startTest();
            insert testLoan;
            
            testLoan.Status__c = 'Submitted';
            update testLoan;
            Test.stopTest();
        }catch(Exception exp){
            System.assert(true, exp.getMessage().contains('Borrower is required to submit the application.'));
        }          
    }

    //Create a Laon record in Draft status with no Borrower email. 
    //Load record will create but fail when try to submit the application
    @IsTest
    private static void negativeBorrowerMissingEmailFails() {
        Contact bNoEmail = [SELECT Id FROM Contact WHERE LastName='No Email' LIMIT 1];
        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bNoEmail.Id, Amount__c=650000,
                Status__c='Draft');

        try{
            Test.startTest();
            insert testLoan;
            
            testLoan.Status__c = 'Submitted';
            update testLoan;
            Test.stopTest();
        }catch(Exception exp){
            System.assert(true, exp.getMessage().contains('Borrower must have an Email.'));
        }
    }

    //Create a Laon record in Draft status with no Borrower with no income. 
    //Load record will create but fail when try to submit the application
    @IsTest
    private static void negativeBorrowerIncomeZeroFails() { 
        Contact bZeroInc = [SELECT Id FROM Contact WHERE LastName='Zero Income' LIMIT 1];
        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bZeroInc.Id, Amount__c=650000,
                Status__c='Draft');

        try{
            Test.startTest();
            insert testLoan;
            //Update Status
            testLoan.Status__c = 'Submitted';
            update testLoan;
            Test.stopTest();
        }catch(Exception exp){
            System.assert(true, exp.getMessage().contains('Borrower Annual Income must be greater than 0.'));
        }
    }

    //Create a Laon record in Draft status with no Credit Score of Borrower. 
    //Load record will create but fail when try to submit the application
    @IsTest
    private static void negative_BorrowerMissingCreditScore_Fails() {
        Contact bNoCS    = [SELECT Id FROM Contact WHERE LastName='No Credit' LIMIT 1];
        Loan_Application__c testLoan = new Loan_Application__c( 
                Borrower__c=bNoCS.Id, Amount__c=650000,
                Status__c='Draft');

        try{
            Test.startTest();
            insert testLoan;
            
            testLoan.Status__c = 'Submitted';
            update testLoan;
            Test.stopTest();
        }catch(Exception exp){
            System.assert(true, exp.getMessage().contains('Borrower Credit Score is required.'));
        }
    }
}
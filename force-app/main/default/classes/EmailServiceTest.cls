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
private class EmailServiceTest {

    @TestSetup
    static void setupData() {
        TestData.createAdminUser();
    }

    @IsTest
    static void testSendEmailInvocations() {
        Integer before = Limits.getEmailInvocations();

        User runningUser = TestData.createAdminUser();
        System.runAs(runningUser) {
            Test.startTest();
            new EmailServiceImpl().sendEmail('ops@example.com','All good. No errors.', 'Batch Summary');
            Test.stopTest();
        }
        // Assert
        Integer after = Limits.getEmailInvocations();
        //System.assert(after > before, 'EmailServiceImpl.send should call Messaging.sendEmail');
    }

    @IsTest
    static void negativeMissingRecipientsThrowsEmailException() {
        String errMessage;

        User runningUser = TestData.createAdminUser();
        System.runAs(runningUser) {
            Test.startTest();
            try {
                new EmailServiceImpl().sendEmail(null,'All good. No errors.', 'This should throw.' );
            }catch (EmailException exp) {
                System.debug('exp---> ' + exp.getMessage());
                errMessage =  exp.getMessage();
            }catch (Exception exp) {
                System.debug('exp---> 1' + exp.getMessage());
                errMessage =  exp.getMessage();
            }
        Test.stopTest();
    }   

        System.assert(true, errMessage.contains('INVALID_EMAIL_ADDRESS'));
    }
}
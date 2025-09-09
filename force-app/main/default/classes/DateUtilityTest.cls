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
private class DateUtilityTest {

    @IsTest
    private static void testAddBusinessDaysSameWeek() {
        // Mon → +3 business days = Thu
        // Use a known Monday
        Date start = Date.newInstance(2025, 9, 1); // 1 Sep 2025 is Monday
        Date expected = Date.newInstance(2025, 9, 4); // Thursday
        Date actual = DateUtility.addBusinessDays(start, 3);
        System.assertEquals(expected, actual, 'Should land on Thursday within the same work week.');
    }

    @IsTest
    private static void testAddBusinessDaysCrossesWeekend() {
        // Fri → +1 business day = Mon (skip Sat/Sun)
        Date start = Date.newInstance(2025, 9, 5); // Friday
        Date expected = Date.newInstance(2025, 9, 8); // Monday
        Date actual = DateUtility.addBusinessDays(start, 1);
        System.assertEquals(expected, actual, 'Should skip the weekend and land on Monday.');
    }

    @IsTest
    private static void testAddBusinessDaysNegativeDays_currentBehavior() {
        // Current implementation: while(added < days) won't run if days < 0,
        // so it returns the original start date unchanged.
        Date start = Date.newInstance(2025, 9, 10); // Wednesday
        Date actual = DateUtility.addBusinessDays(start, -2);
        System.assertEquals(start, actual, 'Negative days currently returns the original date (documented behavior).');
    }

    @IsTest
    private static void negativeAddBusinessDaysNullStartDate() {
        Boolean threw = false;
        try {
            // Expect a NullPointerException inside the method
            DateUtility.addBusinessDays(null, 2);
        } catch (Exception exp) {
            threw = true;
            System.assert(exp.getMessage() != null,
                'Should throw an exception when startDate is null.');
        }
        System.assert(threw, 'Expected an exception for null startDate.');
    }
}
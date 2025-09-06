trigger LoanApplicationTrigger on Loan_Application__c (before update, after update , after insert, before insert) {
    fflib_SObjectDomain.triggerHandler(LoanApplications.class);
}
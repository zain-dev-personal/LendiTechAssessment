public with sharing class LoanApplicationValidator {
    
    public static void handleSubmission(List<Loan_Application__c> loanApps) {
        Set<Id> borrowerIds = new Set<Id>();
        Boolean isSubmitting = false;

        for (Loan_Application__c la :loanApps) {
            if (la.Borrower__c != null) {
                borrowerIds.add(la.Borrower__c);
            }       
        }
        // One query to collect all the Borrower(Contact) Ids for Validation and later use
        Map<Id, Contact> borrowerMap = BorrowerSelector.newInstance().getBorrowerMap(borrowerIds);

        for (Loan_Application__c la :loanApps) {
            // 1) Amount > 0
            if (la.Amount__c == null || la.Amount__c <= 0) {
                la.addError('Amount must be greater than 0 when submitting.');
            }
            // 2) Borrower must be present
            if (la.Borrower__c == null) {
                la.addError('Borrower is required to submit the application.');
                return;
            }
            Contact borrower = borrowerMap.get(la.Borrower__c);
            // 3) Borrower data: Email present, Income > 0, Credit Score present
            if (borrower.Credit_Score__c == null) {
                la.addError('Borrower Credit Score is required.');
            }
            if (String.isBlank(borrower.Email)) {
                la.addError('Borrower must have an Email.');
            }
            if (borrower.Annual_Income__c == null || borrower.Annual_Income__c <= 0) {
                la.addError('Borrower Annual Income must be greater than 0.');
            }  
        }
    }
}
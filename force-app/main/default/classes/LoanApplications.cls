/**
 * Domain class for Loan Applicaton object
 * This class contain the LoanApplication manipulation methods and trigger methods 
 */
public inherited sharing class LoanApplications extends fflib_SObjectDomain implements ILoanApplications{
    
    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }

    // 2. Trigger methods Starts

    // Validate business rules when moving Draft → Submitted
    public override void onBeforeUpdate(Map<Id,SObject> oldMap) {
       // Map<Id, Loan_Application__c> oldMap = (Map<Id, Loan_Application__c>) this.getOldMap();
        Set<Id> productIds = new Set<Id>();
        Boolean isSubmitting = false;

        for (Loan_Application__c la : (List<Loan_Application__c>) records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            isSubmitting = oldLapp != null
                        && oldLapp.Status__c == 'Draft'
                        && la.Status__c == 'Submitted';

            if (isSubmitting) {
                // 1) Amount > 0
                if (la.Amount__c == null || la.Amount__c <= 0) {
                    la.addError('Amount must be greater than 0 when submitting.');
                }

                // 2) Borrower must be present
                if (la.Borrower__c == null) {
                    la.addError('Borrower is required to submit the application.');
                    return;
                }
                // 3) Borrower data: Email present, Income > 0, Credit Score present
                if (la.Borrower__c == null) {
                    la.addError('Borrower record not found.');
                    return;
                }
                if (la.Borrower__r.Credit_Score__c == null) {
                    la.addError('Borrower Credit Score is required.');
                }
                if (String.isBlank(la.Borrower__r.Email)) {
                    la.addError('Borrower must have an Email.');
                }
                if (la.Borrower__r.Annual_Income__c == null || la.Borrower__r.Annual_Income__c <= 0) {
                    la.addError('Borrower Annual Income must be greater than 0.');
                }
                if (la.Borrower__r.Credit_Score__c == null) {
                    la.addError('Borrower Credit Score is required.');
                }
                if (la.Selected_Product__c == null){
                    return;
                }
                if(la.Selected_Product__r.Min_Credit_Score__c != null && la.Borrower__r.Credit_Score__c != null) {
                    if (la.Borrower__r.Credit_Score__c < la.Selected_Product__r.Min_Credit_Score__c) {
                        la.Rejection_Reason__c = 'Borrower does not meet the product minimum credit score.';
                        la.Status__c = 'Rejected';

                    }else{
                        borrowerIds.add(la.Borrower__c);
                    }
                }
                
                borrowerIds.add(la.Borrower__c);
                productIds.add(la.Selected_Product__c);     
            }
        }// End for

        if (isSubmitting) {

            List<Contact> bLst = BorrowerSelector.newInstance().selectByIds(borrowerIds);

            if (productIds.size() > 0) {
                List<Product__c> pLst = ProductSelector.newInstance().selectByIds(productIds);
                for(Product__c p : pLst){
                    
                }
                
            }
        }
    }

    // Create follow-up Task AFTER update once Loan is Approved
    public override void onAfterUpdate() {
        List<Loan_Application__c> approvedLoans = new List<Loan_Application__c>();

        for (Loan_Application__c rec : (List<Loan_Application__c>) Records) {
            Loan_Application__c oldRec = (Loan_Application__c) Trigger.oldMap.get(rec.Id);
            if (oldRec.Status__c != 'Approved' && rec.Status__c == 'Approved') {
                approvedLoans.add(rec);
            }
        }
        if (!approvedLoans.isEmpty()) {
            LoanApplicationService.prepareDocsTasks(approvedLoans);
        }
    }

    //Trigger methods Ends

    public class Constructor implements fflib_IDomainConstructor
	{
		public fflib_SObjects construct(List<Object> objectList)
		{
			return new LoanApplications((List<SObject>) objectList);
		}
	}
}
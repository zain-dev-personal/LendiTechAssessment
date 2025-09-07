/**
 * Domain class for Loan Applicaton object
 * This class contain the LoanApplication manipulation methods and trigger methods 
 */
public inherited sharing class LoanApplications extends fflib_SObjectDomain {
    
    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }
    
    // Trigger methods Starts
    // Bulkified trigger method
    // Validate business rules when moving Draft → Submitted
    public override void onBeforeUpdate(Map<Id,SObject> oldMap) {
        Set<Id> borrowerIds = new Set<Id>();
        Boolean isSubmitting = false;

        for (Loan_Application__c la :(List<Loan_Application__c>) this.records) {
            if (la.Borrower__c != null) {
                borrowerIds.add(la.Borrower__c);
            }       
        }
        
        // One query to collect all the Borrower(Contact) Ids for Validation and later use
        Map<Id, Contact> borrowerMap = BorrowerSelector.newInstance().getBorrowerMap(borrowerIds);

        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
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
        }// End for

        if (isSubmitting) {
            // Get the eligible products for the borrower
            Map<Id, Product__c> prdByConLst = LoanApplicationService.getEligibleProductsByContact(borrowerIds);
            
            for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
                Product__c eligibleProduct = prdByConLst.get(la.Borrower__c);

                if (eligibleProduct == null) {
                    la.Rejection_Reason__c = 'Borrower does not meet the product minimum credit score.';
                    la.Status__c = 'Rejected';
                }else{
                    la.Selected_Product__c  = eligibleProduct.Id;
                    la.Status__c = 'Approved';
                }
            }
            
        }
    }

    // Create follow-up Task AFTER update once Loan is Approved
    public override void onAfterUpdate(Map<Id,SObject> oldMap) {
        List<Loan_Application__c> approvedLoans = new List<Loan_Application__c>();

        for (Loan_Application__c rec : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldRec = (Loan_Application__c) oldMap.get(rec.Id);

            if (oldRec.Status__c != 'Approved' && rec.Status__c == 'Approved') {
                approvedLoans.add(rec);
            }
        }
        if (!approvedLoans.isEmpty()) {
            TaskService.prepareDocsTasks(approvedLoans, 'Prepare Document', 'Loan Application');
        }
    }

    //Trigger methods Ends

    public class Constructor implements fflib_SObjectDomain.IConstructable{

        public fflib_SObjectDomain construct(List<SObject> sObjectList){
			return new LoanApplications(sObjectList);
		}
	}
}
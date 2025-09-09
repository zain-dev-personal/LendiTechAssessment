/**
 * Domain class for Loan Applicaton object
 * This class contain the LoanApplication manipulation methods and trigger methods 
 */
public inherited sharing class LoanApplications extends fflib_SObjectDomain {
    
    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }
    
    // Trigger methods Starts
    // Before Validation
    public override void onValidate(Map<Id,SObject> oldMap) {
        Boolean isSubmitting = false;
        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            isSubmitting = oldLapp != null
                        && oldLapp.Status__c == Util.STATUS_DRAFT
                        && la.Status__c == Util.STATUS_SUBMITTED;
        }
        if (isSubmitting) {
            LoanApplicationValidator.handleSubmission((List<Loan_Application__c>) this.records);
        }
        
    }

    // Bulkified trigger method
    // Validate business rules when moving Draft → Submitted
    public override void onAfterUpdate(Map<Id,SObject> oldMap) {
        Set<Id> borrowerIds = new Set<Id>();
        Boolean isSubmitting = false;

        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            if (la.Borrower__c != null) {
                borrowerIds.add(la.Borrower__c);
            } 
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);
            isSubmitting = oldLapp != null
                        && oldLapp.Status__c == Util.STATUS_DRAFT
                        && la.Status__c == Util.STATUS_SUBMITTED;
        }
        if (isSubmitting) {
            // Get the eligible products for the borrower
            Map<Id, Product__c> prdByConLst = LoanApplicationService.getEligibleProductsByContact(borrowerIds);
            // Approve or Reject the load application and create a followup Task if Loan is Approved 
            LoanApplicationService.updateLoanStatus((List<Loan_Application__c>)this.records, prdByConLst);       
        }
    }
    //Trigger methods Ends

    public class Constructor implements fflib_SObjectDomain.IConstructable{

        public fflib_SObjectDomain construct(List<SObject> sObjectList){
			return new LoanApplications(sObjectList);
		}
	}
}
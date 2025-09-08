/**
 * Domain class for Loan Applicaton object
 * This class contain the LoanApplication manipulation methods and trigger methods 
 */
public inherited sharing class LoanApplications extends fflib_SObjectDomain {
    

    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }
    
    // Trigger methods Starts
    // Before Validatonn
    public override void onValidate(Map<Id,SObject> oldMap) {
        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            Boolean isSubmitting = oldLapp != null
                        && oldLapp.Status__c == Util.STATUS_DRAFT
                        && la.Status__c == Util.STATUS_SUBMITTED;
            if (isSubmitting) {
                LoanApplicationValidator.handleSubmission((List<Loan_Application__c>) this.records);
            }
        }
    }

    // Bulkified trigger method
    // Validate business rules when moving Draft → Submitted
    public override void onAfterUpdate(Map<Id,SObject> oldMap) {
        Set<Id> borrowerIds = new Set<Id>();
        Boolean isSubmitting = false;

        for (Loan_Application__c la :(List<Loan_Application__c>) this.records) {
            if (la.Borrower__c != null) {
                borrowerIds.add(la.Borrower__c);
            }       
        }
        
        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            isSubmitting = oldLapp != null
                        && oldLapp.Status__c == Util.STATUS_DRAFT
                        && la.Status__c == Util.STATUS_SUBMITTED;
        }
        if (isSubmitting) {
            // Get the eligible products for the borrower
            Map<Id, Product__c> prdByConLst = LoanApplicationService.getEligibleProductsByContact(borrowerIds);
            List<Loan_Application__c> approvedLoans = new List<Loan_Application__c>();
            List<Loan_Application__c> loanToUpdate = new List<Loan_Application__c>();
            for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
                Product__c eligibleProduct = prdByConLst.get(la.Borrower__c);
                Loan_Application__c updateRecord = new Loan_Application__c();
                if (eligibleProduct == null) {
                    updateRecord.Id = la.Id;
                    updateRecord.Rejection_Reason__c = Util.LOAN_APP_REJECTION_REASON;
                    updateRecord.Status__c = Util.STATUS_REJECTED;
                }else{
                    updateRecord.Id = la.Id;
                    updateRecord.Selected_Product__c = eligibleProduct.Id;
                    updateRecord.Status__c = Util.STATUS_APPROVED;
                    approvedLoans.add(la);
                }
                loanToUpdate.add(updateRecord);
            }
            if (!loanToUpdate.isEmpty()) {
                update loanToUpdate; // explicit DML required in after context
            }
            update loanToUpdate;
            // Create follow-up Task AFTER update once Loan is Approved
            if (!approvedLoans.isEmpty()) {
            TaskService.prepareDocsTasks(approvedLoans, Util.LOAN_APPLICATION_PREPARE_DOCUMENT, Util.TYPE_LOAN_APPLICATION);
            }          
        }
    }
    //Trigger methods Ends

    public class Constructor implements fflib_SObjectDomain.IConstructable{

        public fflib_SObjectDomain construct(List<SObject> sObjectList){
			return new LoanApplications(sObjectList);
		}
	}
}
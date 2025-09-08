/**
 * Domain class for Loan Applicaton object
 * This class contain the LoanApplication manipulation methods and trigger methods 
 */
public inherited sharing class LoanApplications extends fflib_SObjectDomain {
    
    public static final String LOAN_APPLICATION_PREPARE_DOCUMENT = 'Prepare Document';
    public static final String TYPE_LOAN_APPLICATION = 'Loan Application';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_REJECTED = 'Rejected';
    public static final String STATUS_DRAFT = 'Draft';

    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }
    
    // Before Validatonn
    public override void onValidate(Map<Id,SObject> oldMap) {

         System.debug('onValidate---> ' );
        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            Boolean isSubmitting = oldLapp != null
                        && oldLapp.Status__c == 'Draft'
                        && la.Status__c == 'Submitted';
            System.debug('isSubmitting---> '+isSubmitting );
            System.debug('oldLapp.Status__c---> '+oldLapp.Status__c);
            System.debug('la.Status__c---> '+la.Status__c);
            if (isSubmitting) {
                LoanApplicationValidator.handleSubmission((List<Loan_Application__c>) this.records);
            }
        }
    }

    // Trigger methods Starts
    // Bulkified trigger method
    // Validate business rules when moving Draft → Submitted
    public override void onAfterUpdate(Map<Id,SObject> oldMap) {
        System.debug('onAfterUpdate---> ' );
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
                        && oldLapp.Status__c == STATUS_DRAFT
                        && la.Status__c == STATUS_SUBMITTED;
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
                    updateRecord.Rejection_Reason__c = 'Borrower does not meet the product minimum credit score.';
                    updateRecord.Status__c = STATUS_REJECTED;
                }else{
                    updateRecord.Id = la.Id;
                    updateRecord.Selected_Product__c = eligibleProduct.Id;
                    updateRecord.Status__c = STATUS_APPROVED;
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
            TaskService.prepareDocsTasks(approvedLoans, LOAN_APPLICATION_PREPARE_DOCUMENT, TYPE_LOAN_APPLICATION);
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
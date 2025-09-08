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

        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            Boolean isSubmitting = oldLapp != null
                        && oldLapp.Status__c == 'Draft'
                        && la.Status__c == 'Submitted';

            if (isSubmitting) {
                LoanApplicationValidator.handleSubmission((List<Loan_Application__c>) this.records);
            }
        }
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
        
        for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldLapp =  (Loan_Application__c) oldMap.get(la.Id);

            isSubmitting = oldLapp != null
                        && oldLapp.Status__c == STATUS_DRAFT
                        && la.Status__c == STATUS_SUBMITTED;

        }
        if (isSubmitting) {
            // Get the eligible products for the borrower
            Map<Id, Product__c> prdByConLst = LoanApplicationService.getEligibleProductsByContact(borrowerIds);
            
            for (Loan_Application__c la : (List<Loan_Application__c>) this.records) {
                Product__c eligibleProduct = prdByConLst.get(la.Borrower__c);

                if (eligibleProduct == null) {
                    la.Rejection_Reason__c = 'Borrower does not meet the product minimum credit score.';
                    la.Status__c = STATUS_REJECTED;
                }else{
                    la.Selected_Product__c  = eligibleProduct.Id;
                    la.Status__c = STATUS_APPROVED;
                }
            }
            
        }
    }

    // Create follow-up Task AFTER update once Loan is Approved
    public override void onAfterUpdate(Map<Id,SObject> oldMap) {
        List<Loan_Application__c> approvedLoans = new List<Loan_Application__c>();

        for (Loan_Application__c rec : (List<Loan_Application__c>) this.records) {
            Loan_Application__c oldRec = (Loan_Application__c) oldMap.get(rec.Id);

            if (oldRec.Status__c != STATUS_APPROVED && rec.Status__c == STATUS_APPROVED) {
                approvedLoans.add(rec);
            }
        }
        if (!approvedLoans.isEmpty()) {
            TaskService.prepareDocsTasks(approvedLoans, LOAN_APPLICATION_PREPARE_DOCUMENT, TYPE_LOAN_APPLICATION);
        }
    }

    //Trigger methods Ends

    public class Constructor implements fflib_SObjectDomain.IConstructable{

        public fflib_SObjectDomain construct(List<SObject> sObjectList){
			return new LoanApplications(sObjectList);
		}
	}
}
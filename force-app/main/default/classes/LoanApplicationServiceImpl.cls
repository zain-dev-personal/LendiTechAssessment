public class LoanApplicationServiceImpl implements ILoanApplicationService{

    /**
     * Bulkified:
     * - Input: Set of Contact Ids
     * - Output: Map<ContactId, List<Product__c>> with products where
     *   Product.Min_Credit_Score__c <= Contact.Credit_Score__c
     */
    public Map<Id, Product__c> getEligibleProductsByContact(Set<Id> contactIds) {
        Map<Id, Product__c> result = new Map<Id, Product__c>();

        if (contactIds == null || contactIds.isEmpty()) 
            return null;

        // 1) Get Borrowers in one queryContacts (Id, Credit_Score__c) in one query
        List<Contact> borrowers = BorrowerSelector.newInstance().selectByIds(contactIds);
        
        // Build a map of contact Credit scores for fast lookup
        Map<Id, Decimal> scoreByBorrowerId = new Map<Id, Decimal>();
        for (Contact c : borrowers) {
            scoreByBorrowerId.put(c.Id, c.Credit_Score__c);
        }
    
        if (scoreByBorrowerId.isEmpty()) 
            return null;
        
        // 2) Products (ordered by Base rate in one query)
        List<Product__c> products = ProductSelector.newInstance().selectAllProductByBaseRate();
        // 3) For each contact, collect all products with Min <= credit score
        //    Because products are ordered ascending by Base_Rate__c,
        for (Id contactId : scoreByBorrowerId.keySet()) {
            Decimal borrowerScore = scoreByBorrowerId.get(contactId);

            for (Product__c eligibleProduct : products) { 
                if (eligibleProduct.Min_Credit_Score__c <= borrowerScore) {
                    result.put(contactId, eligibleProduct); 
                    // products are sorted; no further products will qualify
                    break;
                }
            }
        }
        return result;
    }
    
    /**
     * Update the Loan Status
     * - If there is no eligible product for the borrower, the loan application will be rejected and rejection reason is set
     * - If there is an eligible product for the borrower, the loan application will be approved and Product is set
     */
    public void updateLoanStatus(List<Loan_Application__c> lApps, Map<Id, Product__c> prdByConLst){
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        
        List<Loan_Application__c> approvedLoans = new List<Loan_Application__c>();
        List<Loan_Application__c> loanToUpdate = new List<Loan_Application__c>();
        for (Loan_Application__c la : lApps) {
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
            // Create follow-up Task AFTER update once Loan is Approved
            List<Task>  taskToCreate = TaskService.prepareDocsTasks(approvedLoans, 
                            Util.LOAN_APPLICATION_PREPARE_DOCUMENT, Util.TYPE_LOAN_APPLICATION);

            uow.registerNew(taskToCreate);
            uow.registerDirty(loanToUpdate);
            uow.commitWork();
        }
	}
}
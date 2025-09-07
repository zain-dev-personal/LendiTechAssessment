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
        List<Contact> contacts = BorrowerSelector.newInstance().selectByIds(contactIds);
        
        // Build a map of contact Credit scores for fast lookup
        Map<Id, Decimal> scoreByBorrowerId = new Map<Id, Decimal>();
        for (Contact c : contacts) {
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
}
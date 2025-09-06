public inherited sharing class ProductSelector extends fflib_SObjectSelector implements IProductSelector{
    
    /* 1. sObjectField list */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Product__c.Id,
            Product__c.Name,
            Product__c.Min_Credit_Score__c,
            Product__c.Base_Rate__c,
            Product__c.Product_Type__c,
            Product__c.Max_Loan_Amount__c,
            Product__c.Min_Loan_Amount__c,
            Product__c.Interest_Rate_Type__c
        };
    }

     /* 2. Boilerplate code */
    public Schema.SObjectType getSObjectType(){
		return Product__c.SObjectType;
	}

    public static ProductSelector newInstance() {
        return new ProductSelector();
    }
  
    public fflib_QueryFactory getQueryFactory() {
        return new fflib_QueryFactory(getSObjectType());
    }

    /* 3. Selector Methods */
    public List<Product__c> selectByIds(Set<Id> idSet) {
        if (idSet.isEmpty()) {
            return new List<Product__c>();
        }
 
        fflib_QueryFactory qf = getQueryFactory();
        qf.selectFields(getSObjectFieldList());
        qf.setCondition('Id IN :idSet');
        return Database.query(qf.toSOQL());
    }

    public Product__c selectById(Id productId) {
        List<Product__c> rows = (List<Product__c>) this.selectByIds(new Set<Id>{ productId });
        return rows.isEmpty() ? null : rows[0];
    }

    // Best eligible product for a given credit score 
    public Product__c selectBestEligibleProduct(Decimal borrowerCreditScore) {
        String whereClause = 'Min_Credit_Score__c <= :borrowerCreditScore';
        fflib_QueryFactory qf = getQueryFactory();

        qf.selectFields(getSObjectFieldList())
        .setCondition(whereClause)
        .addOrdering(Product__c.Base_Rate__c,fflib_QueryFactory.SortOrder.ASCENDING, true)
        .addOrdering(Product__c.Min_Credit_Score__c,fflib_QueryFactory.SortOrder.DESCENDING)
        .setLimit(1);
        List<Product__c> rows = Database.query(qf.toSOQL());
        
        return rows.isEmpty() ? null : rows[0];
    }
}
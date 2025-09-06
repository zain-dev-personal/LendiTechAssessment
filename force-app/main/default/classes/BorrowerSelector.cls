public inherited sharing class BorrowerSelector extends fflib_SObjectSelector implements IBorrowerSelector{
    
    
    /* 1. sObjectField list */
	public List<Schema.SObjectField> getSObjectFieldList(){
		return new List<Schema.SObjectField> {
			Contact.Id,
            Contact.Name,
            Contact.Email,
            Contact.Annual_Income__c,
            Contact.Credit_Score__c
		};
	}

     /* 2. Boilerplate code */
    public Schema.SObjectType getSObjectType(){
		return Contact.SObjectType;
	}

    public static BorrowerSelector newInstance() {
        return new BorrowerSelector();
    }
  
    public fflib_QueryFactory getQueryFactory() {
        return new fflib_QueryFactory(getSObjectType());
    }
 
    /* 3. Selector Methods */
    public List<Contact> selectByIds(Set<Id> idSet) {
        if (idSet.isEmpty()) {
            return new List<Contact>();
        }
 
        fflib_QueryFactory qf = getQueryFactory();
        qf.selectFields(getSObjectFieldList());
        qf.setCondition('Id IN :idSet');
        return Database.query(qf.toSOQL());
    }
 
    public Contact selectById(Id recordId) {
        List<Contact> recordList = selectByIds(new Set<Id>{ recordId });
        return recordList.isEmpty() ? null : recordList[0];
    }
 
    public List<Contact> selectAll() {
        fflib_QueryFactory qf = getQueryFactory();
        qf.selectFields(getSObjectFieldList());
        return Database.query(qf.toSOQL());
    }

    /**
     * Returns a Map<Id, Contact> keyed by Contact Id
     * for Contacts that have Credit_Score__c populated.
     */
    public Map<Id, Contact> getBorrowerMap(Set<Id> idSet) {
        List<Contact> recordList = selectByIds(idSet);
        return new Map<Id, Contact>(recordList);
    }
}
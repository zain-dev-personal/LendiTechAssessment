public class Application {
    // Configure and create the UnitOfWorkFactory for this Application
	public static final fflib_Application.UnitOfWorkFactory UnitOfWork = 
		new fflib_Application.UnitOfWorkFactory(
				new List<SObjectType> {
					Contact.SObjectType,
					Loan_Application__c.SObjectType,
					Product__c.SObjectType,
					Task.SObjectType
				});	

	// Configure and create the ServiceFactory for this Application
	public static final fflib_Application.ServiceFactory Service = 
		new fflib_Application.ServiceFactory( 
			new Map<Type, Type> {
					ILoanApplicationService.class => LoanApplicationServiceImpl.class,
					ITaskService.class => TaskServiceImpl.class
				});

	// Configure and create the SelectorFactory for this Application
	public static final fflib_Application.SelectorFactory Selector = 
		new fflib_Application.SelectorFactory(
			new Map<SObjectType, Type> {
					Contact.SObjectType => BorrowerSelector.class,
					Product__c.SObjectType => ProductSelector.class
				});

	// Configure and create the DomainFactory for this Application
	public static final fflib_Application.DomainFactory Domain = 
		new fflib_Application.DomainFactory(
			Application.Selector,
			new Map<SObjectType, Type> {
					Loan_Application__c.SObjectType => LoanApplications.Constructor.class
				});
}
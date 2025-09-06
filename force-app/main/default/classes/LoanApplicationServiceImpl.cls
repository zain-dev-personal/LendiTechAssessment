public class LoanApplicationServiceImpl implements ILoanApplicationService{

    public static void prepareDocsTasks(List<Loan_Application__c> approvedLApps) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        Date today = Date.today();

        for (Loan_Application__c Lapp : approvedLApps) {
            Task t = new Task();
            t.Subject = 'Prepare documents';
            t.WhatId = Lapp.Id;
            t.OwnerId = Lapp.OwnerId; 
            t.Priority = 'Normal';
            t.Type = 'Loan Application';
            t.ActivityDate = DateUtility.addBusinessDays(today, 2); // add two business days
            t.Status = 'Not Started';
            uow.registerNew(t);
        }
        uow.commitWork();
    }    
}
public with sharing class ProductRateNormalizationJob 
    implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful{
    
    private List<String> errors = new List<String>();
    private Integer totalProcessed = 0; 
    private Integer totalUpdated = 0; 
    private Integer clampedLow = 0; 
    private Integer clampedHigh = 0; 
    private Integer unchanged = 0;

    public void execute(SchedulableContext sc){
		// Start the job once the scheduled time has arrived
		Database.executeBatch(new ProductRateNormalizationJob());		
	}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new ProductSelector().queryLocatorSelectAll();
    }

    public void execute(Database.BatchableContext bc, List<Product__c> products) {
        List<Product__c> toUpdate = new List<Product__c>();

        for (Product__c p : products) {
            totalProcessed++;
            try {
                Decimal br = p.Base_Rate__c;
            
                if (br != null && br < 0.5){ 
                    p.Base_Rate__c = 0.5; 
                    clampedLow++;  
                    toUpdate.add(p); 

                }else if (br != null && br > 15) {
                    p.Base_Rate__c = 15; 
                    clampedHigh++; 
                    toUpdate.add(p); 

                }else {
                    unchanged++; 
                }

            } catch (Exception exp) {
                errors.add('An error occured while updating the Product Base Rate ' + p.Id + ' (' + p.Name + '): ' + exp.getMessage());
            }
        }
        if (!toUpdate.isEmpty()) {
            for (Database.SaveResult r : Database.update(toUpdate, false)) {
                if (r.isSuccess()){
                    totalUpdated++; 

                }else {
                    for (Database.Error err : r.getErrors())
                        errors.add('Update failed for Product ' + err.getMessage());
                }
            }
        }
    }

     public void finish(Database.BatchableContext bc) {
        // Build email body
        String nl = '\n';
        String header =
            'Product Base Rate Clamp - Batch Completed' + nl + nl +
            'Totals:' + nl +
            '• Processed: ' + totalProcessed + nl +
            '• Updated: ' + totalUpdated + nl +
            '• Rate up <0.5% → 0.5%: ' + clampedLow + nl +
            '• Rate down >15%  → 15%: ' + clampedHigh + nl +
            '• Unchanged: ' + unchanged + nl +
            '• Errors: ' + errors.size() + nl + nl;

        
        List<String> errorsLst = new List<String>();

        for (Integer i = 0; i < errors.size(); i++) {
            errorsLst.add((i+1) + ') ' + errors[i]);
        }

        String errorSection;

        if(errors.isEmpty()){
            errorSection = 'No errors recorded.';
        }else{
            errorSection = 'Error details (first ' + errorsLst.size() + '):' + nl + JSON.serialize(errorsLst);
        }
            
        String body = header + errorSection;

        //Send email
        try {
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{UserInfo.getUserEmail()});
            mail.setSubject('Batch Complete: Product Base Rate updated');
            mail.setPlainTextBody(body);
                
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
        } catch (Exception exp) {
            System.debug(LoggingLevel.ERROR, 'Failed sending completion email: ' + exp.getMessage());
        }

        // Also logging a concise line to debug
        System.debug(LoggingLevel.INFO, body);
    }
}
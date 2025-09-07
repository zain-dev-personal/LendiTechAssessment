public with sharing class EmailService {
   
    public static void sendEmail(String address, String body, String subject){
		service().sendEmail(address, body, subject);
	}

    private static IEmailService service(){
		return (IEmailService) Application.Service.newInstance(IEmailService.class);
	}	
}
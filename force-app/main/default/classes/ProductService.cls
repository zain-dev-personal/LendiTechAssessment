public with sharing class ProductService {
    
    public static void sendEmail(String address, String body, String subject){
		service().sendEmail(address, body, subject);
	}

    private static IProductService service(){
		return (IProductService) Application.Service.newInstance(IProductService.class);
	}	
}
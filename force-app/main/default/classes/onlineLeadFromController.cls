public class onlineLeadFromController {
    
    // @AuraEnabled
    // public static string getText(){
    //     try {
    //         return 'apex method called';
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    // @AuraEnabled
    // public static string submitFormWithFile(Map<String, Object> formData) {
    //     try {
    //         String name = (String) formData.get('name');
    //         String phone = (String) formData.get('mobile');
    //         String email = (String) formData.get('email');
    //         List<FileWrapper> files = (List<FileWrapper>) JSON.deserialize(JSON.serialize(formData.get('files')), List<FileWrapper>.class);
    //         System.debug('Files Data: ' + JSON.serialize(files));
    //         if(String.isBlank(name) || String.isBlank(phone) || String.isBlank(email) || files==null || files.size()==0){
    //             throw new AuraHandledException('some issue with form data');
    //         }
    //         string res=boxFormHelperMethods.uploadFileToBox(name,email,phone,files);
    //         if(res!=null){
    //             return res;
    //         }
    //         throw new AuraHandledException('something wrong with file upload');
    //     }
    //     catch(Exception e) {
    //         throw new AuraHandledException('Error submitting form: ' + e.getMessage());
    //     }
    // }

    @AuraEnabled
    public static reponseForLWC getFolderID(Map<String, Object> formData) {
        try {
            String name = (String) formData.get('name');
            String phone = (String) formData.get('mobile');
            String email = (String) formData.get('email');
            //List<FileWrapper> files = (List<FileWrapper>) JSON.deserialize(JSON.serialize(formData.get('files')), List<FileWrapper>.class);
            //System.debug('Files Data: ' + JSON.serialize(files));
            if(String.isBlank(name) || String.isBlank(phone) || String.isBlank(email)){
                throw new AuraHandledException('some issue with form data');
            }
            
            reponseForLWC res=boxFormHelperMethods.uploadFileToBox(name,email,phone);
            if(res!=null){
                return res;
            }
            throw new AuraHandledException('something wrong with file upload');
        }
        catch(Exception e) {
            throw new AuraHandledException('Error submitting form: ' + e.getMessage());
        }
    }




    @AuraEnabled
    public static String verifyCaptcha(SObject record, String recaptchaResponse){
        //https://developers.google.com/recaptcha/docs/verify
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://www.google.com/recaptcha/api/siteverify');
        request.setMethod('POST');
        request.setBody('secret=6LdBTrAqAAAAANpngSdzHziftnackKY-OIAQASER' + '&response=' + recaptchaResponse);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            System.debug(response.getBody());
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (result.containsKey('success') && result.get('success') == true) {
                if (result.containsKey('score')) {
                    //score logic is only needed/returned for v3 (0.0 - 1.0)
                    //https://developers.google.com/recaptcha/docs/v3
                    //TODO: verify action name for the request
                    String action = (String)result.get('action');
                    //TODO: get threshold configuration for each action
                    Decimal threshold = .4;
                    Decimal score = (Decimal)result.get('score');
                    if (score > threshold) {
                        //TODO: perform action on record
                        
                        return 'Success';
                    }
                } else {
                    //TODO: perform action on record
                    
                    return 'Success - v2';
                }
            } else {
                return 'Invalid Verification';
            }
        }
        //consider letting this through
        return 'Invalid Verification Request';
    }
    public class FileWrapper {
    
        public String fileName;
        public String fileContent;
    }
    public class reponseForLWC{
        @AuraEnabled
        public string loanId{get;set;}
        @AuraEnabled
        public string folderId{get;set;}
        

        public reponseForLWC(string folderId,string loanId){
            this.loanId=loanId;
            this.folderId=folderId;
            
        }
    }
    // public class ResponseWrapper {
    //     @AuraEnabled public Integer statusCode { get; set; }
    //     @AuraEnabled public String message { get; set; }
    // }
}
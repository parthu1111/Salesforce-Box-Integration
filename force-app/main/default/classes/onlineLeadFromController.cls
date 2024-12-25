public with sharing class onlineLeadFromController {
    public onlineLeadFromController() {

    }
    @AuraEnabled
    public static string getText(){
        try {
            return 'apex method called';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string submitFormWithFile(Map<String, Object> formData) {
        try {
            String name = (String) formData.get('name');
            String phone = (String) formData.get('mobile');
            String email = (String) formData.get('email');
            List<FileWrapper> files = (List<FileWrapper>) JSON.deserialize(JSON.serialize(formData.get('files')), List<FileWrapper>.class);
            System.debug('Files Data: ' + JSON.serialize(files));
            string res=boxFormHelperMethods.uploadFileToBox(name,email,phone,files);
            if(res!=null){
                return 'files get successfully uploaded';
            }
            return 'something went wrong';
        }
        catch(Exception e) {
            throw new AuraHandledException('Error submitting form: ' + e.getMessage());
        }
    }
    public class FileWrapper {
    
        public String fileName;
        public String fileContent;
    }
}
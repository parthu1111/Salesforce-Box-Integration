public with sharing class boxFormHelperMethods {

    private static final String BOUNDARY = 'BoxApexSDKcjhJ$vXxPaCKo=83up1oadb0undary';
    private static string emailTemplateName;
    private static string adminUserId;
    private static string holdingFolderId;
    private static string folderName;
    private static string backuFolderId;
    private static string emailBody;
    private static string boxBaseUrl;
    private static string organizationWideEmailAdress;

    private static string getSFBoxFolderIdByEmail(string emailID){
        try{
            System.debug('get folder by email.');
            List<string> stages=getCloseAndOpenStage();
            List<Opportunity> loans=[select id,Account.PersonEmail,CoBorrower_Email__c from Opportunity where Account.PersonEmail =:emailID and StageName not In :stages order by CreatedDate desc];
            if(loans.isEmpty()){
                loans=[select id,Account.PersonEmail,CoBorrower_Email__c from Opportunity where CoBorrower_Email__c =:emailID and StageName not In :stages order by CreatedDate desc];
            }
            if(loans.size()>0){
                //take latest loan and find folder id;
                List<box__FRUP__c> frups= [SELECT Id, Name, box__Folder_ID__c, box__Record_ID__c FROM box__FRUP__c where box__Record_ID__c=:loans[0].Id limit 1];
                System.debug('salesforce loan Id :'+loans[0].Id);
                if(frups.size()>0){
                    return frups[0].box__Folder_ID__c;        
                }
                return null;
            }
            return null;
        }
        catch(Exception e){
            throw new CalloutException('Exception : '+e.getMessage());
        }

    }

    private static List<string> getCloseAndOpenStage(){
        try{
            List<OpportunityStage> oppstage=[select id,ApiName, MasterLabel  from OpportunityStage where (IsClosed=true or IsWon =true) and IsActive =true];
            List<string> stageNames=new List<string>();
            for(OpportunityStage stage:oppstage){
                stageNames.add(stage.MasterLabel);
            }
            return stageNames;
        }
        catch(Exception e){
            throw new CalloutException('Exception : '+e.getMessage());
        }
    }

   
    public static string uploadFileToBox(string name,string email,string phone,List<onlineLeadFromController.FileWrapper> files){
        try{
        Experience_cloud_solution__mdt metaData=[SELECT Temp_User_Id__c,Folder_Name__c, Success_Email_Template__c,Holding_Folder_Id__c,BackUp_Folder_Id__c,Email_Body__c,Box_Base_URL__c,Organization_Wide_Email_Addresse__c FROM Experience_cloud_solution__mdt where DeveloperName ='admin' limit 1];
        
        emailTemplateName=metaData.Success_Email_Template__c;
        adminUserId=metaData.Temp_User_Id__c;
        folderName=metaData.Folder_Name__c;
        holdingFolderId=metaData.Holding_Folder_Id__c;
        backuFolderId=metaData.BackUp_Folder_Id__c;
        emailBody=metaData.Email_Body__c;
        boxBaseUrl=metaData.Box_Base_URL__c;
        organizationWideEmailAdress=metaData.Organization_Wide_Email_Addresse__c;
        List<string> recipientEmails=new List<string>{email};
        string sfFolderId=getSFBoxFolderIdByEmail(email);
        
        FolderDetails folderDetail=sfFolderId!=null?getFolderInfo(sfFolderId):null;
        if(folderDetail!=null){
            //FolderDetails folderDetail=getFolderInfo(sfFolderId);
            /*if(folderDetail!=null){
                System.debug('folder exist!');
                string stagingFolderId=getStagingFolderId(folderDetail);
                System.debug('staging folder id :'+stagingFolderId);
                uploadFiles(files, stagingFolderId);
                sendEmail(recipientEmails, adminUserId, emailTemplateName);
                return stagingFolderId;
                
            }
            else{
                System.debug('folder not exist!');
                return null;
                
            }*/
            System.debug('folder exist!');
            string stagingFolderId=getFolderIfExist(folderDetail);
            System.debug('staging folder id :'+stagingFolderId);
            uploadFiles(files, stagingFolderId);
            uploadFilesToBackupFolder(name,email,files);    
            sendEmail(recipientEmails, 'box folder get created successfully!', boxBaseUrl+'/folder/'+stagingFolderId, organizationWideEmailAdress);
            return stagingFolderId;
        }
        else{

            System.debug('loan doesn\'t exist');
            //folderDetail=getFolderInfo(rootFolderId);
            //string stagingFolderId=getStagingFolderId(folderDetail);
            //string customerFolderName=getKey(name, email, phone);
            System.debug('holding folder id :'+holdingFolderId);
            folderDetail=getFolderInfo(holdingFolderId);
            string customerFolderId=null;
            for(Entry entry:folderDetail.item_collection.entries){
                if(getEmail(entry.name)==email){
                    customerFolderId=entry.id;
                    break;
                }
            }
            if(customerFolderId==null){
                FolderDetails customerFolderDetail=createFolder(getCustomFolderName(name,email), holdingFolderId);
                customerFolderId=customerFolderDetail.id;
            }
            System.debug('customer folder id :'+customerFolderId);
            uploadFiles(files, customerFolderId);
            uploadFilesToBackupFolder(name,email,files);
            sendEmail(recipientEmails, 'box folder get created successfully!', boxBaseUrl+'/folder/'+customerFolderId, organizationWideEmailAdress);
            return customerFolderId;
        }
        }
        catch(Exception e){
            throw new CalloutException('Exception : '+e.getMessage());
        }
    }
    private static void uploadFilesToBackupFolder(string name,string email,List<onlineLeadFromController.FileWrapper> files){

        System.debug('backup folder id :'+backuFolderId);
        FolderDetails folderDetail=getFolderInfo(backuFolderId);
        string customerFolderId=null;
        for(Entry entry:folderDetail.item_collection.entries){
            if(getEmail(entry.name)==email){
                customerFolderId=entry.id;
                break;
            }
        }
        if(customerFolderId==null){
            FolderDetails customerFolderDetail=createFolder(getCustomFolderName(name,email), backuFolderId);
            customerFolderId=customerFolderDetail.id;
        }
        System.debug('customer folder id :'+customerFolderId);
        uploadFiles(files, customerFolderId);

    }
    private static string getCustomFolderName(string name,string email){
        string key=name+'-'+email+'-'+DateTime.now().format('yyyy-MM-dd-HH-mm-ss');
        return key;
    }
    private static string getEmail(String folderName){
        string[] parts=folderName.split('-');
        if(parts.size()>1){
            return parts[1];
        }
        return null;
    }
    private static void uploadFiles(List<onlineLeadFromController.FileWrapper> files, string folderId){
        for(onlineLeadFromController.FileWrapper file:files){
            // Append date-time to the file name
            String newFileName = appendDateTimeToFileName(file.fileName);
            System.debug('new file name :'+newFileName);
            uploadFilesIntoFolder(newFileName, folderId, file.fileContent);
        }
    }
    private static String appendDateTimeToFileName(String fileName) {
        // Get the current date-time and format it
        String dateTimeString = DateTime.now().format('yyyy-MM-dd-HH-mm-ss');
        // Split the file name and extension
        Integer lastDotIndex = fileName.lastIndexOf('.');
        if (lastDotIndex == -1) {
            // If there's no extension, just append the date-time
            return fileName + '-' + dateTimeString;
        } else {
            // Extract the base name and extension
            String baseName = fileName.substring(0, lastDotIndex);
            String extension = fileName.substring(lastDotIndex);
            // Combine base name, date-time, and extension
            return baseName + '-' + dateTimeString + extension;
        }
    }
    private static string getFolderIfExist(FolderDetails folderDetail){
        try{
            string stagingFolderId=null;
        for(Entry entry:folderDetail.item_collection.entries){
            if(entry.name==folderName){
                stagingFolderId=entry.id;
                break;
            }
        }
        if(stagingFolderId==null){
            FolderDetails stagingFolderDetail=createFolder(folderName, folderDetail.id);
            stagingFolderId=stagingFolderDetail.id;
        }
        return stagingFolderId;
        }
        catch(Exception e){
            throw new CalloutException('Exception : '+e.getMessage());
        }
    }

    private static FolderDetails getFolderInfo(string folderID){
       try{
            HttpResponse res=makeHttpRequest('/2.0/folders/'+folderID,'GET', null, null);
            System.debug(res.getStatusCode());
            System.debug(res.getBody());
            //Not Found
            if(res.getStatusCode()==200){
                FolderDetails folderDetail=(FolderDetails)JSON.deserialize(res.getBody(),FolderDetails.class);
                System.debug(folderDetail.id);
                return folderDetail;
            }
            else{
                throw new CalloutException('Exception : '+res.getBody());
            }
       }
       catch(Exception e){
           throw new CalloutException(e.getMessage());
       }
       
    }
   
    private static FolderDetails createFolder(string folderName,string ParentFolderId){
        try{
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('name', folderName);
            requestBody.put('parent', new Map<String, String>{'id' => ParentFolderId});
            requestBody.put('folder_upload_email', new Map<String, String>{'access' => 'open'});
            requestBody.put('sync_state', 'synced');
            String jsonBody = JSON.serialize(requestBody);
            HttpResponse res=makeHttpRequest('/2.0/folders', 'POST',jsonBody , null);
            System.debug(res.getBody());
            System.debug(res.getStatusCode());
            if(res.getStatusCode()==201){
                System.debug('folder get created successfully');
                FolderDetails folderDetail=(FolderDetails)JSON.deserialize(res.getBody(),FolderDetails.class);
                return folderDetail;
            }
            else{
                throw new CalloutException('folder isn\'t getting created.');
            }
        }
        catch(Exception e){
            throw new CalloutException(e.getMessage());
        }
    }

    private static void uploadFilesIntoFolder(string fileName,string folderId,string fileContent){
        try{
            //Blob fileBlob = Blob.valueOf(fileContent);
            Blob fileBlob = EncodingUtil.base64Decode(fileContent);
            String fullUrl = 'callout:Upload_Box_Api/api/2.0/files/content?parent_id='+folderId;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(fullUrl);
            Map<String, String> additionalHeaders = new Map<String, String>();
            additionalHeaders.put('Content-Type', 'multipart/form-data; boundary=' + BOUNDARY);
            additionalHeaders.put('Accept-Encoding', 'gzip');
            additionalHeaders.put('Accept-Charset', 'utf-8');  
            Blob bodyBlob = BoxBase64.buildMultipartFileBody(fileBlob,fileName,BOUNDARY);
            request.setBodyAsBlob(bodyBlob);
            additionalHeaders.put('Content-Length',String.valueof(request.getBodyAsBlob().size()));
            for (String headerName : additionalHeaders.keySet()) {
                request.setHeader(headerName, additionalHeaders.get(headerName));
            }
            HttpResponse res=http.send(request);
            System.debug(res.getBody());
            System.debug(res.getStatusCode()); 
            if(res.getStatusCode()==201){
                System.debug('file get successfully uploaded!');
            }  
            else{
                
                throw new CalloutException('Exception :'+res.getBody());
            }
        }
        catch(Exception e){
            throw new CalloutException(e.getMessage());
        }
    }
    private static HttpResponse makeHttpRequest( String endpointUrl, String httpMethod, String requestBody, Map<String, String> additionalHeaders) {
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            String fullUrl = 'callout:Box_API_Equinox' + endpointUrl;
            // Set request details
            request.setEndpoint(fullUrl);
            request.setMethod(httpMethod);
            
            
            request.setHeader('Content-Type', 'application/json');
            // Set the request body, if provided
            if (!String.isBlank(requestBody)) {
                request.setBody(requestBody);
                request.setHeader('Content-Length', request.getBody().length().toString());
            }
            //request.setHeader('Content-Length', request.getBody().length().toString());
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            // Add additional headers, if provided
            if (additionalHeaders != null) {
                for (String headerName : additionalHeaders.keySet()) {
                    request.setHeader(headerName, additionalHeaders.get(headerName));
                }
            }
            // Send the HTTP request
            HttpResponse response=http.send(request);
            return response;
        }
        catch(Exception e){
            throw new CalloutException(e.getMessage());
        }
    } 

    public static void getToken(){
        String requestBody = 'grant_type=client_credentials'
                         + '&client_id=' + EncodingUtil.urlEncode('cqw8jzbdi52cvj997c1gutsgltspf0zh', 'UTF-8')
                         + '&client_secret=' + EncodingUtil.urlEncode('1H1gxqpgawdEBCyl667DJkbuiteydz6W', 'UTF-8');

        // Call the makeHttpRequest method
        Map<string,string> headers=new Map<string,string>{'Content-Type'=>'application/x-www-form-urlencoded'};
        HttpResponse res = makeHttpRequest('/oauth2/token', 'POST', requestBody, headers);

        // Print the response to debug
        System.debug(res.getBody());
    }
    @Future(callout=true)
    public static void moveFilesToLoanFolder(List<string> frupIds){
        System.debug('moveFilesToLoanFolder called....');
        Experience_cloud_solution__mdt setting=[select id,Holding_Folder_Id__c,Folder_Name__c from Experience_cloud_solution__mdt limit 1];
        holdingFolderId=setting.Holding_Folder_Id__c;
        folderName=setting.Folder_Name__c;
        System.debug('holding folder id :'+holdingFolderId);
        List<box__FRUP__c> frups=[select box__Folder_ID__c,box__Record_ID__c from box__FRUP__c where id in:frupIds];
        Map<string,string> loanToBoxId=new Map<string,string>();
        Map<string,List<string>> loanToRootFolders=new Map<string,List<string>>();
        for(box__FRUP__c frup:frups){
            loanToBoxId.put(frup.box__Record_ID__c, frup.box__Folder_ID__c);
        }
        List<Opportunity> loans=[select id,Account.PersonEmail,CoBorrower_Email__c from Opportunity where id in:loanToBoxId.keySet()];
        //FolderDetails folderDetail=getFolderInfo(rootFolderId);
        //string stagingFolderId=getStagingFolderId(folderDetail);
        FolderDetails stagingFolderDetail=getFolderInfo(holdingFolderId);
        Map<string,string> keyToFolderId=new Map<string,string>();
        if(stagingFolderDetail.item_collection!=null){
            for(Entry entry:stagingFolderDetail.item_collection.entries){
                string folderEmail=getEmail(entry.name);
                keyToFolderId.put(folderEmail, entry.id);
            }
        }
        for(Opportunity loan:loans){
            //string key=getKey(loan.Borrower_Name__c, loan.BorrowerEmail__c, loan.BorrowerHomePhone__c);
            //System.debug(key);
            if(loan.Account.PersonEmail!=null && keyToFolderId.containsKey(loan.Account.PersonEmail)){
               string rootFolderId=keyToFolderId.get(loan.Account.PersonEmail);
               string detinationFolderId=loanToBoxId.get(loan.Id);
               movefile(rootFolderId, detinationFolderId);
            }
            else if(loan.CoBorrower_Email__c!=null && keyToFolderId.containsKey(loan.CoBorrower_Email__c)){
                string rootFolderId=keyToFolderId.get(loan.CoBorrower_Email__c);
                string detinationFolderId=loanToBoxId.get(loan.Id);
                movefile(rootFolderId, detinationFolderId);
            }
        }
    }
    private static void movefile(string sourceId,string destinationId){
        System.debug('move file');
        System.debug('source id :'+sourceId);
        System.debug('destination id :'+destinationId);
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('name', folderName);
        requestBody.put('parent', new Map<String, String>{'id' => destinationId});
        String jsonBody = JSON.serialize(requestBody);
        HttpResponse res=makeHttpRequest('/2.0/folders/'+sourceId, 'PUT',jsonBody , null);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        if(res.getStatusCode()==200){
            System.debug('file get moved successfully');
        }
        else{
            throw new CalloutException('file isn\'t getting moved.');
        }
    }
    public static void sendEmail(List<string> recipientEmails,string subject,string boxLink, string defaultEmail) {
        try {
            //string mergeEmailBody='<html><body><h1>Welcome,</h1><p>We are excited to have you on board. Please feel free to reach out if you have any questions.</p></body></html>';
            string mergeEmailBody = emailBody.replace('{!boxLink}', boxLink);
            //EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //mail.setTargetObjectId(targetId);
            //mail.setWhatId(whatId);
            //mail.setTemplateId(template.Id);
            List<OrgWideEmailAddress> adresses=[select Id from OrgWideEmailAddress where Address =: defaultEmail];
            if(adresses.size()>0){
                System.debug('org wide email address id :'+adresses[0].Id);
                mail.setOrgWideEmailAddressId(adresses[0].Id);
            }
            mail.setToAddresses(recipientEmails);
            mail.setSaveAsActivity(false);
            //mail.setTreatTargetObjectAsRecipient(false);
            mail.setSubject(subject);
            mail.setHtmlBody(mergeEmailBody);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            System.debug('Email sent successfully to' + recipientEmails);
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            throw new CalloutException('Error sending email: ' + e.getMessage());
        }
    }
    public class CalloutException extends Exception {}

    public class Authorization{
        public string access_token;
        public string token_type;
        public Integer expires_in;
        public string refresh_token;
    }

    public class FolderDetails{
        public String id;
        public string name;
        public ItemCollection item_collection;
    }
    public class ItemCollection {
        public Integer total_count;
        public List<Entry> entries;
    }
    public class Entry {
        public String id;
        public String name;
    }
}
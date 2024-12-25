public with sharing class boxFormHelperMethods {

    public static final string stagingFolderName='Experience Cloud Solution';
    public static final string rootFolderId='254281192452';
    private static final String BOUNDARY = 'BoxApexSDKcjhJ$vXxPaCKo=83up1oadb0undary';

    public static string getSFBoxFolderIdByEmail(string emailID){
        System.debug('get folder by email.');
        List<Opportunity> loans=[select id,BorrowerEmail__c,Borrower_Name__c, Name from Opportunity where BorrowerEmail__c =:emailID order by CreatedDate desc];
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

    /*public static void uploadFileToBox(string folderId,string fileName,string fileContent,string name,string email,string phone){
        Authorization auth=getAccessToken();
        //Authorization auth=new Authorization();
        if(auth!=null){
            BoxApiConnection api = new BoxApiConnection(auth.access_token);
            Attachment fileAttachment = new Attachment();
            fileAttachment.Body = Blob.valueOf(fileContent);
            fileAttachment.Name = fileName;
            string customerFolderName=name+'-'+email+'-'+phone;
            if(folderId!=null){
                FolderDetails folderDetail=getFolderInfo(folderId);
                if(folderDetail!=null){
                    System.debug('folder exist!');
                    string stagingFolderId=null;
                    for(Entry entry:folderDetail.item_collection.entries){
                        if(entry.name==stagingFolderName){
                            stagingFolderId=entry.id;
                            break;
                        }
                    }
                    if(stagingFolderId==null){
                        System.debug('before create folder');
                        FolderDetails stagingFolderDetail=createFolder(stagingFolderName, folderDetail.id);
                        System.debug('after create folder');
                        System.debug('before upload file');
                        stagingFolderId=stagingFolderDetail.id;
                    }
                    System.debug('staging folder id :'+stagingFolderId);
                    uploadFile(fileName, stagingFolderId, fileContent);
                    //ItemCollection files=uploadFile(fileName,stagingFolderId,fileContent);
                    //System.debug('number of file get created :'+files.total_count);
                    
                    
                    System.debug(fileName);
                    //BoxFolder folder = new BoxFolder(api, stagingFolderId);
                    //BoxFile.Info fileInfo = folder.uploadFile(fileAttachment, fileName);

                }
                else{
                    System.debug('folder not exist!');
                    
                }
            }
            else{
                System.debug('loan doesn\'t exist');
                string stagingFolderId=null;
                BoxFolder folder = new BoxFolder(api, rootFolderId);
                list<BoxItem.Info> children = folder.getChildren();
                //find staging folder
                for (BoxItem.Info boxItem : children) {
                    if( boxItem.getName()==stagingFolderName){
                        stagingFolderId=boxItem.id;
                        break;
                    }
                }
                if(stagingFolderId==null){
                    //staging folder not exist
                    BoxFolder.Info folderInfo=createFolder2(stagingFolderName,rootFolderId,api);
                    System.debug(folderInfo.id);
                    stagingFolderId=folderInfo.id;
                }
                System.debug('staging folder id :'+stagingFolderId);
                //find user folder
                folder = new BoxFolder(api, rootFolderId);
                children = folder.getChildren();
                string customerFolderId=null;
                for (BoxItem.Info boxItem : children) {
                    if( boxItem.getName()==customerFolderName){
                        customerFolderId=boxItem.id;
                        break;
                    }
                }
                if(customerFolderId==null){
                    System.debug('customer folder doesn\'t exist');
                    BoxFolder.Info folderInfo=createFolder2(customerFolderName,stagingFolderId,api);
                    customerFolderId=folderInfo.id;
                }
                System.debug('customer folder id :'+customerFolderId);
                BoxFile.Info file=createFile2(fileName,fileAttachment,api,customerFolderId);
                System.debug(file.id);

            }
            updateAccessToken(auth.access_token, auth.refresh_token);
        }
    }
*/
    public static string uploadFileToBox(string name,string email,string phone,List<onlineLeadFromController.FileWrapper> files){

        string sfFolderId=getSFBoxFolderIdByEmail(email);
        string customerFolderName=getKey(name, email, phone);
        if(sfFolderId!=null){
            FolderDetails folderDetail=getFolderInfo(sfFolderId);
            if(folderDetail!=null){
                System.debug('folder exist!');
                string stagingFolderId=getStagingFolderId(folderDetail);
                // for(Entry entry:folderDetail.item_collection.entries){
                //     if(entry.name==stagingFolderName){
                //         stagingFolderId=entry.id;
                //         break;
                //     }
                // }
                // if(stagingFolderId==null){
                //     FolderDetails stagingFolderDetail=createFolder(stagingFolderName, folderDetail.id);
                //     stagingFolderId=stagingFolderDetail.id;
                // }
                System.debug('staging folder id :'+stagingFolderId);
                uploadFiles(files, stagingFolderId);
                return stagingFolderId;
            }
            else{
                System.debug('folder not exist!');
                return null;
                
            }
        }
        else{
            System.debug('loan doesn\'t exist');
            FolderDetails folderDetail=getFolderInfo(rootFolderId);
            string stagingFolderId=getStagingFolderId(folderDetail);
            // for(Entry entry:folderDetail.item_collection.entries){
            //     if(entry.name==stagingFolderName){
            //         stagingFolderId=entry.id;
            //         break;
            //     }
            // }
            // if(stagingFolderId==null){
            //     FolderDetails stagingFolderDetail=createFolder(stagingFolderName, folderDetail.id);
            //     stagingFolderId=stagingFolderDetail.id;
            // }
            System.debug('staging folder id :'+stagingFolderId);
            folderDetail=getFolderInfo(stagingFolderId);
            string customerFolderId=null;
            for(Entry entry:folderDetail.item_collection.entries){
                if(entry.name==customerFolderName){
                    customerFolderId=entry.id;
                    break;
                }
            }
            if(customerFolderId==null){
                FolderDetails customerFolderDetail=createFolder(customerFolderName, stagingFolderId);
                customerFolderId=customerFolderDetail.id;
            }
            System.debug('customer folder id :'+customerFolderId);
            uploadFiles(files, customerFolderId);
            return customerFolderId;
        }
    }
    private static string getKey(String name,string email,string phone){
        string key=name+'-'+email+'-'+phone;
        return key;
    }
    private static void uploadFiles(List<onlineLeadFromController.FileWrapper> files, string folderId){
        for(onlineLeadFromController.FileWrapper file:files){
            uploadFilesIntoFolder(file.fileName, folderId, file.fileContent);
        }
    }
    private static string getStagingFolderId(FolderDetails folderDetail){
        string stagingFolderId=null;
        for(Entry entry:folderDetail.item_collection.entries){
            if(entry.name==stagingFolderName){
                stagingFolderId=entry.id;
                break;
            }
        }
        if(stagingFolderId==null){
            FolderDetails stagingFolderDetail=createFolder(stagingFolderName, folderDetail.id);
            stagingFolderId=stagingFolderDetail.id;
        }
        return stagingFolderId;
    }

    private static FolderDetails getFolderInfo(string folderID){
        HttpResponse res=makeHttpRequest('/2.0/folders/'+folderID,'GET', null, null);
        System.debug(res.getStatus());
        System.debug(res.getBody());
        //Not Found
        if(res.getStatus()=='OK'){
            FolderDetails folderDetail=(FolderDetails)JSON.deserialize(res.getBody(),FolderDetails.class);
            System.debug(folderDetail.id);
            return folderDetail;
        }
        else{
            return null;
        }
    }
    /*
    public static FolderDetails getFolderInfo2(string folderID, BoxApiConnection api){
        try{
            BoxFolder folder = new BoxFolder(api, folderID);
            BoxFolder.Info info = folder.getFolderInfo();
        }
        catch(Exception e){
            System.debug(e.getMessage());
            
        }
        //System.debug(folder);
        return null;
    }
    public static BoxFolder.Info createFolder2(string folderName,string parentFolderId,BoxApiConnection api){
        BoxFolder parentFolder = new BoxFolder(api, parentFolderId);
        BoxFolder.Info childFolderInfo = parentFolder.createFolder(folderName);
        return childFolderInfo;
    }
    public static BoxFile.Info createFile2(string fileName,Attachment attachment,BoxApiConnection api,string folderId){
        BoxFolder folder = new BoxFolder(api, folderId);
        return folder.uploadFile(attachment,fileName);
    }
    
    public static Authorization getAccessToken(){
        Box_Api_Cred__c cred=[select id,Name, Client_Id__c, Client_Secret__c, Refresh_Token__c,Access_Token__c from Box_Api_Cred__c where name='Experience Cloud Solution' limit 1];
        Map<String, string> additionalHeader = new Map<String, string>();
        additionalHeader.put('Content-Type', 'application/x-www-form-urlencoded');
        Map<String, string> requestBody = new Map<String, string>();
        requestBody.put('client_id', cred.Client_Id__c);
        requestBody.put('client_secret', cred.Client_Secret__c);
        requestBody.put('grant_type', 'refresh_token');
        requestBody.put('refresh_token',cred.Refresh_Token__c );
        String formattedBody = '';
        for (String key : requestBody.keySet()) {
            String encodedKey = EncodingUtil.urlEncode(key, 'UTF-8');
            String encodedValue = EncodingUtil.urlEncode(requestBody.get(key), 'UTF-8');
            formattedBody += encodedKey + '=' + encodedValue + '&';
        }
        // Remove the trailing '&' if present
        if (formattedBody.endsWith('&')) {
            formattedBody = formattedBody.substring(0, formattedBody.length() - 1);
        }
        //string body=JSON.serialize(requestBody);
        HttpResponse res=makeHttpRequest('/oauth2/token', 'POST',formattedBody, additionalHeader);
        System.debug(res.getStatusCode());
        System.debug(res.getBody());
        if(res.getStatusCode()==200){
            Authorization auth=(Authorization)JSON.deserialize(res.getBody(),Authorization.class);
            cred.Access_Token__c=auth.access_token;
            cred.Refresh_Token__c=auth.refresh_token;
            // update cred;
            //updateAccessToken(auth.access_token,auth.refresh_token);
            
            return auth;
        }
        else{
            throw new CalloutException('Failed to get access token');
        }
    }
        public static void updateAccessToken(String accessToken, String refreshToken) {
            Box_Api_Cred__c cred = [
                SELECT Id 
                FROM Box_Api_Cred__c 
                WHERE Name = 'Experience Cloud Solution' 
                LIMIT 1
            ];
            
            cred.Access_Token__c = accessToken;
            cred.Refresh_Token__c = refreshToken;
            
            // Perform the update in a separate transaction
            update cred;
        }*/
    private static FolderDetails createFolder(string folderName,string ParentFolderId){
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

    private static void uploadFilesIntoFolder(string fileName,string folderId,string fileContent){
        Blob fileBlob = Blob.valueOf(fileContent);
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
            throw new CalloutException('file hasn\'t uploaded....');
        }
    }
    private static HttpResponse makeHttpRequest( String endpointUrl, String httpMethod, String requestBody, Map<String, String> additionalHeaders) {
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
        }
        // Add additional headers, if provided
        if (additionalHeaders != null) {
            for (String headerName : additionalHeaders.keySet()) {
                request.setHeader(headerName, additionalHeaders.get(headerName));
            }
        }
        // Send the HTTP request
        HttpResponse response;
        try {
            response = http.send(request);
        } catch (Exception ex) {
            System.debug('Error making HTTP callout: ' + ex.getMessage());
            throw new CalloutException('Failed to make HTTP callout: ' + ex.getMessage());
        }

        return response;
    } 
    @Future(callout=true)
    public static void moveFilesToLoanFolder(List<string> frupIds){
        System.debug('moveFilesToLoanFolder called....');
        List<box__FRUP__c> frups=[select box__Folder_ID__c,box__Record_ID__c from box__FRUP__c where id in:frupIds];
        Map<string,string> loanToBoxId=new Map<string,string>();
        Map<string,List<string>> loanToRootFolders=new Map<string,List<string>>();
        for(box__FRUP__c frup:frups){
            loanToBoxId.put(frup.box__Record_ID__c, frup.box__Folder_ID__c);
        }
        List<Opportunity> loans=[select id,BorrowerEmail__c, Borrower_Name__c, BorrowerHomePhone__c from Opportunity where id in:loanToBoxId.keySet()];
        FolderDetails folderDetail=getFolderInfo(rootFolderId);
        string stagingFolderId=getStagingFolderId(folderDetail);
        FolderDetails stagingFolderDetail=getFolderInfo(stagingFolderId);
        Map<string,string> keyToFolderId=new Map<string,string>();
        for(Entry entry:stagingFolderDetail.item_collection.entries){
            keyToFolderId.put(entry.name, entry.id);
        }
        for(Opportunity loan:loans){
            string key=getKey(loan.Borrower_Name__c, loan.BorrowerEmail__c, loan.BorrowerHomePhone__c);
            System.debug(key);
            if(keyToFolderId.containsKey(key)){
               string rootFolderId=keyToFolderId.get(key);
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
        requestBody.put('name', stagingFolderName);
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
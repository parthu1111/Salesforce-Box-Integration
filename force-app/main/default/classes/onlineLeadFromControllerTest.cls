@isTest
private with sharing class onlineLeadFromControllerTest {
    // private static Id PERSON_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    // private static Id Opp_RI = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Purchase').getRecordTypeId();
    @TestSetup
    static void makeData(){
        BoxAPIMock mock = new BoxAPIMock(200, '{"id": "12345","name":"test-test2@gmail.com", "size": 0,"item_collection":{"total_count":2, "entries":[{"id":"1", "name":"test-test2@gmail.com"},{"id":"2", "name":"File2"}]}}');
        Test.setMock(HttpCalloutMock.class, mock); 
        createData();
        
        

    }
    static void createData(){
        Id PERSON_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Id Opp_RI = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Purchase').getRecordTypeId();
        Account acc=new Account();
        acc.LastName='Test Account';
        acc.PersonEmail='test2@gmail.com';
        acc.RecordTypeId=PERSON_RT;
        insert acc;

        Opportunity opp = new Opportunity();
        opp.LeadSource='Direct Mail';
        opp.Loan_Number__c='123456';
        opp.AccountId=acc.Id;
        opp.Name='Test Opportunity';
        opp.CloseDate=Date.today();
        opp.StageName='Application Completed';
        opp.RecordTypeId=Opp_RI;
        opp.EncompassId__c = '99a5f8a8-8361-4329-88be-21d3ddda8c28';
        insert opp;

        box__FRUP__c frup=new box__FRUP__c();
        frup.box__Record_ID__c=opp.Id;
        frup.box__Folder_ID__c='99999';
        insert frup;

        System.debug('data get created!');
    }

    @isTest
    static void testCase1(){
        Map<String, Object> formData = new Map<String, Object>();
        formData.put('name', 'test1');
        formData.put('mobile', '1234567890');
        formData.put('email', 'test1@gmail.com');
        List<onlineLeadFromController.FileWrapper> files = new List<onlineLeadFromController.FileWrapper>();
        onlineLeadFromController.FileWrapper file1 = new onlineLeadFromController.FileWrapper();
        file1.fileName = 'TestFile1.txt';
        file1.fileContent = 'Sample content for file 1';
        files.add(file1);
        formData.put('files', files);
        Test.setMock(HttpCalloutMock.class, new boxAPIMockout());
        Test.startTest();
        onlineLeadFromController.submitFormWithFile(formData);
        Test.stopTest();
    }

    @isTest
    static void testCase2(){
        
        Map<String, Object> formData = new Map<String, Object>();
        formData.put('name', 'test1');
        formData.put('mobile', '1234567890');
        formData.put('email', 'test2@gmail.com');
        List<onlineLeadFromController.FileWrapper> files = new List<onlineLeadFromController.FileWrapper>();
        onlineLeadFromController.FileWrapper file1 = new onlineLeadFromController.FileWrapper();
        file1.fileName = 'TestFile1.txt';
        file1.fileContent = 'Sample content for file 1';
        files.add(file1);
        formData.put('files', files);
        Test.setMock(HttpCalloutMock.class, new boxAPIMockout());
        Test.startTest();
        onlineLeadFromController.submitFormWithFile(formData);
        Test.stopTest();
    }

    @isTest
    static void testCase3(){
        Test.setMock(HttpCalloutMock.class, new boxAPIMockout());
        Test.startTest();
        onlineLeadFromController.verifyCaptcha(null,'12345');
        Test.stopTest();
    }
}
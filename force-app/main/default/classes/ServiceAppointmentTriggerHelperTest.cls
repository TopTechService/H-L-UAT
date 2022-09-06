@isTest
public class ServiceAppointmentTriggerHelperTest {
    @TestSetup
    public static void testData() {

        //Create Account Record
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        accountRecord.market_vertical__c = 'Bakery';
        accountRecord.Core_POS_System__c = 'Bluefrog';
        insert accountRecord;
        
        //Create Contact record
        contact contactRecord = new contact();
        contactRecord.LastName = 'Test Contact';
        contactRecord.Email = 'test.contact@gmail.com';
        contactRecord.AccountId = accountRecord.Id;
        insert contactRecord;

        //Create Work Order
		WorkOrder testWorkOrder = new WorkOrder();
        testWorkOrder.AccountId = accountRecord.Id;
        testWorkOrder.ContactId = contactRecord.Id;
        testWorkOrder.Status = 'New';
        testWorkOrder.Priority = 'Low';
        testWorkOrder.Street = '1 Test Street';
        testWorkOrder.City = 'Testville';
        testWorkOrder.State = 'New South Wales';
        testWorkOrder.StateCode = 'NSW';
        testWorkOrder.PostalCode = '2000';
        testWorkOrder.Country = 'Australia';
        testWorkOrder.CountryCode = 'AU';
        insert testWorkOrder;
        
        
        //Create Service Appointment
		ServiceAppointment testServiceAppointment = new ServiceAppointment();
        testServiceAppointment.Subject = 'Testing';
        testServiceAppointment.Status = 'None';
        testServiceAppointment.EarliestStartTime = Datetime.now();
        testServiceAppointment.DueDate = Datetime.now().addDays(1);
        testServiceAppointment.ParentRecordId = testWorkOrder.Id;
        insert testServiceAppointment;
                
        //Create Custom Setting 
        List<SeviceAppointmentReportMail__c> settingList= new List<SeviceAppointmentReportMail__c>();
        
        for(Integer i=0;i<2;i++){
            SeviceAppointmentReportMail__c customSetting = new SeviceAppointmentReportMail__c();
            customSetting.email__c = 'test@xyz.com';
            customSetting.Name = 'Test'+i;
            customSetting.Name__c = 'test'+i;
            settingList.add(customSetting);
        }
        System.debug('settingList'+settingList);
        Insert settingList;
        
        //Create Service Report for the Service Appointment
        Attachment serviceReport = new Attachment();
        Blob bodyBlob = Blob.valueOf('Test Data');
        serviceReport.Name = 'SA-0101';
        serviceReport.body = bodyBlob;
        serviceReport.parentId = testServiceAppointment.id;
        Insert serviceReport;
        
        //Create Content Version
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = 'SA-0101';
        contentVersion.Title = 'SA-0101';
        contentVersion.VersionData = bodyBlob;
        insert contentVersion;
        
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        ContentVersion version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        contentDocumentLink.ContentDocumentId = version.contentDocumentId;
        contentDocumentLink.LinkedEntityId = testServiceAppointment.id;
        contentDocumentLink.ShareType = 'I'; // Inferred permission
        insert contentDocumentLink;
    }
    
    @isTest 			
    static void test() {
        ServiceAppointment serviceAppointment = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
        
		serviceAppointment.Status = 'Scheduled';
        update serviceAppointment;
        
		serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        
		serviceAppointment.Status = 'In Progress';
        update serviceAppointment;

        integer numBefore =  Limits.getEmailInvocations();
        system.debug('NumBefore:' + numBefore);
                                                 
        test.startTest();
        	serviceAppointment.Status = 'Completed';
            serviceAppointment.Email_Trigger__c = true;
            update serviceAppointment;
            
            integer invocations =  Limits.getEmailInvocations();
        test.stopTest();
        
        System.assertEquals(0, numBefore);
        System.assertEquals(1, invocations, 'An email has not been sent');
    }
}
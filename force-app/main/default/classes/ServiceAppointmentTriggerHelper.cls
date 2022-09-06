public class ServiceAppointmentTriggerHelper {
    
    public static void email_send(Map<Id,ServiceAppointment> mapNewServiceAppointments,Map<Id,ServiceAppointment> mapOldServiceAppointments) {
        //Created List of Email
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        
        //Close Service Appointment List
        List<ServiceAppointment> closedServiceAppointments = New List<ServiceAppointment>();
        List<String> closedServiceAppointmentIds = new List<String>();
        
        for(ServiceAppointment sa :mapNewServiceAppointments.values()) {
            System.debug('oldMap:' + mapOldServiceAppointments.get(sa.Id).Email_Trigger__c);
            System.debug('new:' + sa.Email_Trigger__c);
            if(sa.Email_Trigger__c && !mapOldServiceAppointments.get(sa.Id).Email_Trigger__c) {
                closedServiceAppointmentIds.add(sa.Id);
                closedServiceAppointments.add(sa);
            }
        }
        System.debug('CLosedSA:' + closedServiceAppointments);
        if(!closedServiceAppointments.isEmpty()) {
            //Query Template to use in Email
            EmailTemplate emailtempRecord  = [Select id, Name, Body, Subject, HtmlValue
                                              from EmailTemplate 
                                              where Name =: 'TS Closed SA Notification'];

            //Query Content Document Links related to Service Appointments
            Map<Id, List<String>> documentLinkMap = new Map<Id, List<String>>();
            List<String> contentDocumentIds = new List<String>();

            for(ContentDocumentLink documentLink : [SELECT Id, LinkedEntityId, ContentDocumentId 
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId IN :closedServiceAppointmentIds]) {
                                                        if(!documentLinkMap.containsKey(documentLink.LinkedEntityId)) {
                                                            documentLinkMap.put(documentLink.LinkedEntityId,new List<String>());
                                                        }
                                                        documentLinkMap.get(documentLink.LinkedEntityId).add(documentLink.ContentDocumentId);
                                                        contentDocumentIds.add(documentLink.ContentDocumentId);
                                                    }

            //Build a map of content documents and latest versions
            Map<Id, String> documentLatestVersionMap = new Map<Id, String>();
            for(ContentDocument documentRecord : [SELECT Id, LatestPublishedVersionId
                                                  FROM ContentDocument
                                                  WHERE Id IN :contentDocumentIds]) {
                                                      documentLatestVersionMap.put(documentRecord.Id, documentRecord.LatestPublishedVersionId);
                                                  }

            //Build a map of Service Appointments and ContentVersions
            Map<Id, List<String>> documentVersionMap = new Map<Id, List<String>>();
            Map<Id, Id> contentVersionServiceAppointmentMap = new Map<Id, Id>();
            List<Id> contentVersionIds = new List<Id>();

            for(Id idValue :documentLinkMap.keySet()) {
                if(!documentVersionMap.containsKey(idValue)) {
                    documentVersionMap.put(idValue, new List<String>());
                }
                for(String str :documentLinkMap.get(idValue)) {
                    documentVersionMap.get(idValue).add(documentLatestVersionMap.get(str));
                    contentVersionIds.add(documentLatestVersionMap.get(str));
                    contentVersionServiceAppointmentMap.put(documentLatestVersionMap.get(str), idValue);
                }
            }

            //Query Content Versions related to customer form
            Map<ID, List<ContentVersion>> attachmentMap = new Map<Id, List<ContentVersion>>();
            System.debug('contentVersion IDs:' + contentVersionIds);
            for(ContentVersion attachRecords : [SELECT Id, Title, VersionData
                                                FROM ContentVersion
                                                WHERE Title Like 'SA-%' AND Id IN :contentVersionIds]) {
                                                    if(!attachmentMap.containsKey(contentVersionServiceAppointmentMap.get(attachRecords.Id))) {
                                                        attachmentMap.put(contentVersionServiceAppointmentMap.get(attachRecords.Id),new List<ContentVersion>());
                                                    }
                                                    attachmentMap.get(contentVersionServiceAppointmentMap.get(attachRecords.Id)).add(attachRecords);
                                              } 

            
            //Create List of Emails to whome Email is to be sent
            List<String> toAddressList= new List<String>();
            
            for(SeviceAppointmentReportMail__c customMailList :SeviceAppointmentReportMail__c.getall().values()) {
                if(!String.isBlank(customMailList.email__c)) {
                    toAddressList.add(customMailList.email__c);
                }
            }

            //Get the org wide address to be used as the from address
            String orgWideEmailAddressID;
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'troy@apiresoftware.com'];
            if ( owea.size() > 0 ) {
                orgWideEMailAddressID = owea.get(0).Id;
            }
            
            for(ServiceAppointment saRecord :closedServiceAppointments) {
                //Created List of Attachments related to every Service Appointment
                List<Id> ownerIDs = New List<Id>();
                if(saRecord.Email_Trigger__c && !toAddressList.isEmpty() ) {
                    System.debug('SA: ' + saRecord.Id);
                    System.debug('Map:' + attachmentMap);
                    System.debug('Map Value: ' + attachmentMap.get(saRecord.Id));
                    Messaging.SingleEmailMessage renderTemplate = Messaging.renderStoredEmailTemplate(emailtempRecord.Id, saRecord.FSSK__FSK_Assigned_Service_Resource__c, saRecord.Id); 
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(toAddressList);
                    ownerIDs.add(saRecord.OwnerId);
                    mail.setCcAddresses(OwnerIDs);
                    mail.setSubject(renderTemplate.getSubject());
                    mail.setHtmlBody(renderTemplate.getHtmlBody());
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressID);
                    
                    //Add attachments
                    List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                    if(attachmentMap.get(saRecord.Id) != null) {

                        for (ContentVersion attachment : attachmentMap.get(saRecord.Id)) {
                            Messaging.Emailfileattachment emailAttachment = new Messaging.Emailfileattachment();
                            emailAttachment.setFileName(attachment.Title);
                            emailAttachment.setBody(attachment.VersionData);
                            fileAttachments.add(emailAttachment);
                        }
                    }
                    mail.setFileAttachments(fileAttachments);
                    mailList.add(mail);
                }
            }
            
            //Send Mail to if list size is not zero
            if ( mailList.size() > 0 ) Messaging.sendEmail(mailList);
        }
    }
}
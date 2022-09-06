public without sharing class TriggerEmailScheduler implements schedulable {
    
    public void execute(SchedulableContext sc) {
        List<ServiceAppointment> triggeredAppointments = [SELECT Id, Status, Email_Trigger__c FROM ServiceAppointment 
                                                          WHERE Status = 'Completed' AND Email_Trigger__c = false];
        for(ServiceAppointment sa :triggeredAppointments) {
            sa.Email_Trigger__c = true;
        }
        update triggeredAppointments;
    }
}
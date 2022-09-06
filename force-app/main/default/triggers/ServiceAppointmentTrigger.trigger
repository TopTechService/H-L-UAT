/*---------------------------------------------------------------------------------------------------------------------------------------------------------------
Description     : Trigger for Opportunity records
Inputs          : "Opportunities" - Opportunityrecords that are being triggered
Handler Classes : OpportunityTriggerHelper
Test Classes    : OpportunityTriggerHelperTest
History:
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
trigger ServiceAppointmentTrigger on ServiceAppointment (after update) {
    
    if(Trigger.isAfter) {
        //Send email to T.S as soon as Service Appointment is closed
        if(Trigger.isUpdate) {
            ServiceAppointmentTriggerHelper.email_send(Trigger.newMap, Trigger.oldMap);
        }
    }
}
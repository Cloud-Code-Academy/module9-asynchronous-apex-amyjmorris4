/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable {

    private Map<Id, Account> accounts;

    public NextStepQueueable(Map<Id, Account> accounts) {
        this.accounts = accounts;
    }

    public static void enqueueJob() {
        List<Account> accountsList = [SELECT Id, Name, Next_Step__c FROM Account WHERE Next_Step__c != NULL LIMIT 10];
        Map<Id, Account> accounts = new Map<Id, Account>(accountsList);

        if (accounts.size() > 0) {
            System.enqueueJob(new NextStepQueueable(accounts));
        }
    }

    public void execute(QueueableContext context) {
        Map<Id, Account> accounts = this.accounts;

        // Convert Map<Id, Account> to List<SObject>
        List<SObject> accountSObjectList = new List<SObject>();
        accountSObjectList.addAll(accounts.values());

        // Remove 'Next Step' from Accounts
        removeNextStepFromAccountsAndOpportunities(accountSObjectList);

        // Update Accounts
        update accounts.values();

        // Query related Opportunities
        List<Opportunity> relatedOpportunities = [SELECT Id, Name, NextStep FROM Opportunity WHERE AccountId IN :accounts.keySet()];

        // Convert List<Opportunity> to List<SObject>
        List<SObject> opportunitySObjectList = new List<SObject>();
        opportunitySObjectList.addAll(relatedOpportunities);

        // Remove 'Next Step' from Opportunities
        removeNextStepFromAccountsAndOpportunities(opportunitySObjectList);

        // Update Opportunities
        update relatedOpportunities;

        // Queue the next job
        enqueueJob();
    }

    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }

    private void removeNextStepFromAccountsAndOpportunities(List<SObject> records) {
        for (SObject record : records) {
            if (record.getSObjectType() == Account.sObjectType) {
                removeNextStep((Account) record);
            } else if (record.getSObjectType() == Opportunity.sObjectType) {
                removeNextStep((Opportunity) record);
            }
        }
    }
}



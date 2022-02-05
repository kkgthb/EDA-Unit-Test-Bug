# EDA unit test bug, 2/5/2022

On 4/3/2021, Ruben Carvalho pointed out that there is a bug in Salesforce's Education Data Architecture _(EDA)_ package through the Trailblazer Communities with a post titled, "[EDA's TDTM still active in Test context even when all triggers disabled](https://trailhead.salesforce.com/en/trailblazer-community/feed/0D54S00000BuHE1SAN)."

## Reproducing the bug

To see this code run, deploy it to a scratch org by following these steps:

1. Install the SFDX and CumulusCI command line tools on your computer; connect the SFDX command line to an org enabled as a "dev hub" and give it an alias like `my-hub-alias`.
2. Download a copy of this repo to your hard drive.
3. Create a folder at the root of the folder where you downloaded this repo called `.sfdx`, and into it, add a `sfdx-config.json` file that specifies an alias like `my-hub-alias` as follows:
    ```json
    {
        "defaultdevhubusername": "`my-hub-alias`"
    }
    ```
4. Spin up the scratch org with `cci flow run dev_org --org dev`.
5. Run `cci task run run_tests --org dev --test_name_match Two_Contacts_w_Uniq_Account_Field_TEST` and watch it fail with the following stack trace:
    ```
    --------------------------------------------------------------------------------
    Failing Tests
    --------------------------------------------------------------------------------
    1: Two_Contacts_w_Uniq_Account_Field_TEST.runTest - Fail
            Message: System.DmlException: Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, hed.TDTM_Contact: execution of AfterInsert  

    caused by: System.DmlException: Insert failed. First exception on row 1; first error: DUPLICATE_VALUE, duplicate value found: <unknown> duplicates value on record with id:   
    <unknown>: []

    Class.hed.ACCT_IndividualAccounts_TDTM.insertContactAccount: line 759, column 1
    Class.hed.ACCT_IndividualAccounts_TDTM.handleInsertProcessing: line 375, column 1
    Class.hed.ACCT_IndividualAccounts_TDTM.handlesAfterInsertUpdate: line 270, column 1
    Class.hed.ACCT_IndividualAccounts_TDTM.run: line 118, column 1
    Class.hed.TDTM_TriggerHandler.runClass: line 145, column 1
    Class.hed.TDTM_TriggerHandler.run: line 75, column 1
    Class.hed.TDTM_Global_API.run: line 61, column 1
    Trigger.hed.TDTM_Contact: line 33, column 1: []
            StackTrace: Class.Two_Contacts_w_Uniq_Account_Field_TEST.runTest: line 8, column 1
    ```
6. Run `cci task run run_tests --org dev --test_name_match Non_Namespaced_Application_TEST` and watch it fail with the following stack trace:
    ```
    --------------------------------------------------------------------------------
    Failing Tests
    --------------------------------------------------------------------------------
    1: Non_Namespaced_Application_TEST.runTest - Fail
            Message: System.DmlException: Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, ApplicationTrigger: execution of
    BeforeInsert

    caused by: System.TypeException: Invalid conversion from runtime type List<Application__c> to List<hed__Application__c>

    Class.hed.Application_TDTM.handleBeforeInsert: line 77, column 1
    Class.hed.Application_TDTM.run: line 57, column 1
    Class.hed.TDTM_TriggerHandler.runClass: line 145, column 1
    Class.hed.TDTM_TriggerHandler.run: line 75, column 1
    Class.hed.TDTM_Global_API.run: line 61, column 1
    Trigger.ApplicationTrigger: line 2, column 1: []
            StackTrace: Class.Non_Namespaced_Application_TEST.runTest: line 10, column 1
    ```

## Bug history

This is consistent with Ruben Carvalho's finding that:

> "We installed EDA in our org and ensured all EDA's triggers on Accounts and Contacts were disabled.
> 
> "We did this by setting `hed__Active__c = false` in all records returned in this query:
> 
> ```sql
> SELECT Id, hed__Object__c, hed__Active__c FROM hed__Trigger_Handler__c WHERE hed__Object__c IN ('Account', 'Contact')
> ```
> 
> However when running our org tests, EDA is still interfering as it runs its triggers on contacts and causes validation rules to fail.  In particular it tries to insert accounts when a contact is inserted.
> 
> ```
> System.DmlException: Insert failed. First exception on row 0; first error:
> CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, hed.TDTM_Contact: execution of AfterInsert caused by: 
> System.DmlException: Update failed. 
> First exception on row 0 with id 0030Q000010htRJQAY; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, 
> ...
> Class.hed.ACCT_IndividualAccounts_TDTM.insertContactAccount: line 699, column 1 
> Class.hed.ACCT_IndividualAccounts_TDTM.handleInsertProcessing: line 329, column 1 
> Class.hed.ACCT_IndividualAccounts_TDTM.handlesAfterInsertUpdate: line 282, column 1 
> Class.hed.ACCT_IndividualAccounts_TDTM.run: line 109, column 1 
> Class.hed.TDTM_TriggerHandler.runClass: line 145, column 1 
> Class.hed.TDTM_TriggerHandler.run: line 75, column 1 
> Class.hed.TDTM_Global_API.run: line 61, column 1 Trigger.hed.TDTM_Contact: line 33, column 1: [] 
> ```
> 
> Adding the following before inserting a contact shows that there are 48 triggers active: 
> 
> ```java
> for (hed.TDTM_Global_API.TdtmToken tdtmToken : hed.TDTM_Global_API.getTdtmConfig()) { System.debug('trigger: ' + tdtmToken); } 
> ```
> 
> The only way to stop this is to inactivate the triggers at the start of every test.
> Why does EDA ship with this enabled by default and how do I change this? Thanks

## Dead ends

Marc Beaulieu from Salesforce replied on May 3, 2021, "This should not be happening after you ran on update on those records to change the value from 'true' to 'false'."

I think Marc missed something important -- records in the "Trigger Handler" table shouldn't even _exist_ in a unit test execution context unless explicitly created!  It actually shouldn't matter if such records are flagged "true" or "false" in the org itself -- they should be nonexistent as far as the unit test engine is concerned.  _(I searched the EDA GitHub repo for the phrase `seealldata` and found no results.)_

## Bug report

So there's some sort of bug in EDA that is making all of the "Trigger Handler" records that normally would be shipped to an org upon installing EDA also end up "shipped to" every single unit test's execution context in an org, which is definitely **not** how Salesforce developers are taught to expect unit test execution contexts to behave.  _(**Data** should never exist in the execution context unless explicitly opted into with `SeeAllData`.)_

I am of the strong opinion that it is **bug**, not "feature", behavior of EDA's codebase to interfere with the normal behavior of unit test execution contexts and force every unit test ever to **opt out** of having a bazillion "default" **Trigger Handler** records exist, rather than having a blank slate of data as is promised by every training ever conducted for developers about the nature of Salesforce unit tests.

This unit test should definitely _not_ surprise developers working in EDA orgs by firing every single trigger handler that comes with EDA when it hits the `INSERT` simply because they didn't know there was a secret thing they had to do to make EDA _not_ secretly insert a bunch of records into the execution context's **Trigger Handler** table behind their backs:

```java
@isTest
public class A_Unit_Test {
    static testMethod void runTest() {
        Contact c1 = new Contact(LastName='C1');
        Contact c2 = new Contact(LastName='C2');
        INSERT new List<Contact>{c1, c2};
    }
}
```

### Aside

I understand that my examples of finding this bug are a little strange:
1. an "Account" custom field that's sensitive to the existence of `BeforeInsert` triggers
2. a package _(EASY)_ that installs a custom object with a name _(`Application__c`)_ that conflicts against the name EDA later chose for a similar concept _(`hed__Application__c`)_

But in my opinion, if someone wants to try to use EASY and EDA together and is willing to simply make sure none of the EDA-delivered "Trigger Handler" records like the one invoking `hed__Application_TDTM` have "**Active**" set to `TRUE`, they should be able to trust that they won't find the `hed__Application_TDTM` Apex class yelling at them during unit tests _(because unit test execution contexts should have an empty "**Trigger Handler**" table and therefore, this class shouldn't ever be invoked)_.

Similarly, if someone wants to create a strange field on Account that works for them and locks them out of ever putting a before-insert trigger on Account, they should be able to do that and not worry about the `hed__ACCT_IndividualAccounts_TDTM` Apex class yelling at them during unit tests _(because unit test execution contexts should have an empty "**Trigger Handler**" table and therefore, this class shouldn't ever be invoked)_.

## Possible bug location

I think that perhaps the EDA codebase might have some sort of utility function _(responsible for doing a bunch of `INSERT`s into the **Trigger Handler** table)_ to help make it easier to write unit tests within EDA ... but but that the utility function accidentally got invoked from **actual** TDTM code instead of only from EDA's unit tests' test setup?

That might be responsible for _all_ unit tests somehow having a bunch of records exist in **Trigger Handler** when the table should **normally** be empty **unless** a developer **explicitly** tries to **opt into** filling **Trigger Handler** with "EDA defaults."

Perhaps it's this part of [TDTM_Config](https://github.com/SalesforceFoundation/EDA/blob/main/force-app/main/tdtm/classes/TDTM_Config.cls)?

```java
// Getting the default configuration only if there is no data in the Trigger Handler object. Otherwise
// we would delete customizations and Trigger Handlers entries that aren't in the default configuration.
if(tdtmConfig.size() == 0) {
    tdtmConfig = TDTM_DefaultConfig.getDefaultRecords();
}
```

## Thank you!

Could this bug please be fixed so that TDTM trigger handlers as shipped by EDA won't exist unless explicitly added by a unit test?

Thanks so much!
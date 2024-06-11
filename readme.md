### Daily E2E Test

Welcome to our Daily E2E Test automated service! This service conducts daily end-to-end tests. Additionally, it operates an application to collect logs from a PVC to the logs folder. It checks if files in the folder have identical names but different dates, puts the results in a database, and sends a message in Slack with the test name, result, cause of failure (if any), and the scenario.

#### How It Works

1. **Sequential Testing**: 
   - Our service performs daily end-to-end tests sequentially. Each test starts only after the previous one has completed, ensuring smooth transitions.

2. **HELM Configuration**: 
   - The HELM chart is tailored for each test, with specific global variable values set on the values page.

3. **CRONJOB Schedule**: 
   - The schedule for all tests is defined on the values page under the `schedule` key.

4. **BASH Command Execution**: 
   - BASH commands ensure each test waits for the previous one to finish before starting.

#### Adding a New Test

To add a new test to the sequence, follow these steps:

1. **Copy Previous CRONJOB**: 
   - Duplicate an existing CRONJOB and update the `metadata:name`.

2. **Modify initContainers**: 
   - Change the name of the `initContainers` to reflect the new test.

3. **Update CRONJOB_PREFIX**: 
   - Set the `CRONJOB_PREFIX` variable to the name of the preceding test.

4. **Add Global Variables**: 
   - On the values page, add a new section for the new test with its specific global variables. Update these variables as needed from the job you copied.

5. **Maintain Chain Integrity**: 
   - Ensure the collect-logs job remains the last step. Verify that the new test fits seamlessly between the previous and next tests.

By following these guidelines, you can easily manage and expand the chain of automated tests, ensuring efficient and orderly execution. Happy testing!
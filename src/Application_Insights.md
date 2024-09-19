# Configuring Application Insights for Workflow Service

> **Note:** These instructions are for setting up Application Insights using the _Workflow Service_ as an example.

## Prerequisite

1. Download the Application Insights Java Agent (Version 3.5.2) from the [official release page](https://github.com/microsoft/ApplicationInsights-Java/releases/tag/3.5.2) to a known location.

   _In this solution, the Application Insights Java Agent has already been downloaded and is available in the current directory as `applicationinsights-agent-3.5.2.jar`._

2. Note your Azure Application Insights Instrumentation Key.

## Configuration Options

### Option 1: Command Line (Linux/macOS)

1. Set the environment variable:
   ```bash
   export APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=<your_instrumentation_key>"
   ```

2. Run your Java application:
   ```bash
   # Using Java command
   java -javaagent:/path/to/applicationinsights-agent-3.5.2.jar \
        -DAPPINSIGHTS_LOGGING_ENABLED=true \
        -cp your-classpath org.opengroup.osdu.workflow.provider.azure.WorkflowAzureApplication

   # Using Maven command
   mvn spring-boot:run -pl "$project_name" \
       -Dspring-boot.run.jvmArguments="-javaagent:/path/to/applicationinsights-agent-3.5.2.jar -DAPPINSIGHTS_LOGGING_ENABLED=true"
   ```
   Replace `/path/to/applicationinsights-agent-3.5.2.jar`, `your-classpath`, `$project_name`, and the main class as needed.

### Option 2: IntelliJ Configuration

1. Go to **Run > Edit Configurations**.
2. Select your application configuration (e.g., `WorkflowAzureApplication`).
3. In **VM Options**, add:
   ```
   -javaagent:/path/to/applicationinsights-agent-3.5.2.jar
   -DAPPINSIGHTS_LOGGING_ENABLED=true
   ```
4. In **Environment Variables**, add:
   - **Key**: `APPLICATIONINSIGHTS_CONNECTION_STRING`
   - **Value**: `InstrumentationKey=<your_instrumentation_key>`
5. Save and run the configuration.

### Option 3: VS Code Configuration

1. Create or edit `.vscode/launch.json`.
2. Add the following configuration:

   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "type": "java",
         "name": "Launch WorkflowAzureApplication",
         "request": "launch",
         "mainClass": "org.opengroup.osdu.workflow.provider.azure.WorkflowAzureApplication",
         "vmArgs": "-javaagent:/path/to/applicationinsights-agent-3.5.2.jar -DAPPINSIGHTS_LOGGING_ENABLED=true",
         "env": {
           "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=<your_instrumentation_key>"
         }
       }
     ]
   }
   ```

3. Replace `/path/to/applicationinsights-agent-3.5.2.jar` and `<your_instrumentation_key>` with actual values.
4. Save the file and press F5 to run the application.
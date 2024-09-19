# Configuring Application Insights for Running Services Locally

OSDU has modified how Application Insights functions within its ecosystem. While these modifications are primarily on the server side, there is a specific requirement for local development:

When running OSDU services locally, you must ensure that the standard Application Insights Java agent JAR file is available and configured as a java virtual machine argument.

Note: If the Application Insights JAR file is not properly configured or available, you may encounter the following exception:

   ```
   Cannot invoke \"com.microsoft.applicationinsights.web.internal.RequestTelemetryContext.getHttpRequestTelemetry()\" because the return value of \"com.microsoft.applicationinsights.web.internal.ThreadContext.getRequestTelemetryContext()\" is null
   ```

## Prerequisite

1. Download the Application Insights Java Agent (Version 3.5.4) from the [official release page](https://github.com/microsoft/ApplicationInsights-Java/releases/tag/3.5.4) to a known location.


## Configuration Options

### Option 1: Command Line

1. Set the environment variable:
   ```bash
   export APPINSIGHTS_LOGGING_ENABLED="true"
   export APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=<your_instrumentation_key>"
   ```

2. Run your Java application:
   ```bash
   # Using Maven command
   mvn spring-boot:run -pl "$project_name" \
       -Dspring-boot.run.jvmArguments="-javaagent:/path/to/applicationinsights-agent.jar -DAPPINSIGHTS_LOGGING_ENABLED=true"
   ```
   Replace `/path/to/applicationinsights-agent.jar`, and the `$project_name` as needed.

### Option 2: IntelliJ Configuration

1. Go to **Run > Edit Configurations**.
2. Select your application configuration
3. In **VM Options**, add:
   ```
   -javaagent:/path/to/applicationinsights-agent.jar -DAPPINSIGHTS_LOGGING_ENABLED=true
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
         "mainClass": "org.opengroup.osdu.<your_project_name>",
         "vmArgs": "-javaagent:/path/to/applicationinsights-agent.jar -DAPPINSIGHTS_LOGGING_ENABLED=true",
         "env": {
           "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=<your_instrumentation_key>"
         }
       }
     ]
   }
   ```

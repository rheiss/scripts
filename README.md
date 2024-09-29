# JMeter Smoke Test Script

This is a Bash script to run JMeter smoke tests in non-GUI mode, store results, and upload the results to an AWS S3 bucket. The script supports optional cleanup of old results and generates a simple status HTML page to track test history. 

## Features
- Runs JMeter tests in non-GUI mode.
- Creates a timestamped results directory for each test run.
- Cleans up results older than 30 days.
- Generates an HTML status page with test results.
- Uploads results to an S3 bucket.
- Provides clear output in the terminal for debugging and tracking the test's success or failure.

## Prerequisites
- [JMeter](https://jmeter.apache.org/download_jmeter.cgi) installed and available in the system's PATH.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured with the necessary permissions to access the specified S3 bucket.
- A valid JMeter test plan file (`.jmx`).
- Access to an AWS S3 bucket for uploading test results.

## Usage

```bash
./run_jmeter_test.sh -t <test-plan> -b <s3-bucket> [-d <results-dir>]
```
### Output
- **Results Directory**: A directory (default: `results`) containing timestamped `.jtl` and log files for each test run.
- **HTML Status Page**: A `status.html` file that displays the test history with buttons to show logs and results.
- **S3 Uploads**: The script uploads the `status.html`, the JMeter log file, and the results file to the specified S3 bucket.

### Notes
- The script checks for failures in the results file and exits with a failure code if any are found.
- Results older than 30 days are automatically deleted to save space.
- The script generates a new status page if one does not already exist.
- Customize the HTML and JavaScript within the script for your needs (e.g., to add custom styles).

### Requirements
- **JMeter**: Ensure JMeter is installed and accessible from the command line.
- **AWS CLI**: Install and configure the AWS CLI with the necessary permissions to upload files to the S3 bucket.
- **Permissions**: Make sure the script has execute permissions:

    ```bash
    chmod +x run_jmeter_test.sh
    ```

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

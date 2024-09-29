#!/bin/bash

# Usage: ./run_jmeter_test.sh -t <test-plan> -b <s3-bucket> [-d <results-dir>]
# Example: ./run_jmeter_test.sh -t conf/test-plan.jmx -b my-s3-bucket

# Default values
RESULTS_DIR="results"

# Function to display usage
usage() {
    echo "Usage: $0 -t <test-plan> -b <s3-bucket> [-d <results-dir>]"
    echo "  -t    Path to the JMeter test plan (.jmx file)"
    echo "  -b    S3 bucket name for uploading the results"
    echo "  -d    Directory to store results (default: results)"
    exit 1
}

# Parse command-line arguments
while getopts ":t:b:d:" opt; do
    case $opt in
        t) TEST_PLAN="$OPTARG" ;;
        b) S3_BUCKET="$OPTARG" ;;
        d) RESULTS_DIR="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if required arguments are provided
if [ -z "$TEST_PLAN" ] || [ -z "$S3_BUCKET" ]; then
    usage
fi

# Generate a unique timestamp for each run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="$RESULTS_DIR/results_$TIMESTAMP.jtl"
LOG_FILE="$RESULTS_DIR/jmeter_$TIMESTAMP.log"
STATUS_PAGE="status.html"
TEMP_RESULTS="temp_results.html"
TEMP_PAGE="temp_status.html"

# Create the results directory if it doesn't exist
if [ ! -d "$RESULTS_DIR" ]; then
    echo "Creating results directory: $RESULTS_DIR"
    mkdir -p "$RESULTS_DIR"
fi

# Remove results older than 30 days
echo "Cleaning up results older than 30 days in $RESULTS_DIR"
find "$RESULTS_DIR" -type f -mtime +30 -exec rm {} \;

# Run JMeter in non-GUI mode
echo "Running JMeter with test plan: $TEST_PLAN"
jmeter -n -t "$TEST_PLAN" -l "$RESULTS_FILE" -j "$LOG_FILE"

# Create a temporary HTML file to hold the current test results
echo "Creating temporary results file: $TEMP_RESULTS"
echo "<div class='test-result'>" > "$TEMP_RESULTS"
echo "<h2>Smoke Test Run: $(date)</h2>" >> "$TEMP_RESULTS"

# Add a button and a hidden div for displaying the JMeter log file
echo "<button onclick='toggleLog(\"log_$TIMESTAMP\")'>Show JMeter Log</button>" >> "$TEMP_RESULTS"
echo "<pre id='log_$TIMESTAMP' style='display:none; background-color: #f4f4f4; padding: 10px; border: 1px solid #ccc; max-height: 300px; overflow-y: scroll;'>" >> "$TEMP_RESULTS"
cat "$LOG_FILE" >> "$TEMP_RESULTS"
echo "</pre>" >> "$TEMP_RESULTS"

# Add a button and a hidden div for displaying the results.jtl file
echo "<button onclick='toggleLog(\"results_$TIMESTAMP\")'>Show Results File</button>" >> "$TEMP_RESULTS"
echo "<pre id='results_$TIMESTAMP' style='display:none; background-color: #f4f4f4; padding: 10px; border: 1px solid #ccc; max-height: 300px; overflow-y: scroll;'>" >> "$TEMP_RESULTS"
cat "$RESULTS_FILE" >> "$TEMP_RESULTS"
echo "</pre>" >> "$TEMP_RESULTS"

# Check for success or failure based on the 'success' column
echo "Checking for failures in the results file..."
if grep -q ",false," "$RESULTS_FILE"; then
    echo "Failures detected in the test results."
    echo "<p class='status failure'>Smoke test failed!</p>" >> "$TEMP_RESULTS"
    echo "<h3>Failed URLs Grouped by Status Code:</h3>" >> "$TEMP_RESULTS"

    # Extract failed URLs and group by status code
    tail -n +2 "$RESULTS_FILE" | awk -F',' '$8 == "false" {print $4, $14}' | sort | while read -r status url; do
        if [[ $prev_status != "$status" ]]; then
            if [[ -n $prev_status ]]; then
                echo "</ul>" >> "$TEMP_RESULTS"
            fi
            echo "<h4>Status Code: $status</h4><ul>" >> "$TEMP_RESULTS"
            prev_status=$status
        fi
        echo "<li><a href='$url' target='_blank'>$url</a></li>" >> "$TEMP_RESULTS"
    done

    if [[ -n $prev_status ]]; then
        echo "</ul>" >> "$TEMP_RESULTS"
    fi
else
    echo "No failures detected. Smoke test passed."
    echo "<p class='status success'>Smoke test passed!</p>" >> "$TEMP_RESULTS"
fi

# Close the current test results div
echo "</div>" >> "$TEMP_RESULTS"

# Check if the status page already exists, create a new one if not
if [ ! -f "$STATUS_PAGE" ]; then
    echo "Status page does not exist. Creating a new status page: $STATUS_PAGE"
    echo "<html><head><title>Smoke Test Status</title>" > "$STATUS_PAGE"
    # Add CSS styles and JavaScript (omitted here for brevity)
    echo "</head><body>" >> "$STATUS_PAGE"
    echo "<h1>Smoke Test History</h1>" >> "$STATUS_PAGE"
fi

# Concatenate the latest results at the top of the existing status page
echo "Updating the status page with the latest results."
cat "$TEMP_RESULTS" "$STATUS_PAGE" > "$TEMP_PAGE"
mv "$TEMP_PAGE" "$STATUS_PAGE"

# Publish to S3
echo "Uploading results to S3 bucket: $S3_BUCKET"
aws s3 cp "$STATUS_PAGE" "s3://$S3_BUCKET/status.html" --acl public-read
aws s3 cp "$RESULTS_FILE" "s3://$S3_BUCKET/$RESULTS_FILE" --acl public-read
aws s3 cp "$LOG_FILE" "s3://$S3_BUCKET/$LOG_FILE" --acl public-read

# Exit with an error code if the test failed
echo "Final success check in results file..."
if grep -q ",false," "$RESULTS_FILE"; then
    echo "Failures found in test results. Exiting with failure."
    exit 1
else
    echo "No failures found. Exiting with success."
fi

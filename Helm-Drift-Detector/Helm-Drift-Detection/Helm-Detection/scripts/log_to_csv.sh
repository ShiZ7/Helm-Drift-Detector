Logs to Csv Script

#!/bin/bash

DRIFT_OUTPUT_FILE="${1:-drift.1og}"
CSV_OUTPUT_FILE="${2:-drift_history.csv}"

# Initialize CSV if 1t doesn't exist

if [ ! -f "$CSV_OUTPUT_FILE" ]; then
echo "Timestamp, Resource, Field, Local, Live" > "$CSV_OUTPUT_FILE" 
fi

# Extract DRIFI Lines trom log and convert to Csv

grep "DRIFT:" "$DRIFT_OUTPUT_FILE" | while IFS= read -r line; do 

  field=$(echo "Sline" | cut -d ':' -f2 | cut -d '(' -f1 | xargs) 
  values=slecho "Sline" | grep -op '(Local=,*?, Live=,*?\' | sed "s/l()J//g")
  
  local_val=$(echo "$values" | sed -n 's/Local=\(.*\), Live=.*/\1/p')
  live_val=$(echo "$values" | sed -n 's/.*Live=\(.*\)/\1/p') 
  
  echo "$(date), HPA/$field, $field, $local_val, $live_val" >> "$CSV_OUTPUT_FILE"
done

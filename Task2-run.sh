#!/bin/bash
set -e
rm -f centroids.txt centroids_new.txt Task2_output.txt 2>/dev/null
hdfs dfs -rm -r /Output/Task2* 2>/dev/null || true

[ -f initialization.txt ] || { echo "ERROR: initialization.txt missing"; exit 1; }
[ -f Task2-mapper.py ] || { echo "ERROR: mapper.py missing"; exit 1; }
[ -f Task2-reducer.py ] || { echo "ERROR: reducer.py missing"; exit 1; }
[ -f Task2-reader.py ] || { echo "ERROR: Task2-reader.py missing"; exit 1; }
[ -f hadoop-streaming-3.1.4.jar ] || { echo "ERROR: hadoop-streaming-3.1.4.jar missing"; exit 1; }

v=$(head -n 1 initialization.txt)
k=0
medoids=()
while IFS= read -r line; do
    if [[ $line =~ ^[-0-9.]+[[:space:]]+[-0-9.]+$ ]]; then
        medoids+=("$line")
        ((k++))
    fi
done < <(tail -n +2 initialization.txt)

echo "Running PAM algorithm with k=$k and v=$v"

# Create initial centroids file
> centroids.txt
for i in "${!medoids[@]}"; do
    echo -e "$i\t${medoids[$i]}" >> centroids.txt
done

# Run iterations
iter=1
converged=0

while [ $iter -le $v ]; do
    echo "=== Iteration $iter ==="
    echo "Current medoids:"
    cat centroids.txt
    
    # Remove previous output
    hdfs dfs -rm -r /Output/Task2 2>/dev/null || true
    
    # Run MapReduce job with 3 reducers
    hadoop jar hadoop-streaming-3.1.4.jar \
        -D mapred.reduce.tasks=3 \
        -D stream.num.map.output.key.fields=1 \
        -files centroids.txt,Task2-mapper.py,Task2-reducer.py \
        -mapper "python3 Task2-mapper.py" \
        -reducer "python3 Task2-reducer.py" \
        -input /Input/Trips.txt \
        -output /Output/Task2 \
        -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner
    
    # Get new medoids
    hdfs dfs -getmerge /Output/Task2/part* centroids_new.txt 2>/dev/null
    
    # Sort by medoid index and extract only coordinates
    sort -n centroids_new.txt | cut -f2-3 > centroids_sorted.txt
    mv centroids_sorted.txt centroids_new.txt
    
    # Check for convergence
    if [ $iter -gt 1 ]; then
        if python3 Task2-reader.py centroids_prev.txt centroids_new.txt; then
            echo "Convergence reached after $iter iterations!"
            converged=1
            break
        fi
    fi
    
    # Update centroids for next iteration
    cp centroids_new.txt centroids_prev.txt
    > centroids.txt
    idx=0
    while IFS= read -r line; do
        echo -e "$idx\t$line" >> centroids.txt
        ((idx++))
    done < centroids_new.txt
    
    iter=$((iter + 1))
done

# Final output
if [ $converged -eq 0 ]; then
    echo "Reached maximum iterations ($v) without convergence"
fi

# Create final output file
hdfs dfs -getmerge /Output/Task2/part* Task2_output.txt 2>/dev/null
# Extract only coordinates and format with a TAB between x and y (no sorting)
> final_output.txt
while IFS= read -r line; do
    # robustly take the last two fields as x and y, and print with a tab
    echo "$line" | awk 'NF>=2 { printf "%s\t%s\n", $(NF-1), $NF }' >> final_output.txt
done < Task2_output.txt

head -n $k final_output.txt > Task2_output.txt
rm -f final_output.txt

echo "Final medoids:"
cat Task2_output.txt

# Cleanup
rm -f centroids.txt centroids_new.txt centroids_prev.txt 2>/dev/null

echo "Task 2 completed successfully!"
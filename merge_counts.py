import os
import glob
import pandas as pd
import time

# Fixed paths
input_path = "/home/sanchan_chandrasheka/bulkrnaseq_analysis/quants"
output_path = "/home/sanchan_chandrasheka/bulkrnaseq_analysis/countsmatrix"

# Create output folder if it doesn't exist
os.makedirs(output_path, exist_ok=True)

# Get all .txt featureCounts files
files = glob.glob(os.path.join(input_path, "*.txt"))

if not files:
    print("No .txt files found in the input folder.")
    exit()

print("Files found:", files)

all_counts = []

for file in files:
    start_time = time.time()
    df = pd.read_csv(file, sep="\t", comment="#")

    # Extract sample name from filename
    sample_name = os.path.basename(file).replace("_featurecounts.txt", "")
    df = df[["Geneid", df.columns[-1]]]
    df.rename(columns={df.columns[-1]: sample_name}, inplace=True)

    all_counts.append(df)

    elapsed = (time.time() - start_time) / 60  # minutes
    print(f"Completed {sample_name} | Rows: {df.shape[0]} | Time: {elapsed:.2f} min")

# Merge all dataframes on 'Geneid'
counts_matrix = all_counts[0]
for df in all_counts[1:]:
    counts_matrix = counts_matrix.merge(df, on="Geneid", how="outer")

# Save merged matrix
output_file = os.path.join(output_path, "merged_counts_matrix.csv")
counts_matrix.to_csv(output_file, index=False)

print("\nAll files processed!")
print("Merged matrix shape:", counts_matrix.shape)
print("Saved to:", output_file)

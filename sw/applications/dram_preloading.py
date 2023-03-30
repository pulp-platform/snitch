import pandas as pd 
import argparse
import os

# the input file is a CSV file with the following format:
# label, [feature1, feature2, ...]

# get arguments from command line
parser = argparse.ArgumentParser()
parser.add_argument('--data-csv', type=str, required=True, help='path to the CSV file containing the data')
parser.add_argument('--num-rows', type=int, required=False, help='number of rows to read from the CSV file')
parser.add_argument('--scaled', type=bool, required=False, help='whether the data should be scaled or not')
parser.add_argument('--dtype', type=str, required=True, help='data type of the features (in numpy format)')
parser.add_argument('--display', type=bool, required=False, help='whether to display the data or not')
parser.add_argument('--output-dir', type=str, required=True, help='path to the output directory with / at the end')


args = parser.parse_args()

print('Writing {} rows from file {} to binary files at {}'.format(args.num_rows, args.data_csv, args.output_dir))

# read the data
data_df = pd.read_csv(args.data_csv)

if args.num_rows is not None:
    data_df = data_df[:args.num_rows]

# separate the data into two dataframes with labels and features
labels_df = data_df['label']
features_df = data_df.drop('label', axis=1)

    
if args.scaled:
    # scale the data
    features_df = features_df.div(255).astype(args.dtype)

# display the data to terminal
if args.display:
    print("labels_df: {}".format(labels_df))
    print("features_df: {}".format(features_df))

# if output directory does not exist, create it
if not os.path.exists(args.output_dir):
    os.makedirs(args.output_dir)


# get the data type of the features and labels
feature_type = str(type(features_df.iloc[0][0])).split(".")[-1].split("'")[0]
label_type = str(type(int(labels_df.iloc[0]))).split("<")[-1].split(">")[0].split("class")[-1].replace("'", "").strip()

if args.display:
    print("feature_type: {}".format(feature_type))
    print("label_type: {}".format(label_type))

# write the feature data into a binary file

for row in features_df.values:
    bin_row = bytearray(row)
    f = open(args.output_dir + str(args.num_rows) + "_features_" + str(feature_type) + ".bin", "ab")
    f.write(bin_row)
    f.close()


# write the label data into a binary file
for row in labels_df.values:
    bin_row = int(row).to_bytes(8, byteorder='little')
    f = open(args.output_dir + str(args.num_rows) + "_labels_" + str(label_type) + ".bin", "ab")
    f.write(bin_row)
    f.close()


print("Wrote {} rows of features to binary file {}_features_{}.bin".format(args.num_rows, args.num_rows, feature_type))
print("Wrote {} rows of labels to binary file {}_labels_{}.bin".format(args.num_rows, args.num_rows, label_type))


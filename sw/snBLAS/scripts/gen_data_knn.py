#!/usr/bin/env python3

# Copied from:
# https://towardsdatascience.com/machine-learning-basics-with-the-k-nearest-neighbors-algorithm-6a6e71d01761

from collections import Counter
import math
import numpy as np


def pseudo_rand_matrix(N, M, seed):
    return np.arange(seed, seed+N*M, dtype=np.float64).reshape(M, N).transpose() * 3.141


def knn(data, query, k, distance_fn, choice_fn):
    neighbor_distances_and_indices = []
    # print(data)
    # 3. For each example in the data
    for index, example in enumerate(data):
        # 3.1 Calculate the distance between the query example and the current
        # example from the data.
        distance = distance_fn(example[:-1], query)

        # 3.2 Add the distance and the index of the example to an ordered collection
        neighbor_distances_and_indices.append((distance, index))

    # 4. Sort the ordered collection of distances and indices from
    # smallest to largest (in ascending order) by the distances
    sorted_neighbor_distances_and_indices = sorted(neighbor_distances_and_indices)

    # 5. Pick the first K entries from the sorted collection
    k_nearest_distances_and_indices = sorted_neighbor_distances_and_indices[:k]

    # 6. Get the labels of the selected K entries
    k_nearest_labels = [data[i][1] for distance, i in k_nearest_distances_and_indices]
    # print(f'k_nearest_distances_and_indices: {k_nearest_distances_and_indices}')
    # print(f'k_nearest_labels: {k_nearest_labels}')
    # print(f'choice_fn(k_nearest_labels): {choice_fn(k_nearest_labels)}')

    # 7. If regression (choice_fn = mean), return the average of the K labels
    # 8. If classification (choice_fn = mode), return the mode of the K labels
    return k_nearest_distances_and_indices, choice_fn(k_nearest_labels)


def mean(labels):
    return sum(labels) / len(labels)


def mode(labels):
    return Counter(labels).most_common(1)[0][0]


def euclidean_distance(point1, point2):
    sum_squared_distance = 0
    for i in range(len(point1)):
        sum_squared_distance += math.pow(point1[i] - point2[i], 2)
        # print(point1[i], point2[i])
    # print("Result:", sum_squared_distance)
    return sum_squared_distance


def array_to_cstr(a):
    out = '{'
    if isinstance(a, np.ndarray):
        a = a.flat
    for el in a:
        out += '{}, '.format(el)
    out = out[:-2] + '}'
    return out


def emit(name, array, pfx=""):
    if isinstance(array, int):
        print(f'static uint32_t {pfx}{name} = {array};')
        return
    out = 'static '
    if array.dtype == np.uint32:
        out += 'uint32_t'
    elif array.dtype == np.float64:
        out += 'double'
    else:
        exit(-1)

    out += f' {pfx}{name}[{array.size}] = {array_to_cstr(array)};'
    print(out)


N = 100
k = 3
nr_samples = 24

name_prefix = f"knn_k{k}_N{N}_nrs{nr_samples}_"

emit("input_size", N, pfx=name_prefix)
emit("k_size", k, pfx=name_prefix)
emit("nr_samples", nr_samples, pfx=name_prefix)

reg_data = pseudo_rand_matrix(N, 2, 1)
np.random.seed(seed=1)
samples = np.random.uniform(0, reg_data[-1][-1], nr_samples)
emit("samples", np.array(samples, dtype=np.float64), pfx=name_prefix)

# print('samples')
# print(samples)
# print('reg_data')
# print(reg_data)

results = []
for sample in samples:
    reg_k_nearest_neighbors, reg_prediction = knn(
        reg_data, [sample], k=k, distance_fn=euclidean_distance, choice_fn=mode
    )
    results.append(reg_prediction)

emit("output_checksum", np.array(results, dtype=np.float64), pfx=name_prefix)

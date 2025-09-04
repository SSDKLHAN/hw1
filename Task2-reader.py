#!/usr/bin/env python
"""Task2-reader.py"""

import sys
from math import sqrt

def getCentroids(filepath):
    centroids = []
    with open(filepath) as fp:
        line = fp.readline()
        while line:
            if line.strip():
                try:
                    line = line.strip()
                    parts = line.split('\t')
                    if len(parts) >= 2:
                        cord = parts[1].split(',')
                        centroids.append([float(cord[0]), float(cord[1])])
                except:
                    pass
            line = fp.readline()
    return centroids

def checkCentroidsDistance(centroids, centroids1):
    if len(centroids) != len(centroids1):
        return False
    
    for i in range(len(centroids)):
        dist = sqrt(pow(centroids[i][0] - centroids1[i][0], 2) + pow(centroids[i][1] - centroids1[i][1], 2))
        if dist >= 1.0:
            return False
    return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("0")
        sys.exit(1)
    
    try:
        centroids = getCentroids(sys.argv[1])
        centroids1 = getCentroids(sys.argv[2])
        
        if checkCentroidsDistance(centroids, centroids1):
            print("1")
        else:
            print("0")
    except:
        print("0")
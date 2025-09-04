#!/usr/bin/env python3
import sys, math

# Extract last two numeric tokens (accepts commas or whitespace between x and y)
def parse_xy(s: str):
    vals = []
    for t in s.replace(",", " ").split():
        try:
            vals.append(float(t))
        except:
            pass
    return (vals[-2], vals[-1]) if len(vals) >= 2 else None

# Build clusters: key=int(cluster_id) -> list[(x,y)]
clusters = {}
for line in sys.stdin:
    line = line.strip()
    if not line or "\t" not in line:
        continue
    k_str, v = line.split("\t", 1)
    try:
        k = int(k_str)
        xy = parse_xy(v)
        if xy is None:
            continue
        clusters.setdefault(k, []).append(xy)
    except:
        continue

# For each cluster, choose medoid: point minimizing sum of Euclidean distances
for idx in sorted(clusters):
    pts = clusters[idx]
    if not pts:
        continue
    def total_dist(c):
        return sum(math.hypot(c[0]-p[0], c[1]-p[1]) for p in pts)
    best = min(pts, key=lambda c: (total_dist(c), c))  # tie-break by coords
    print(f"{best[0]}\t{best[1]}")
#!/usr/bin/env python3
import sys, os, math

def read_medoids():
    def load(path, skip_first=False):
        if not os.path.exists(path):
            return []
        out = []
        with open(path) as f:
            for i, line in enumerate(f):
                if skip_first and i == 0: \
                    continue
                p = line.replace(',', ' ').split()
                if len(p) >= 2:
                    try:
                        out.append((float(p[0]), float(p[1])))
                    except: \
                        pass
        return out
    m = load('current_medoids.txt')
    return m if m else load('initialization.txt', skip_first=True)

def parse_xy(s):
    t = s.replace(',', ' ').split()
    nums = []
    for v in t:
        try: nums.append(float(v))
        except: pass
    if len(nums) < 2:
        raise ValueError
    return nums[-2], nums[-1]

def main():
    med = read_medoids()
    if not med:
        sys.exit(1)
    for line in sys.stdin:
        line = line.strip()
        if not line: \
            continue
        try:
            x, y = parse_xy(line)
        except: \
            continue
        bx, bd = -1, float('inf')
        for i, (mx, my) in enumerate(med):
            d = (x-mx)*(x-mx) + (y-my)*(y-my)
            if d < bd:
                bd, bx = d, i
        print(f"{bx}\t{x} {y}")

if __name__ == '__main__':
    main()
#!/usr/bin/python3

import sys

def remove_adjacent_dups(fname):
    with open(fname, 'r') as f:
        for line in f:
            lists = line.strip().split()
            uttid = lists.pop(0)
            result = []
            most_recent_elem = None
            for elem in lists:
                if elem != most_recent_elem:
                    result.append(elem)
                    most_recent_elem = elem
            to_string = ' '.join(result)
            print(uttid + ' ' + to_string)


if __name__ == "__main__":
    fname = sys.argv[1]
    remove_adjacent_dups(fname)


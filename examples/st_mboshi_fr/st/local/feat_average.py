#! /usr/bin/python3

'''This scripts take input MFCC features (format: npz) and a text file with aligned phone sequences,
it averages the feature vectors that spread over the same phones.
'''
import sys
import argparse
import numpy as np

def rename_feat(feat_file):
    feat = dict(np.load(feat_file))
    dict_feat = {}
    for key in feat:
        l = key.split('_')
        l.pop(0)
        new_key = '_'.join(l)
        dict_feat[new_key] = feat[key]
    return dict_feat

def load_align_file(align_file_name, rename=False):
    dict_align = {}
    utt_list = []
    with open(align_file_name, 'r') as fp:
        for line in fp:
            line = line.strip()
            tokens = line.split()
            uttid = tokens.pop(0)
            if rename:
                l = uttid.split('_')
                l.pop(0)
                uttid = '_'.join(l)
            utt_list.append(uttid)
            dict_align[uttid] = tokens
    return dict_align, utt_list

def average_feats(feat, align, align_utt_list, aligned_feats_file):
    '''
    feat(dictionary): key is uttid, value is MFCC vectors.
    align(dictioary): key is uttid, value is a list of unit sequence.
    '''
    savez_dict = {}
    for uttid in align_utt_list: 
        utt = align[uttid]
        if not uttid in feat:
            print(f'Warning: uttterance {uttid} in the alignments has no corresponding MFCC features')
            continue
            #sys.exit(1)
        vecs = feat[uttid]
        if len(vecs) != len(utt):
            print(f'Warning: number of frames in MFCC is not equal to number of units for utterance {uttid}: {len(vecs)} vs {len(utt)} ')
            #sys.exit(1)
        most_recent_token = utt[0]
        most_recent_vec_sum = np.zeros(vecs[0].shape)
        count = 0
        new_vecs = []
        for i, token in enumerate(utt):
            if token == most_recent_token:
                most_recent_vec_sum += vecs[i]
                count += 1
            else:
                new_vecs.append(most_recent_vec_sum/count)
                most_recent_token = token
                most_recent_vec_sum = vecs[i]
                count = 1
        new_vecs.append(most_recent_vec_sum/count)
        savez_dict[uttid] = np.array(new_vecs)
    np.savez(aligned_feats_file, **savez_dict)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Average MFCC vectors based on phone alignments')
    parser.add_argument('feat_file', type=str, help='Input MFCC file name')
    parser.add_argument('align_file', type=str, help='Input alignment file')
    parser.add_argument('aligned_feats_file', type=str, help='Output averaged MFCC file name')
    parser.add_argument('--rename_align', action='store_true', default=False)
    parser.add_argument('--rename_feats', action='store_true')
    args = parser.parse_args()
    feat_file = args.feat_file
    align_file = args.align_file
    aligned_feats_file = args.aligned_feats_file
    align, align_utt_list = load_align_file(align_file, rename=args.rename_align)
    if args.rename_feats:
        feat = rename_feat(feat_file)
    average_feats(feat, align, align_utt_list, aligned_feats_file)



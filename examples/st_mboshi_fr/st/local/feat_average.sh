#!/bin/bash

mfccdir="/export/b03/jyang/espresso/examples/st_mboshi_fr/st/data_prepared/ondel/mfcc"
aud_dir="/export/b03/jyang/espresso/examples/st_mboshi_fr/mt/data/mboshi-fr"
aligned_mfcc_dir="/export/b03/jyang/espresso/examples/st_mboshi_fr/mt/data/mboshi-fr"

for d in train dev; do
    [ ! -d $aligned_mfcc_dir/$d ] && mkdir -p $aligned_mfcc_dir/$d
    python local/feat_average.py --rename_feats \
    $mfccdir/train/mboshi_mfcc_train.npz \
    $aud_dir/$d/aud_ali.mb.txt $aligned_mfcc_dir/$d/mfcc_aud_avrg.npz 
done

[ ! -d $aligned_mfcc_dir/test ] && mkdir -p $aligned_mfcc_dir/test
python local/feat_average.py --rename_feats --rename_align \
    $mfccdir/dev/mboshi_mfcc_dev.npz \
    $aud_dir/test/aud_ali.mb.txt $aligned_mfcc_dir/test/mfcc_aud_avrg.npz 


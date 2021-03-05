#!/bin/bash

# This scripts randomly select $n utterances from the given input datadir, and create a subset from the
# given input datadir, based on the selection.

num_select=200

if [ $# -ne 3 ]; then
    echo "Usage: $0 [ --num-select 200 ] <data-dir> <subset-select> <subset-rest>"
    exit 1;
fi

. path.sh
. parse_options.sh

datadir=$1
subset_select=$2
subset_rest=$3

mkdir -p $subset_select || exit 1;
mkdir -p $subset_rest || exit 1;

# Randomly select $num_select utterances
cat $datadir/uttids | utils/shuffle_list.pl --srand 777 | head -n $num_select > $subset_select/uttids || exit 1;
diff <(sort $datadir/uttids) <(sort $subset_select/uttids) | grep "<" | cut -d " " -f2- > $subset_rest/uttids

# Create subsets
for f in ali.mb.txt trans.wrd.mb.txt trans.wrd.fr.txt uttids_speakers wav.scp
do
    utils/filter_scp.pl $subset_select/uttids $datadir/$f | sort > $subset_select/$f
    utils/filter_scp.pl $subset_rest/uttids $datadir/$f | sort > $subset_rest/$f
done

utils/utt2spk_to_spk2utt.pl $datadir/uttids_speakers | sort > $datadir/spk2utt
utils/utt2spk_to_spk2utt.pl $subset_select/uttids_speakers | sort > $subset_select/spk2utt
utils/utt2spk_to_spk2utt.pl $subset_rest/uttids_speakers | sort > $subset_rest/spk2utt

sed  's@^[^\_]*\_@@g' $datadir/aud_ali.mb.txt | utils/filter_scp.pl $subset_select/uttids - | sort > $subset_select/aud_ali.mb.txt
sed  's@^[^\_]*\_@@g' $datadir/aud_ali.mb.txt | utils/filter_scp.pl $subset_rest/uttids - | sort > $subset_rest/aud_ali.mb.txt


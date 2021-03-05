#!/bin/bash

stage=3
src="mb"
tgt="fr"
nbpe=1000
nphones=70
nauds=58
nutt_dev=200
raw_datadir=data/mboshi_downloaded
datadir=data/mboshi-fr
tok_dir=exp/tokenization
exp=exp

. path.sh
. parse_options.sh

[ ! -d $tok_dir ] && mkdir -p $tok_dir

# split_data.sh 
if [ $stage -le 1 ]; then
    local/split_data.sh --num-select $nutt_dev $raw_datadir $datadir/dev $datadir/train
fi

# normalize_ali.py: remove duplicated consecutive words in the aligntments
if [ $stage -le 2 ]; then
    for d in train dev test; do
       python3 local/normalize_ali.py $datadir/$d/ali.mb.txt > $datadir/$d/ali.mb.redup.txt
       python3 local/normalize_ali.py $datadir/$d/aud_ali.mb.txt > $datadir/$d/aud_ali.mb.redup.txt
       sed -i 's/<unk>/<unknown>/g' $datadir/$d/ali.mb.redup.txt
    done
fi

bpe_dir=$tok_dir/nbpe_${nbpe}
# Train BPE and BPE encoding
if [ $stage -le 3 ]; then
    mkdir -p $bpe_dir || exit 1;

    for lan in $src $tgt; do
        for d in train dev test; do
            cut -d " " -f2- $datadir/$d/trans.wrd.$lan.txt > $bpe_dir/$d.$lan.txt
        done
        cat $bpe_dir/train.$lan.txt $bpe_dir/dev.$lan.txt > $bpe_dir/bpe_train.$lan.txt

        # Only train BPE and encode with BPE for word transcription / translation
        spm_train --input=$bpe_dir/bpe_train.$lan.txt \
            --model_prefix=$bpe_dir/spm_bpe${nbpe}_${lan} \
            --vocab_size=$nbpe --character_coverage=1.0 \
            --model_type=bpe \
            --user_defined_symbols "<sil>","<unknown>","&apos;","&quot;"
        for d in train dev test; do
            cut -d " " -f2- $datadir/$d/trans.wrd.$lan.txt |\
                spm_encode --model=$bpe_dir/spm_bpe${nbpe}_${lan}.model \
                --output_format=piece > $bpe_dir/$d.$lan
        done
    done
fi

if [ $stage -le 4 ]; then
    echo "$(date -u) MB-phones"
    mb_phone_tok_dir=$exp/mb_nphones_${nphones}
    mkdir -p $mb_phone_tok_dir || exit 1;
    for d in train dev test; do
        ln -s $(pwd)/$bpe_dir/$d.fr $mb_phone_tok_dir/$d.fr
        ln -s $(pwd)/$bpe_dir/$d.fr.wrd.txt $mb_phone_tok_dir/$d.fr.wrd.txt
        cut -d " " -f2- $datadir/$d/ali.mb.redup.txt > $mb_phone_tok_dir/$d.mb
    done
#     # For Mboshi phone/aud tokenization, we use the spm char


#     # Tokenization for phones
#     cat <(cut -d " " -f2- $datadir/train/ali.mb.redup.txt) \
#         <(cut -d " " -f2- $datadir/dev/ali.mb.redup.txt) > $mb_phone_tok_dir/phone_train.mb.txt
#     spm_train --input=$mb_phone_tok_dir/phone_train.mb.txt \
#         --model_prefix=$mb_phone_tok_dir/spm_char${nphones} \
#         --vocab_size=$nphones --character_coverage=1.0 \
#         --model_type=char \
#         --user_defined_symbols "<sil>","<unknown>","&apos;","&quot;"
#     for d in train dev test; do
#         cut -d " " -f2- $datadir/$d/ali.mb.redup.txt |\
#             spm_encode --model=$mb_phone_tok_dir/spm_char${nphones}.model \
#             --output_format=piece > $mb_phone_tok_dir/$d.$tgt
#         cp $bpe_dir/$d.$src $mb_phone_tok_dir/$d.$tgt
#     done
fi

 if [ $stage -le 5 ]; then
     echo "$(date -u) MB-auds"
     mb_aud_tok_dir=$exp/mb_nauds_${nauds}
     mkdir -p $mb_aud_tok_dir || exit 1;
    for d in train dev test; do
        ln -s $(pwd)/$bpe_dir/$d.fr $mb_aud_tok_dir/$d.fr
        ln -s $(pwd)/$bpe_dir/$d.fr.wrd.txt $mb_aud_tok_dir/$d.fr.wrd.txt
        cut -d " " -f2- $datadir/$d/aud_ali.mb.redup.txt | sed 's/sil/<sil>/'g > $mb_aud_tok_dir/$d.mb
    done
##### Wrong: since aud units are like "aud1" "aud2", ... , they should not be splitted.
#     # Tokenization for aud units
#     cat <(cut -d " " -f2- $datadir/train/aud_ali.mb.redup.txt | sed 's/sil/<sil>/'g) \
#         <(cut -d " " -f2- $datadir/dev/aud_ali.mb.redup.txt | sed 's/sil/<sil>/'g) > $mb_aud_tok_dir/aud_train.mb.txt
#     spm_train --input=$mb_aud_tok_dir/aud_train.mb.txt \
#         --model_prefix=$mb_aud_tok_dir/spm_char${nauds} \
#         --vocab_size=$nauds --character_coverage=1.0 \
#         --model_type=char \
#         --user_defined_symbols "<sil>","<unknown>","&apos;","&quot;"

#     for d in train dev test; do
#         cut -d " " -f2- $datadir/$d/aud_ali.mb.redup.txt | sed 's/sil/<sil>/'g\
#             spm_encode --model=$mb_aud_tok_dir/spm_char${nauds}.model \
#             --output_format=piece > $mb_aud_tok_dir/ali.auds.mb.$d.txt
#     done
fi
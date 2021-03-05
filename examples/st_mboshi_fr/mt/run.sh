#!/bin/bash

stage=0
. path.sh
. cmd.sh
. parse_options.sh

if [ $# -ne 1 ];then
    echo "Usage: $0 <train-conf>"
    echo "E.g. $0 mt_words.conf"
    exit 1;
fi


conf=$1
. $conf

if [ $stage -le 1 ]; then
    echo "$(date) Preprocessing"
    fairseq-preprocess -s $src -t $tgt \
        --trainpref $token_dir/train \
        --validpref $token_dir/dev \
        --testpref $token_dir/dev,$token_dir/test \
        --destdir $bin_dir || exit 1;
fi

if [ $stage -le 2 ]; then
    echo "$(date) Training for ${src}-${tgt}: source type is ${type}"
    mkdir -p $exp_dir/log || exit 1;
    cp $conf $exp_dir 
    $cuda_cmd --gpu $ngpus $exp_dir/log/train.log \
        fairseq-train $bin_dir \
            -s $src \
            -t $tgt \
            --num-workers $train_num_workers \
            --task $task \
            --arch $arch \
            --encoder-layers $encoder_layers \
            --encoder-embed-dim $encoder_embed_dim \
            --encoder-ffn-embed-dim $encoder_ffn_embed_dim \
            --encoder-attention-heads $encoder_attention_heads \
            --decoder-layers $decoder_layers \
            --decoder-embed-dim $decoder_embed_dim \
            --decoder-ffn-embed-dim $decoder_ffn_embed_dim \
            --decoder-attention-heads $decoder_attention_heads \
            --tensorboard-logdir $exp_dir/tensorboard-log \
            --activation-fn relu \
            --optimizer $optimizer --adam-betas '(0.9, 0.98)' \
            --lr-scheduler $lr_scheduler \
            --update-freq $update_freq \
            --clip-norm $clip_norm \
            --patience $patience \
            --dropout $dropout \
            --max-epoch $max_epoch \
            --lr $lr \
            --warmup-init-lr $init_lr \
            --stop-min-lr $stop_min_lr \
            --warmup-updates $warmup_updates \
            --weight-decay $weight_decay \
            --batch-size $batch_size \
            --curriculum $curriculum \
            --criterion $criterion \
            --label-smoothing $label_smoothing \
            --attention-dropout $transformer_attn_dropout \
            --save-dir $exp_dir/checkpoints \
            --save-interval $save_interval \
            --log-format json || exit 1
fi

if [ $stage -le 3 ]; then
    for dset in test test1; do
        decode_dir=$exp_dir/decode_${dset}_best
        echo "$(date) Decoding for ${src}-${tgt}: dset is ${dset}, type is ${type}"
        mkdir -p $decode_dir/log || exit 1;
        if [ $type == "word " ]; then # We assume BPE was performed on the word sequences
            $cuda_cmd --gpu 1 --mem 4G $decode_dir/log/decode.log \
                fairseq-generate $bin_dir \
                    -s $src \
                    -t $tgt \
                    --task $task \
                    --gen-subset $dset \
                    --path $exp_dir/checkpoints/checkpoint_best.pt \
                    --batch-size 32 \
                    --beam 15 \
                    --scoring sacrebleu \
                    --remove-bpe=sentencepiece > $decode_dir/decode.$src.sys
            #grep ^H $decode_dir/decode.$src.sys | cut -f3 |\
            #    sacrebleu --test-set $dset --language-pair ${src}-${tgt}
            #cat $token_dir/$dset.$tgt.wrd.txt
        else
            $cuda_cmd --gpu 1 --mem 4G $decode_dir/log/decode.log \
                fairseq-generate $bin_dir \
                    -s $src \
                    -t $tgt \
                    --task $task \
                    --gen-subset $dset \
                    --path $exp_dir/checkpoints/checkpoint_best.pt \
                    --batch-size 32 \
                    --beam 15 \
                    --scoring sacrebleu > $decode_dir/decode.$src.sys
            #grep ^H $decode_dir/decode.$src.sys | cut -f3 |\
        fi
    done
fi
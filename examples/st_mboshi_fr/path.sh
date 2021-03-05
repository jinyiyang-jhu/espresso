KALDI_PATH=/export/b16/draj/kaldi
OPENFST_PATH=/export/b07/jyang/kaldi-jyang/kaldi/tools/openfst/bin
export PATH=$KALDI_PATH/latbin:$KALDI_PATH/featbin:$KALDI_PATH/bin:$OPENFST_PATH:utils:$PWD:$PATH
unset PYTHONPATH
export PYTHONPATH=$PYTHONPATH

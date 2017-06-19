#!/bin/bash

#-------------------------------------------------------
DATE_TIME=`date +'%Y-%m-%d_%H-%M-%S'`
#-------------------------------------------------------

#-------------------------------------------------------
model_name=jacintonet11
dataset=imagenet
folder_name=training/"$model_name"_"$dataset"_"$DATE_TIME";mkdir $folder_name

#------------------------------------------------
LOG=$folder_name/train-log_"$DATE_TIME".txt
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

#------------------------------------------------
caffe="../../build/tools/caffe.bin"

#-------------------------------------------------------
max_iter=320000
base_lr=0.1
solver_param="{'type':'SGD','base_lr':$base_lr,'max_iter':$max_iter}"

#-------------------------------------------------------
max_iter=96000
base_lr=1e-3  #use a lower lr for fine tuning
sparse_solver_param="{'type':'$type','base_lr':$base_lr,'max_iter':$max_iter,'sparse_mode':1,'display_sparsity':1000}"

#-------------------------------------------------------
max_iter=4000
base_lr=1e-4  #use a lower lr for fine tuning
quant_solver_param="{'type':'$type','base_lr':$base_lr,'max_iter':$max_iter,'sparse_mode':1,'display_sparsity':1000\
,'insert_quantization_param':1,'quantization_start_iter':2000,'snapshot_log':1}"

#-------------------------------------------------------
stage="stage0"
config_name=$folder_name/$stage;mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','pretrain_model':None}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param="$solver_param"
config_name_prev=$config_name

#Threshold step
stage="stage1"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
$caffe threshold --threshold_fraction_low 0.40 --threshold_fraction_mid 0.70 --threshold_fraction_high 0.70 --threshold_value_max 0.2 --threshold_value_maxratio 0.2 --threshold_step_factor $threshold_step_factor --model="$config_name_prev/deploy.prototxt" --gpu="0" --weights=$weights --output=$config_name/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name_prev=$config_name

#fine tuning
stage="stage2"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','stride_list':$stride_list,'pretrain_model':'$weights'}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$sparse_solver_param
config_name_prev=$config_name

#Threshold step
stage="stage3"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
$caffe threshold --threshold_fraction_low 0.40 --threshold_fraction_mid 0.80 --threshold_fraction_high 0.80 --threshold_value_max 0.2 --threshold_value_maxratio 0.2 --threshold_step_factor $threshold_step_factor --model="$config_name_prev/deploy.prototxt" --gpu="0" --weights=$weights --output=$config_name/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name_prev=$config_name

#fine tuning
stage="stage4"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','stride_list':$stride_list,'pretrain_model':'$weights'}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$sparse_solver_param
config_name_prev=$config_name

#Threshold step
stage="stage5"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
$caffe threshold --threshold_fraction_low 0.40 --threshold_fraction_mid 0.90 --threshold_fraction_high 0.90 --threshold_value_max 0.2 --threshold_value_maxratio 0.2 --threshold_step_factor $threshold_step_factor --model="$config_name_prev/deploy.prototxt" --gpu="0" --weights=$weights --output=$config_name/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name_prev=$config_name

#fine tuning
stage="stage6"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','stride_list':$stride_list,'pretrain_model':'$weights'}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$sparse_solver_param
config_name_prev=$config_name

#quantization
stage="stage7"
weights=$config_name_prev/"$model_name"_"$dataset"_iter_$max_iter.caffemodel
config_name="$folder_name"/$stage; echo $config_name; mkdir $config_name
config_param="{'config_name':'$config_name','model_name':'$model_name','dataset':'$dataset','stride_list':$stride_list,'pretrain_model':'$weights'}" 
python ./models/image_classification.py --config_param="$config_param" --solver_param=$quant_solver_param
config_name_prev=$config_name



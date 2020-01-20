#!/bin/bash
set -x

# Give path to MSS prepro anaconda bin
conda_base_path=/home/mss/miniconda3
conda_prepro_instance=mss_prepro
conda_prepro_bin=${conda_base_path}/envs/${conda_prepro_instance}/bin
if [[ ${PATH} != *${conda_prepro_bin}* ]]
then
    export PATH=${conda_prepro_bin}:${PATH}
fi

dir=/home/mss/mss_data
dir=/home_local/jkretzs/mss/mss_data
src_dir=${dir}/src

cd ${src_dir}
#./mss_ecmwf_prepro.bash
./mss_icon_download.bash
cd ..





#!/bin/bash

ecmwf_input=/scratch/ms/datex/gdr/mss/mss_data/ecmwf_input

# Copy data to remote site
eval `ssh-agent -s`
ssh-add /home/ms/datex/gdr/.ssh/id_rsa_mss
rsync -avhP ${ecmwf_input}/* mss@139.18.173.186:/home/mss/mss_data/ecmwf_input

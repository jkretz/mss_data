#!/bin/bash

ecmwf_input=/scratch/ms/datex/gdr/mss/mss_data/ecmwf_input
find ${ecmwf_input}/* -type d -ctime +7 -exec rm -rf {} \;

# Copy data to remote site
pgrep -x -U gdr rsync | xargs kill
sleep 1
eval `ssh-agent -s`
ssh-add /home/ms/datex/gdr/.ssh/id_rsa_mss
rsync -avhP ${ecmwf_input}/ecmwf* mss@139.18.173.186:/data/mss/mss_data/ecmwf_input/
pgrep -U gdr ssh-agent | xargs kill

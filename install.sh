#!/bin/bash

### OS BASE install  


sudo apt-get install icewm -y
sudo apt install tightvncserver -y
sudo apt install xterm -y
sudo apt install mc -y
sudo apt-get install xfsprogs -y
sudo apt install net-tools -y
sudo apt install git -y
sudo apt install nfs-kernel-server -y
sudo apt install nfs-common -y

vncserver


cat > ~/disk-setup.sh <<EOL
#!/bin/bash

sudo chown vlad:vlad /mnt

for i in {1..12} 
do
mkdir /mnt/disk$i
done

## FORMAT


for d in {b..l}
do
 current_fs=$(lsblk -no KNAME,FSTYPE /dev/sd$d)
 current_fs=$(echo $current_fs | awk '{print $2}')
 if [ $current_fs == "xfs" ]; then
  echo -e "sd$d already formated"
 else
  sudo mkfs.xfs  -f -L DISK2 /dev/sd$d
 fi
done

### MOUNT


for i in {2..12}
do
  f=96
  x=$((i + f))
  t=$(printf "\\$(printf '%03o' "$x")")
  sudo mount /dev/sd$t /mnt/disk$i
  sudo bash -c 'echo /dev/sd'"$t"' /mnt/disk'"$i"' xfs defaults 0 2 >> /etc/fstab'
done

sudo chown vlad:vlad -R /mnt


#### CREATE  CHIA DIRS

for i in {1..12}
do
 mkdir /mnt/disk$i/tmp
 mkdir /mnt/disk$i/final
done

hhEOL
chmod a+x disk-setup.sh

#### NETWORK SETUP FOR PRIV NET

cat > ~/pn-setup.sh <<EOL

#!/bin/bash

sudo echo -e "  ethernets:" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "    enp2s0f1:" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "       dhcp4: yes" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "       dhcp6: no" >> /etc/netplan/01-netcfg.yaml

sudo netplan apply

EOL

chmod a+x ~/pn-setup.sh
#sudo ~/pn-setup.sh


### NFS SETUP

cat > ~/nfs-setup.sh <<EOL
#!/bin/bash

sudo chmod a+rwx -R /mnt

sudo bash -c 'echo -e "/mnt  10.32.51.160/27(rw,sync,no_subtree_check,crossmnt,no_root_squash)" >> /etc/exports'

sudo systemctl restart nfs-kernel-server
sudo exportfs -a
sudo chmod a+rwx -R /mnt
 
EOL

chmod a+x ~/nfs-setup.sh
#sudo ~/nfs-setup.sh

### FIREWALL SETUP


cat > ~/fw-setup.sh <<EOL
#!/bin/bash

sudo ufw allow from any to any port 22
sudo ufw allow from any to any port 5901
sudo ufw allow from any to any port 5902
sudo ufw allow from any to any port 8444
sudo ufw allow from any to any port 5903
sudo ufw allow from any to any port 5904
sudo ufw allow from 10.32.51.160/27 to 10.32.51.160/27  port nfs
sudo ufw enable
sudo ufw status


EOL

chmod a+x ~/fw-setup.sh
#sudo ~/fw-setup.sh

### install CHIA

cat > ~/chia-setup.sh <<EOL
#!/bin/bash


cd ~
git clone https://github.com/Chia-Network/chia-blockchain.git -b latest --recurse-submodules
cd chia-blockchain
sh install.sh
. ./activate
chia init

sudo chown -R vlad:vlad /home/vlad

echo "lesson pattern shaft fiction dish father since tongue flame quarter spirit hen empty file dismiss rotate wrist witness distance dwarf symbol trumpet gossip nose" >> ~/words.tmp
chia keys add -f ~/words.tmp
rm ~/words.tmp

EOL
chmod a+x ~/chia-setup.sh
#sudo ~/chia-setup.sh


### Install HPOOL miner

cat > ~/hp-setup.sh <<EOL2
#!/bin/bash

cd ~
wget https://github.com/hpool-dev/chia-miner/releases/download/v1.2.0-5/HPool-Miner-chia-v1.2.0-5-linux.zip
unzip HPool-Miner-chia-v1.2.0-5-linux.zip
mv linux hpool-farmer

### deploy HPool CONFIG


cat > ~/hpool-farmer/config.yaml <<EOL
token: ""
path:
- /mnt/disk1/tmp
- /mnt/disk1/final
- /mnt/disk2/tmp
- /mnt/disk2/final
- /mnt/disk3/tmp
- /mnt/disk3/final
- /mnt/disk4/tmp
- /mnt/disk4/final
- /mnt/disk5/tmp
- /mnt/disk5/final
- /mnt/disk6/tmp
- /mnt/disk6/final
- /mnt/disk7/tmp
- /mnt/disk7/final
- /mnt/disk8/tmp
- /mnt/disk8/final
- /mnt/disk9/tmp
- /mnt/disk9/final
- /mnt/disk10/tmp
- /mnt/disk10/final
- /mnt/disk11/tmp
- /mnt/disk11/final
- /mnt/disk12/tmp
- /mnt/disk12/final
- /mnt/disk1/final
minerName: $HOSTNAME
apiKey: 025ba5b5-8bf2-4bdd-bb8b-2af1d3f65515
cachePath: ""
deviceId: ""
extraParams: {}
log:
  lv: info
  path: ./log/
  name: miner.log
url:
  info: ""
  submit: ""
  line: ""
scanPath: true
scanMinute: 5
debug: ""
language: en
EOL

EOL2
chmod a+x ~/hp-setup.sh
#sudo ~/hp-setup.sh


### INSTALL SCHEDULER

cat > ~/sched-setup.sh <<EOL2
#!/bin/bash


cd ~
git clone https://github.com/swar/Swar-Chia-Plot-Manager
cd ~/chia-blockchain
. ./activate
cd ~/Swar-Chia-Plot-Manager
pip install -r requirements.txt


### deploy scheduler config


cat > ~/Swar-Chia-Plot-Manager/config.yaml <<EOL

# This is a single variable that should contain the location of your chia executable file. This is the blockchain executable.
#
# WINDOWS EXAMPLE: C:\Users\Swar\AppData\Local\chia-blockchain\app-1.1.2\resources\app.asar.unpacked\daemon\chia.exe
#   LINUX EXAMPLE: /usr/lib/chia-blockchain/resources/app.asar.unpacked/daemon/chia
#  LINUX2 EXAMPLE: /home/swar/chia-blockchain/venv/bin/chia
chia_location: /home/vlad/chia-blockchain/venv/bin/chia


manager:
  # These are the config settings that will only be used by the plot manager.
  #
  # check_interval: The number of seconds to wait before checking to see if a new job should start.
  #      log_level: Keep this on ERROR to only record when there are errors. Change this to INFO in order to see more
  #                 detailed logging. Warning: INFO will write a lot of information.
  check_interval: 60
  log_level: ERROR


log:
  # folder_path: This is the folder where your log files for plots will be saved.
  folder_path: /home/vlad/.chia/mainnet/plotter


view:
  # These are the settings that will be used by the view.
  #
  #            check_interval: The number of seconds to wait before updating the view.
  #           datetime_format: The datetime format that you want displayed in the view. See here
  #                            for formatting: https://docs.python.org/3/library/datetime.html#strftime-and-strptime-format-codes
  # include_seconds_for_phase: This dictates whether seconds are included in the phase times.
  #        include_drive_info: This dictates whether the drive information will be showed.
  #               include_cpu: This dictates whether the CPU information will be showed.
  #               include_ram: This dictates whether the RAM information will be showed.
  #        include_plot_stats: This dictates whether the plot stats will be showed.
  check_interval: 60
  datetime_format: "%Y-%m-%d %H:%M:%S"
  include_seconds_for_phase: true
  include_drive_info: true
  include_cpu: true
  include_ram: true
  include_plot_stats: true


notifications:
  # These are different settings in order to notified when the plot manager starts and when a plot has been completed.

  # DISCORD
  notify_discord: false
  discord_webhook_url: https://discord.com/api/webhooks/0000000000000000/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

  # PLAY AUDIO SOUND
  notify_sound: false
  song: audio.mp3

  # PUSHOVER PUSH SERVICE
  notify_pushover: false
  pushover_user_key: xx
  pushover_api_key: xx

  # TWILIO
  notify_twilio: false
  twilio_account_sid: xxxxx
  twilio_auth_token: xxxxx
  twilio_from_phone: +1234657890
  twilio_to_phone: +1234657890


progress:
  # phase_line_end: These are the settings that will be used to dictate when a phase ends in the progress bar. It is
  #                 supposed to reflect the line at which the phase will end so the progress calculations can use that
  #                 information with the existing log file to calculate a progress percent.
  #   phase_weight: These are the weight to assign to each phase in the progress calculations. Typically, Phase 1 and 3
  #                 are the longest phases so they will hold more weight than the others.
  phase1_line_end: 801
  phase2_line_end: 834
  phase3_line_end: 2474
  phase4_line_end: 2620
  phase1_weight: 33.4
  phase2_weight: 20.43
  phase3_weight: 42.29
  phase4_weight: 3.88


global:
  # These are the settings that will be used globally by the plot manager.
  #
  # max_concurrent: The maximum number of plots that your system can run. The manager will not kick off more than this
  #                 number of plots total over time.
  max_concurrent: 11


jobs:
  # These are the settings that will be used by each job. Please note you can have multiple jobs and each job should be
  # in YAML format in order for it to be interpreted correctly. Almost all the values here will be passed into the
  # Chia executable file.
  #
  # Check for more details on the Chia CLI here: https://github.com/Chia-Network/chia-blockchain/wiki/CLI-Commands-Reference
  #
  # name: This is the name that you want to give to the job.
  # max_plots: This is the maximum number of jobs to make in one run of the manager. Any restarts to manager will reset
  #            this variable. It is only here to help with short term plotting.
  #
  # [OPTIONAL] farmer_public_key: Your farmer public key. If none is provided, it will not pass in this variable to the
  #                               chia executable which results in your default keys being used. This is only needed if
  #                               you have chia set up on a machine that does not have your credentials.
  # [OPTIONAL] pool_public_key: Your pool public key. Same information as the above.
  #
  # temporary_directory: Only a single directory should be passed into here. This is where the plotting will take place.
  # [OPTIONAL] temporary2_directory: Can be a single value or a list of values. This is an optional parameter to use in
  #                                  case you want to use the temporary2 directory functionality of Chia plotting.
  # destination_directory: Can be a single value or a list of values. This is the final directory where the plot will be
  #                        transferred once it is completed. If you provide a list, it will cycle through each drive
  #                        one by one.
  #
  # size: This refers to the k size of the plot. You would type in something like 32, 33, 34, 35... in here.
  # bitfield: This refers to whether you want to use bitfield or not in your plotting. Typically, you want to keep
  #           this as true.
  # threads: This is the number of threads that will be assigned to the plotter. Only phase 1 uses more than 1 thread.
  # buckets: The number of buckets to use. The default provided by Chia is 128.
  # memory_buffer: The amount of memory you want to allocate to the process.
  # max_concurrent: The maximum number of plots to have for this job at any given time.
  # max_concurrent_with_start_early: The maximum number of plots to have for this job at any given time including
  #                                  phases that started early.
  # stagger_minutes: The amount of minutes to wait before the next job can get kicked off. You can even set this to
  #                  zero if you want your plots to get kicked off immediately when the concurrent limits allow for it.
  # max_for_phase_1: The maximum number of plots on phase 1 for this job.
  # concurrency_start_early_phase: The phase in which you want to start a plot early. It is recommended to use 4 for
  #                                this field.
  # concurrency_start_early_phase_delay: The maximum number of seconds to wait before a new plot gets kicked off when
  #                                      the start early phase has been detected.
  # temporary2_destination_sync: This field will always submit the destination directory as the temporary2 directory.
  #                              These two directories will be in sync so that they will always be submitted as the
  #                              same value.

  - name: Q11
    max_plots: 9999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk11/tmp
    temporary2_directory:
    destination_directory: /mnt/disk11/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false

  - name: Q12
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk12/tmp
    temporary2_directory:
    destination_directory: /mnt/disk12/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false

  - name: Q10
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk10/tmp
    temporary2_directory:
    destination_directory: /mnt/disk10/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false

  - name: Q9
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk9/tmp
    temporary2_directory:
    destination_directory: /mnt/disk9/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false

  - name: Q8
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk8/tmp
    temporary2_directory:
    destination_directory: /mnt/disk8/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false

  - name: Q7
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk7/tmp
    temporary2_directory:
    destination_directory: /mnt/disk7/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false


  - name: Q6
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk6/tmp
    temporary2_directory:
    destination_directory: /mnt/disk6/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false



  - name: Q5
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk5/tmp
    temporary2_directory:
    destination_directory: /mnt/disk5/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false


  - name: Q4
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk4/tmp
    temporary2_directory:
    destination_directory: /mnt/disk4/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false


  - name: Q3
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk3/tmp
    temporary2_directory:
    destination_directory: /mnt/disk3/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false


  - name: Q2
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk2/tmp
    temporary2_directory:
    destination_directory: /mnt/disk2/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false


  - name: Q1
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk1/tmp
    temporary2_directory:
    destination_directory: /mnt/disk1/tmp
    size: 32
    bitfield: true
    threads: 2
    buckets: 128
    memory_buffer: 5000
    max_concurrent: 1
    max_concurrent_with_start_early: 1
    stagger_minutes: 70
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false

EOL

EOL2
chmod a+x ~/sched-setup.sh
#sudo ~/sched-setup.sh


### DEPLOY COPY SCRIPT


cat > ~/copy-plots.sh <<EOL

#!/bin/bash

$IP
$server=s$IP-12x12

mkdir /mnt/$server
sudo mount 10.32.51.1$IP:/mnt -t nfs /mnt/$server

while :
do

for i in {2..12}
do
  tmp_dir="/mnt/disk$i/tmp"
  f_dir="/mnt/$server/disk$i/tmp"
#  echo -e "$f_dir"
  for file in "$tmp_dir"/*.plot; do
    filename=$(basename -- "$file")
    if [ "$filename" == "*.plot" ]; then
     sleep 1
    else
        myfilesize=$(wc -c "$tmp_dir/$filename" | awk '{print $1}')
        if [ "$myfilesize" == "0" ]; then
                rm $tmp_dir/$filename
        else
        echo -e "$myfilesize in $tmp_dir to $f_dir - MY PID IS: $BASHPID "
        rsync --remove-source-files --progress  "$tmp_dir"/"$filename" "$f_dir"/"$filename"
        myfilesize2=$(wc -c "$tmp_dir/$filename" | awk '{print $1}')
            if [ "$myfilesize2" == "0" ]; then
                rm $tmp_dir/$filename
            fi

        break
        fi
    fi
  done
done

sleep 10
done


EOL

chmod a+x ~/copy-plots.sh



cat > ~/start_mg.sh <<EOL
#!/bin/bash

cd ~/chia-blockchain
. ./activate
cd ~/Swar-Chia-Plot-Manager
python manager.py restart

EOL
chmod a+x ~/start_mg.sh

cat > ~/view_mg.sh <<EOL
#!/bin/bash

cd ~/chia-blockchain
. ./activate
cd ~/Swar-Chia-Plot-Manager
python manager.py view

EOL
chmod a+x ~/view_mg.sh

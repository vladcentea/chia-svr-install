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

u=$'$(printf "\\\\$(printf '%03o' "$x")")'


cat > ~/disk-setup.sh<<EOL
#!/bin/bash

sudo chown vlad:vlad /mnt

for i in {1..12} 
do
mkdir /mnt/disk\$i
done

## FORMAT


for d in {b..l}
do
 current_fs=\$(lsblk -no KNAME,FSTYPE /dev/sd\$d)
 current_fs=\$(echo \$current_fs | awk '{print \$2}')
 if [ \$current_fs == "xfs" ]; then
  echo -e "sd\$d already formated"
 else
  sudo mkfs.xfs  -f -L DISK2 /dev/sd\$d
 fi
done

### MOUNT


for i in {2..12}
do
  f=96
  x=\$((i + f))
  t=$u
  sudo mount /dev/sd\$t /mnt/disk\$i
  sudo bash -c 'echo /dev/sd'"\$t"' /mnt/disk'"\$i"' xfs defaults 0 2 >> /etc/fstab'
done

sudo chown vlad:vlad -R /mnt


#### CREATE  CHIA DIRS

# for i in {1..12}
# do
#  mkdir /mnt/disk\$i/tmp
#  mkdir /mnt/disk\$i/final
# done

EOL
chmod a+x ~/disk-setup.sh

#### NETWORK SETUP FOR PRIV NET

cat > ~/pn-setup.sh<<EOL

#!/bin/bash
vncserver

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
- /mnt/disk1
- /mnt/disk2
- /mnt/disk3
- /mnt/disk4
- /mnt/disk5
- /mnt/disk6
- /mnt/disk7
- /mnt/disk8
- /mnt/disk9
- /mnt/disk10
- /mnt/disk11
- /mnt/disk12
- /mnt/disk1/final
- /mnt/disk2/final
- /mnt/disk3/final
- /mnt/disk4/final
- /mnt/disk5/final
- /mnt/disk6/final
- /mnt/disk7/final
- /mnt/disk8/final
- /mnt/disk9/final
- /mnt/disk10/final
- /mnt/disk11/final
- /mnt/disk12/final
- /mnt/disk1/tmp
- /mnt/disk2/tmp
- /mnt/disk3/tmp
- /mnt/disk4/tmp
- /mnt/disk5/tmp
- /mnt/disk6/tmp
- /mnt/disk7/tmp
- /mnt/disk8/tmp
- /mnt/disk9/tmp
- /mnt/disk10/tmp
- /mnt/disk11/tmp
- /mnt/disk12/tmp
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
# WINDOWS EXAMPLE: C:\Users\Swar\AppData\Local\chia-blockchain\app-1.1.5\resources\app.asar.unpacked\daemon\chia.exe
#   LINUX EXAMPLE: /usr/lib/chia-blockchain/resources/app.asar.unpacked/daemon/chia
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
  folder_path: /home/vlad/.chia/mainnet/Plotter


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

  # IFTTT, ref https://ifttt.com/maker_webhooks, and this function will send title as value1 and message as value2.
  notify_ifttt: false
  ifttt_webhook_url: https://maker.ifttt.com/trigger/{event}/with/key/{api_key}

  # PLAY AUDIO SOUND
  notify_sound: false
  song: audio.mp3

  # PUSHOVER PUSH SERVICE
  notify_pushover: false
  pushover_user_key: xx
  pushover_api_key: xx

  # TELEGRAM
  notify_telegram: false
  telegram_token: xxxxx

  # TWILIO
  notify_twilio: false
  twilio_account_sid: xxxxx
  twilio_auth_token: xxxxx
  twilio_from_phone: +1234657890
  twilio_to_phone: +1234657890


instrumentation:
  # This setting is here in case you wanted to enable instrumentation using Prometheus.
  prometheus_enabled: false
  prometheus_port: 9090


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
  # max_for_phase_1: The maximum number of plots that your system can run in phase 1.
  # minimum_minutes_between_jobs: The minimum number of minutes before starting a new plotting job, this prevents
  #                               multiple jobs from starting at the exact same time. This will alleviate congestion
  #                               on destination drive. Set to 0 to disable.
  max_concurrent: 7
  max_for_phase_1: 3
  minimum_minutes_between_jobs: 5


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
  # temporary_directory: Can be a single value or a list of values. This is where the plotting will take place. If you
  #                      provide a list, it will cycle through each drive one by one.
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
  # initial_delay_minutes: This is the initial delay that is used when initiate the first job. It is only ever
  #                        considered once. If you restart manager, it will still adhere to this value.
  # stagger_minutes: The amount of minutes to wait before the next plot for this job can get kicked off. You can even set this to
  #                  zero if you want your plots to get kicked off immediately when the concurrent limits allow for it.
  # max_for_phase_1: The maximum number of plots on phase 1 for this job.
  # concurrency_start_early_phase: The phase in which you want to start a plot early. It is recommended to use 4 for
  #                                this field.
  # concurrency_start_early_phase_delay: The maximum number of minutes to wait before a new plot gets kicked off when
  #                                      the start early phase has been detected.
  # temporary2_destination_sync: This field will always submit the destination directory as the temporary2 directory.
  #                              These two directories will be in sync so that they will always be submitted as the
  #                              same value.
  # exclude_final_directory: Whether to skip adding `destination_directory` to harvester for farming
  # skip_full_destinations: When this is enabled it will calculate the sizes of all running plots and the future plot
  #                         to determine if there is enough space left on the drive to start a job. If there is not,
  #                         it will skip the destination and move onto the next one. Once all are full, it will
  #                         disable the job.
  # unix_process_priority: UNIX Only. This is the priority that plots will be given when they are spawned. UNIX values
  #                        must be between -20 and 19. The higher the value, the lower the priority of the process.
  # windows_process_priority: Windows Only. This is the priority that plots will be given when they are spawned.
  #                           Windows values vary and should be set to one of the following values:
  #                             - 16384 (BELOW_NORMAL_PRIORITY_CLASS)
  #                             - 32    (NORMAL_PRIORITY_CLASS)
  #                             - 32768 (ABOVE_NORMAL_PRIORITY_CLASS)
  #                             - 128   (HIGH_PRIORITY_CLASS)
  #                             - 256   (REALTIME_PRIORITY_CLASS)
  # enable_cpu_affinity: Enable or disable cpu affinity for plot processes. Systems that plot and harvest may see
  #                      improved harvester or node performance when excluding one or two threads for plotting process.
  #        cpu_affinity: List of cpu (or threads) to allocate for plot processes. The default example assumes you have
  #                      a hyper-threaded 4 core CPU (8 logical cores). This config will restrict plot processes to use
  #                      logical cores 0-5, leaving logical cores 6 and 7 for other processes (6 restricted, 2 free).


  - name: Q2
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk2
    temporary2_directory:
    destination_directory: /mnt/disk2
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q3
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk3
    temporary2_directory:
    destination_directory: /mnt/disk3
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q4
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk4
    temporary2_directory:
    destination_directory: /mnt/disk4
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q5
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk5
    temporary2_directory:
    destination_directory: /mnt/disk5
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]


  - name: Q6
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk6
    temporary2_directory:
    destination_directory: /mnt/disk6
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q7
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk7
    temporary2_directory:
    destination_directory: /mnt/disk7
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q8
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk8
    temporary2_directory:
    destination_directory: /mnt/disk8
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q9
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk9
    temporary2_directory:
    destination_directory: /mnt/disk9
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q10
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk10
    temporary2_directory:
    destination_directory: /mnt/disk10
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q11
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk11
    temporary2_directory:
    destination_directory: /mnt/disk11
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q12
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk12
    temporary2_directory:
    destination_directory: /mnt/disk12
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

  - name: Q1
    max_plots: 999
    farmer_public_key:
    pool_public_key:
    temporary_directory: /mnt/disk1
    temporary2_directory:
    destination_directory: /mnt/disk1
    size: 32
    bitfield: true
    threads: 8
    buckets: 128
    memory_buffer: 4000
    max_concurrent: 6
    max_concurrent_with_start_early: 7
    initial_delay_minutes: 0
    stagger_minutes: 60
    max_for_phase_1: 2
    concurrency_start_early_phase: 4
    concurrency_start_early_phase_delay: 0
    temporary2_destination_sync: false
    exclude_final_directory: false
    skip_full_destinations: false
    unix_process_priority: 10
    windows_process_priority: 32
    enable_cpu_affinity: false
    cpu_affinity: [ 0, 1, 2, 3, 4, 5 ]

EOL

EOL2
chmod a+x ~/sched-setup.sh
#sudo ~/sched-setup.sh


### DEPLOY COPY SCRIPT


cat > ~/copy-plots.sh<<EOL
#!/bin/bash

\$IP=68
\$server=s\$IP-12x12

mkdir /mnt/\$server
sudo mount 10.32.51.1\$IP:/mnt -t nfs /mnt/\$server

while :
do

for i in {2..12}
do
  tmp_dir="/mnt/disk\$i"
  f_dir="/mnt/\$server/disk\$i"
#  echo -e "\$f_dir"
  for file in "\$tmp_dir"/*.plot; do
    filename=\$(basename -- "\$file")
    if [ "\$filename" == "*.plot" ]; then
     sleep 1
    else
        myfilesize=\$(wc -c "\$tmp_dir/\$filename" | awk '{print \$1}')
        if [ "\$myfilesize" == "0" ]; then
                rm \$tmp_dir/\$filename
        else
        echo -e "\$myfilesize in \$tmp_dir to \$f_dir - MY PID IS: \$BASHPID "
        rsync --remove-source-files --progress  "\$tmp_dir"/"\$filename" "\$f_dir"/"\$filename"
        myfilesize2=\$(wc -c "\$tmp_dir/\$filename" | awk '{print \$1}')
            if [ "\$myfilesize2" == "0" ]; then
                rm \$tmp_dir/\$filename
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


cat > ~/all_install.sh<<EOL
#!/bin/bash
sudo ~/disk-setup.sh
sudo ~/pn-setup.sh
sudo ~/nfs-setup.sh
sudo ~/fw-setup.sh
~/chia-setup.sh 
~/hp-setup.sh 
~/sched-setup.sh

EOL
chmod a+x ~/all_install.sh


ServerIps=(10.10.1.3 10.10.1.1 10.10.1.2 10.10.1.4 10.10.1.5) # 5
ClientIps=(10.10.1.6)
MasterIp=10.10.1.3
FirstServerPort=17070 # change it when only necessary (i.e., firewall blocking, port in use)
NumOfServerInstances=5 # before recompiling, try no more than 5 servers. See Known Issue # 4
NumOfClientInstances=20 #20, 10, 5, 2
reqsNb=20000

# For Nilext operations:
# 1. writes = 0 for 100% reads
# 2. writes = 100 for 100% writes
writes=50 #non nilext
dlog=false
conflicts=0
thrifty=false

# if closed-loop, uncomment two lines below
clientBatchSize=1
rounds=$((reqsNb / clientBatchSize))
# if open-loop, uncomment the line below
#rounds=1 # open-loop

# some constants
SSHKey=~/go/src/rabia/deployment/install/id_rsa # RC project has it
EPaxosFolder=~/go/src/epaxos # where the epaxos' bin folder is located
LogFolder=~/go/src/epaxos/logs
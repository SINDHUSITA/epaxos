source ./base-profile.sh

function prepareRun() {
    for ip in "${ServerIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "mkdir -p ${LogFolder}; rm -rf ${LogFolder}/*; cd ${EPaxosFolder} && chmod 777 runPaxos.sh" 2>&1
        sleep 0.3
    done
    for ip in "${ClientIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "mkdir -p ${LogFolder}; rm -rf ${LogFolder}/*; cd ${EPaxosFolder} && chmod 777 runPaxos.sh" 2>&1
        sleep 0.3
    done
    wait
}

function runMaster() {
    "${EPaxosFolder}"/bin/master -N ${NumOfServerInstances} 2>&1 &
}

function runServersOneMachine() {
    for idx in $(seq 0 $(($NumOfServerInstances - 1)))
    do
        svrIpIdx=$((idx % ${#ServerIps[@]}))
        svrIp=${ServerIps[svrIpIdx]}
        svrPort=$((FirstServerPort + $idx))
	echo "Server Port Revert"
        if [[ ${svrIpIdx} -eq ${EPMachineIdx} ]]
        then
            "${EPaxosFolder}"/bin/server -port ${svrPort} -maddr ${MasterIp} -addr ${svrIp} -p 4 -thrifty=${thrifty} 2>&1 &
        fi
    done
}

function runClientsOneMachine() {
    ulimit -n 65536
    mkdir -p ${LogFolder}
    for idx in $(seq 0 $((NumOfClientInstances - 1)))
    do
        cliIpIdx=$((idx % ${#ClientIps[@]}))
	echo ${cliIpIdx}
	echo ${EPMachineIdx}
        cliIp=${ClientIps[cliIpIdx]}
	echo ${cliIp}
        if [[ ${cliIpIdx} -eq ${EPMachineIdx} ]]
        then
            "${EPaxosFolder}"/bin/client -maddr ${MasterIp} -q ${reqsNb} -w ${writes} -r ${rounds} -p 30 -c ${conflicts} > ${LogFolder}/S${NumOfServerInstances}-C${NumOfClientInstances}-q${reqsNb}-w${writes}-r${rounds}-c${conflicts}--client${idx}.out 2>&1 &
        fi
    done
}

function runServersAllMachines() {
    runMaster
    sleep 2

    MachineIdx=0
    for ip in "${ServerIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "cd ${EPaxosFolder} && EPScriptOption=StartServers EPMachineIdx=${MachineIdx} /bin/bash runPaxos.sh" 2>&1 &
        sleep 0.3
        ((MachineIdx++))
    done
}

function runClientsAllMachines() {
    MachineIdx=0
    for ip in "${ClientIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "cd ${EPaxosFolder} && EPScriptOption=StartClients EPMachineIdx=${MachineIdx} /bin/bash runPaxos.sh" 2>&1 &
        sleep 0.3
        ((MachineIdx++))
    done
}

function runServersAndClientsAllMachines() {
    runServersAllMachines
    sleep 15 # TODO(highlight): add wait time here
    runClientsAllMachines
}

function SendEPaxosFolder() {
    for ip in "${ServerIps[@]}"
    do
        scp -o StrictHostKeyChecking=no -i ${SSHKey} -r ${EPaxosFolder} sa84@"$ip":~  2>&1 &
        sleep 0.3
    done
    for ip in "${ClientIps[@]}"
    do
        scp -o StrictHostKeyChecking=no -i ${SSHKey} -r ${EPaxosFolder} sa84@"$ip":~  2>&1 &
        sleep 0.3
    done
    wait
}

function SSHCheckClientProgress() {
    for ip in "${ClientIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "ps -fe | grep bin/client" 2>&1 &
    done
}

function EpKillAll() {
    for ip in "${ServerIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "cd ${EPaxosFolder} && chmod 777 kill.sh && /bin/bash kill.sh" 2>&1 &
        sleep 0.3
    done
    for ip in "${ClientIps[@]}"
    do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "cd ${EPaxosFolder} && chmod 777 kill.sh && /bin/bash kill.sh" 2>&1 &
        sleep 0.3
    done
    wait
}

function DownloadLogs() {
    mkdir -p ${LogFolder}

#    for ip in "${ServerIps[@]}"
#    do
#        scp -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip":${LogFolder}/*.out ${LogFolder} 2>&1 &
#        sleep 0.3
#    done

    for ip in "${ClientIps[@]}"
    do
        echo "in download logs"; scp -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip":${LogFolder}/*.out ${LogFolder} 2>&1 &
        sleep 0.3
    done
}

function RemoveLogs(){
  for ip in "${ClientIps[@]}"
  do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "rm -rf ${LogFolder}/*" 2>&1 &
        sleep 0.3
  done

  for ip in "${ServerIps[@]}"
  do
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} sa84@"$ip" "rm -rf ${LogFolder}/*" 2>&1 &
        sleep 0.3
  done
}

function Analysis() {
    sleep 3
#    cat ${LogFolder}/*.out  # for visual inspection
    python3.8 analysis_paxos.py ${LogFolder} print-title
}

function Main() {
    case ${EPScriptOption} in
        "StartServers")
            runServersOneMachine
            ;;
        "StartClients")
            runClientsOneMachine
            ;;
        "killall")
            EpKillAll
            ;;
        *)
            runServersAndClientsAllMachines
            ;;
    esac
}

#SendEPaxosFolder
#prepareRun;
RemoveLogs
wait
echo "Starting Server Setup"
Main
echo "Completed Server Setup"
wait
echo "Starting Download Logs"
DownloadLogs
echo "Completed Download Logs"
wait
echo "Starting Kill"
EpKillAll
echo "Completed Kill"

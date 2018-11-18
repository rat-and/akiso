#!/bin/bash

i=0
declare -A pid
declare -A ppid
declare -A name
declare -A thre
declare -A stat
declare -A opnd

printf "Browsing through proceses...\n"
all_proc=$(ls -l /proc | awk '{print $9}' | grep -Eo '[0-9]{1,4}' | sort -k1 -n) 

###FOR SECOND INDEX=0 RECORD CONTAINS DATA OF ITSELF###
printf "Dereferencing proces data...\n"
for p in $all_proc
do
	if  [ -f /proc/$p/status ] 
	then		
		pid[$i,0]=$(grep '^Pid' /proc/$p/status | awk '{print $2}')
		ppid[$i,0]=$(grep 'PPid' /proc/$p/status | awk '{print $2}')
		name[$i,0]=$(grep 'Name' /proc/$p/status | awk '{print $2}')
		thre[$i,0]=$(grep 'Threads' /proc/$p/status | awk '{print $2}')
		stat[$i,0]=$(grep 'State' /proc/$p/status | awk '{print $2}')

		opn_n=$(lsof -p "${pid[$i,0]}" 2>/dev/null | grep "${pid[$i,0]}" | awk '{print $2}')
		opn_d=$((${#opn_n}+1))
		opn_p=${pid[$i,0]}
		opn_l=$((${#opn_p}+1))
		opn=$((opn_d / opn_l))
		opnd[$i,0]=$opn

		i=$(($i+1))
	fi
done

###FOR SECON INDEX=n RECORD CONTAINS DATA OF ITS n-th CHILD###
printf "Checking relations between proceses and building proces tree...\n"
for j in $(seq 0 $(($i-1)))		
do
	o=1
	for k in $(seq $j $(($i-1))) 
	do
		if [[ "${pid[$j,0]}" -eq "${ppid[$k,0]}" ]] #&& [[ "${pid[$j,1]}" -ne 0 ]];
		then
			pid[$j,$o]=${pid[$k,0]}
			ppid[$j,$o]=${ppid[$k,0]}
			name[$j,$o]=${name[$k,0]}
			thre[$j,$o]=${thre[$k,0]}
			stat[$j,$o]=${stat[$k,0]}
			opnd[$j,$o]=${opnd[$k,0]}

			pid[$k,0]=-1
			o=$(($o+1))
		fi
	done		
done

line=$(tput lines)
tput cup $line 0
printf "%s" "PID"
tput cup $line 6
printf "%s" "PPID"
tput cup $line 12 
printf "%4s" "THRS"
tput cup $line 18
printf "%3s" "STA"
tput cup $line 23
printf "%6s" "OPND-F"
tput cup $line 29
printf "%12s" "NAME"

a=0
while [[ ${pid[$a,0]} -ne 0 ]]
do

	line=$(tput lines)
	b=1
	if [[ "${pid[$a,$b]}" -gt "0" ]]    
	then
		tput cup $line 0
		printf "\n%4d" "${pid[$a,0]}"
		tput cup $line 6
		printf "%4d" "${ppid[$a,0]}"
		tput cup $line 12
		printf "%4d" "${thre[$a,0]}"
		tput cup $line 18
		printf "%3s" "${stat[$a,0]}"
		tput cup $line 22
		printf "%6d" "${opnd[$a,0]}"
		tput cup $line 30
		printf "%11s" "${name[$a,0]}"
	
		while [[ ${pid[$a,$b]} -ne 0 ]]
		do
			tput cup $(($line+$b)) 0
			printf "\n%4d" "${pid[$a,$b]}"
			tput cup $(($line+$b)) 6
			printf "%4d" "${ppid[$a,$b]}"
			tput cup $(($line+$b)) 12
			printf "%4d" "${thre[$a,$b]}"
			tput cup $(($line+$b)) 18
			printf "%3s" "${stat[$a,$b]}"
			tput cup $(($line+$b)) 22
			printf "%6d" "${opnd[$a,$b]}"
			tput cup $(($line+$b)) 31
			printf " \\__ %12s" "${name[$a,$b]}"
			b=$(($b+1))
		done
	fi
	a=$(($a+1))
done
echo ""
exit 0

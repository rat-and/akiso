#!/bin/bash
#trap $(update_width) 28  #doesn't work as it should :(
trap $(end) 2 3

function end {
	tput cup $((3*$chart_height+4))
	tput cnorm
	tput sgr0
	exit 0
}

###ADDS POSTFIX###
function postfix {
	arg1=${1}
	letters=( B KB MB GB )
	current_letter=0
	
	while [ $arg1 -gt 1000 ]; 
	do
		tmp_a=$(( arg1 / 1000 ))
		arg1=$tmp_a
		let "current_letter= $current_letter+1"
	done
	echo -e "$arg1 ${letters[$current_letter]}/s"
	return 0
}

#function update_width {   #doesn't work like it should :(
#	 tput clear 
#	 echo "terminal_width=$(tput cols)"
#}

###REFRESHES CHART AREA###
function redraw_chart {
	for j in $(seq 0 11)
		do
			tput cup $(($1 - $j)) $2
			if [[ $3 -ne 0 ]]; then
				tput setab 7
				#tput setaf 
			fi
			tput el
		done
		tput sgr0
	}

function redraw_legend {
	for j in $(seq 0 11)
		do
			tput sgr0
			tput cup $(($1 - $j)) $2
			tput el1
		done
		tput sgr0
	}


###CHEKS IF THE GIVEN PARAMETER IS VALID###
dev=$1
check=0

for installed_dev in $(grep ":" /proc/net/dev | awk '{print $1}' | sed s/://);
do
	if [[ $dev = $installed_dev ]];
	then 
		check=1
		break
	fi
done

if [[ check -eq 0 ]];
then
	echo "Missing argument or device not found. Use one of these:"
	grep ":" /proc/net/dev | awk '{print $1}' | sed s/://
	exit 1
fi

###MAIN###
tput clear
tput cup 0 35
echo "EXPLORER by Andrzej C. Ratajski"
#terminal_width=$(tput cols)  #doesn't work like it should :(
i=0
ii=0
max=1
max_h=1
avg=0
avg_h=0
avg_ac=0
avg_ach=0
chart_height=13
chart_left=19
#let "cycle = $terminal_width"  #doesn't work as it should :(
cycle=65
reversed_colors=$2

received=$(grep ${1} /proc/net/dev | awk '{print $2}')
transmitted=$(grep ${1} /proc/net/dev | awk '{print $10}')
total=$(($received+$transmitted))
sleep 1

while [ 1 ];
do
	tput civis

	###CONNECTION SPEED###
	received_new=$(grep ${1} /proc/net/dev | awk '{print $2}')
	transmitted_new=$(grep ${1} /proc/net/dev | awk '{print $10}')
	total_new=$(($received_new+$transmitted_new))
	speed=$(($total_new - $total))
	rec[$i]=$(($speed  * 100))
	if [ $(($total_new-$total)) -gt $max ]; then	
		max=$(($total_new-$total+1))
		echo $(redraw_chart $chart_height $chart_left)
		if [[ $max -gt $max_h ]]; then
			let "max_h = $max"
		fi
	fi
	maxi=0 #$(( max / 2 ))

	###CPU LOAD###
	cpu_no=$(lscpu | grep -E '^CPU\(' | awk '{print $2}')
	cpu_load_1m=$(cat /proc/loadavg | awk '{print $1}')
	cpu_load_5m=$(cat /proc/loadavg | awk '{print $2}')
	cpu_load_1m=$(cat /proc/loadavg | awk '{print $3}')
	cpu_prc_f=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage }')
	cpu_prc_2f=$(echo $cpu_prc_f | awk '{printf("%.2f", $1)}')
	cpu_prc=$(echo $cpu_prc_f | awk '{printf("%.0f", $1)}')
	usg[$i]=$cpu_prc

	###MEMORY USAGE###
	#mem_tot=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
	#mem_ava=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}') 
	#mem_fre=$(grep "MemFree" /proc/meminfo | awk '{print $2}') 
	#mem_cah=$(grep "Cached" /proc/meminfo | awk '{print $2}') 

	###BATTERY CAPACITY###
	bty_s=$(grep "CAPACITY=" /sys/class/power_supply/BAT0/uevent | awk '{print $1}')
	bty=${bty_s##*=}
	cap[$i]=$bty

	###UPTIME###
	ti=$(cat /proc/uptime | awk '{print $1}')
	tim=$(echo $ti | awk '{printf("%.0f", $1)}')
	tim_m=$((tim / 60))
	tim_h=$((tim_m / 60))
        tim_s=$(($tim-60*$tim_m))
	let "tim_m = $tim_m - 60*$tim_h"

	if [[ $2 -ne 0 ]]; then
		echo $(redraw_chart $chart_height $chart_left $reversed_colors)
		echo $(redraw_chart $((2*$chart_height)) $chart_left $reversed_colors)
		echo $(redraw_chart $((3*$chart_height)) $chart_left $reversed_colors)
	fi

	###DRAWING THE CHART###
	for j in $(seq 0 $i) 
	do
		###CONNECTION SPEED CHART###
		ac=$((${rec[$j]}+$maxi))
		acc=$(( ac / max ))
		symbol[$j,0]=$((acc / 9))

		ab=$(($acc-9*${symbol[$j,0]}))
		symbol[$j,1]=$((ab / 6))
		symbol[$j,2]=$((ab % 6))

		for n in $(seq 0 $((${symbol[$j,0]}-1)))  
		do
			if [[ ${symbol[$j,0]} -ne 0 ]]; then
				tput cup $(($chart_height-$n)) $(($chart_left+$j))
				if [[ $2 -ne 0 ]]; then
					tput setab 7
					tput setaf 0 
					tput bold
				fi
				echo "|"
				tput sgr0

			fi	
		done

		if [ ${symbol[$j,1]} -ge 1 ];
		then
			tput cup $(($chart_height-${symbol[$j,0]})) $(($chart_left+$j))
			if [[ $2 -ne 0 ]]; then
				tput setab 7
				tput setaf 0
			       	tput bold
			fi
			echo -e ":";
			tput sgr0

		else
			if [ ${symbol[$j,2]} -gt 0 ] || [ ${symbol[$j,0]} -eq 0 ]
			then
				tput cup $(($chart_height-${symbol[$j,0]})) $(($chart_left+$j)) 
				if [[ $2 -ne 0 ]]; then
					tput setab 7
					tput setaf 0
				        tput bold	
				fi
				echo -e	"."
				tput sgr0
   			fi
		fi

		###CPU USAGE CHART###
		uc=${usg[$j]}
		umbol[$j,0]=$((uc / 9))

		ub=$(($uc-9*${umbol[$j,0]}))
		umbol[$j,1]=$((ub / 6))
		umbol[$j,2]=$((ub % 6))

		for nn in $(seq 0 $((${umbol[$j,0]}-1)))  
		do
			if [ ${umbol[$j,0]} -ne 0 ]; then
				if [[ $2 -ne 0 ]]; then
					tput setab 7
					tput setaf 0 
					tput bold
				fi
				tput cup $((2*$chart_height-$nn)) $(($chart_left+$j))
				echo "|"
				tput sgr0
			fi	
		done

		if [ ${umbol[$j,1]} -ge 1 ];
		then
			tput cup $((2*$chart_height-${umbol[$j,0]})) $(($chart_left+$j))
			if [[ $2 -ne 0 ]]; then
				tput setab 7
				tput setaf 0
			       	tput bold
			fi
			echo -e ":";
			tput sgr0
		else
			if [ ${umbol[$j,2]} -gt 0 ] || [ ${umbol[$j,0]} -eq 0 ]
			then
				tput cup $((2*$chart_height-${umbol[$j,0]})) $(($chart_left+$j)) 
				if [[ $2 -ne 0 ]]; then
					tput setab 7
					tput setaf 0
				        tput bold	
				fi
				echo -e	"."
				tput sgr0
			fi
		fi

		###BATTERY CAPACITY CHART###
		cc=${cap[$j]}
		cbol[$j,0]=$((cc / 9))

		cb=$(($cc-9*${cbol[$j,0]}))
		cbol[$j,1]=$((cb / 6))
		cbol[$j,2]=$((cb % 6))

		for nn in $(seq 0 $((${cbol[$j,0]}-1)))  
		do
			if [ ${cbol[$j,0]} -ne 0 ]; then
				if [[ $2 -ne 0 ]]; then
					tput setab 7
					tput setaf 0 
					tput bold
				fi
				tput cup $((3*$chart_height-$nn)) $(($chart_left+$j))
				echo "|"
				tput sgr0
			fi	
		done

		if [ ${cbol[$j,1]} -ge 1 ];
		then
			tput cup $((3*$chart_height-${cbol[$j,0]})) $(($chart_left+$j))
			if [[ $2 -ne 0 ]]; then
				tput setab 7
				tput setaf 0
			       	tput bold
			fi
			echo -e ":";
			tput sgr0
		else
			if [ ${cbol[$j,2]} -gt 0 ] || [ ${cbol[$j,0]} -eq 0 ] 
			then
				tput cup $((3*$chart_height-${cbol[$j,0]})) $(($chart_left+$j)) 
				if [[ $2 -ne 0 ]]; then
					tput setab 7
					tput setaf 0
				        tput bold	
				fi
				echo -e	"."
				tput sgr0
				
			fi
		fi

		tput cup 0 35
		tput sgr0
		echo "EXPLORER by Andrzej C. Ratajski"
	done	       

	let "avg_ac = $(($avg_ac + $speed))"
	let "avg_ach = $(($avg_ach + $speed))"
	let "avg = $(echo "$avg_ac / ($i+1) | bc" )"
	let "avg_h = $(echo "$avg_ach / ($ii+1) | bc" )"

	###DISPLAYING VALUES###
	echo $(redraw_legend $chart_height $(($chart_left-1)))
	tput cup 2 0
	echo $dev
	tput cup 4 0
	echo "current:"
	tput cup 5 0
	echo -en "speed: $(postfix $speed)"
	tput cup 6 0
	echo -en "max: $(postfix $max)"
	tput cup 7 0
	echo -en "avg: $(postfix $avg)"
	tput cup 9 0
	echo "historical:"
	tput cup 10 0
	echo -en "max: $(postfix $max_h)"
	tput cup 11 0
	echo -en "avg: $(postfix $avg_h)"
	echo $(redraw_legend $((2*$chart_height)) $(($chart_left-1)))
	tput cup $(($chart_height+3)) 0 	
	echo "CPU"
	tput cup $(($chart_height+5)) 0
	echo -en "usage: ${cpu_prc_2f}%"
	tput cup $(($chart_height+7)) 0
	echo "avg load"
	tput cup $(($chart_height+8)) 0
	echo -en "1m: ${cpu_load_1m}/${cpu_no}"
	tput cup $(($chart_height+9)) 0
	echo -en "5m: ${cpu_load_5m}/${cpu_no}"
	tput cup $(($chart_height+10)) 0
	echo -en "10m: ${cpu_load_1m}/${cpu_no}"
	echo $(redraw_legend $((3*$chart_height)) $(($chart_left-1)))
	tput cup $((2*$chart_height+4))
	echo "battery"
	tput cup $((2*$chart_height+6)) 0
	echo -en "capacity: ${bty}%"
	tput cup $((3*$chart_height+3)) 0
	echo -en "System has been up ${tim_h}h ${tim_m}m ${tim_s}s "
	tput cup $((3*$chart_height+4)) 0
	echo -en "Tip: In order to start explorer with white background put <1> as second parameter "


	###UPDATING AND INCREMENTING VALUES###
	received=$(grep ${1} /proc/net/dev | awk '{print $2}')
	transmitted=$(grep ${1} /proc/net/dev | awk '{print $10}')
	total=$(($received+$transmitted))


	let "i = $i +1"	
	let "ii = $ii + 1"		
	
	if [ "$i" -gt "$cycle" ]; then     
		i=0
		let "tmp = $((max / 2))"
		let "max = $(($tmp + 1))"
		avg_ac=0
		echo $(redraw_chart $chart_height $chart_left $reversed_colors)
		echo $(redraw_chart $((2*$chart_height+1)) $chart_left $reversed_colors)
		echo $(redraw_chart $((3*$chart_height+1)) $chart_left $reversed_colors)

	fi
	sleep 1
done

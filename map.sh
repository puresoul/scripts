#!/bin/bash


tree() {
cat <<EOF
custom,tree$4,default,$5,$5,$5,0,1,1,1,1.0,1.0,$1,40,$2,0,1,0,$3;
EOF
}

titan() {
cat <<EOF
photon,spawnTitan,30,0,$1,-0.4625661,$2,0,0.2089859,0,0.9779187;
EOF
}

rand() {
echo $((`echo $1 | cut -c1`+`echo $1 | cut -c2`+`echo $1 | cut -c3`))
}


w=1
x=580

for m in `seq 1 9`; do
	y=-650

	for t in `seq 1 10`; do

		tmp=`rand $RANDOM`
		let y=y+120-$tmp

		if [[ "$(($t % 2))" == "0" ]]; then
			tree $(($x+$tmp)) $y "0.$RANDOM" 2 "1.$RANDOM"
		else
			tree $(($x+$tmp)) $y "-0.$RANDOM" 5 "1.$RANDOM"
		fi

		if [[ "$w" == "$t" || "$t" == "4" ]]; then
			titan "$(($tmp-20))" "$(($y-20))"
		fi

	done

	let w=w+1
	let x=x-150

done
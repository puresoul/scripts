package main

import (
	"fmt"
	"os/exec"
	"os"
)

func main() {

arg := os.Args[1]

cmdOut, err := exec.Command("ls", "-lh", "/").Output()

if err != nil {
    os.Exit(1)
}

out := string(cmdOut)
Var := 1

Wr := len(arg)-1

for Var < len(out)+1 {
    Chr := out[Var-1:Var]

    if Var+Wr > len(out) {
	Is := (Var+Wr)-len(out)
	Wr = Is
    }

    if Chr == arg[0:1] {
	word := os.Args[1]
	Ch := 1
	Ok := 1
	ret := 0
	
	for Ch < len(out[Var-1:Var+Wr])+1 {
	    W := out[Var-1:Var+Wr]
	    C := word[Ch-1:Ch]
	    
	    if W[Ch-1:Ch] == C {
		Ok = Ok+1
	    } 
	    Ch = Ch+1
	}
	
	if Ok == len(out[Var-1:Var+Wr])+1 {
	    ret = 1
	}
	
	if ret == 1 {
	    fmt.Print(os.Args[2])
	    Var = Var+Wr+1
	    continue
	}
    }

    fmt.Print(Chr)
    Var = Var+1
}
}
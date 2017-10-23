package main

import (
	"fmt"
	"os"
	"bufio"
)

func Find(Out string,In string) int {
var Char int = 1
var Oth int = 1
var Ok int = 1
var Var int = 1
for Char < len(Out) {
    if Out[Char-1:Char] == In[Oth-1:Oth] {
		Oth++
		Ok++
    } else {
		Oth = 1
		Ok = 1
    }
    if Ok == len(In) {
		Var = Char+1
		Oth = 1
		Ok = 1
		break
    }
    Char++
	fmt.Print(string(Out[Char]),"[",Char,"]")
}
return Var
}


func main() {
StartArg := os.Args[1]
EndArg := os.Args[2]

scanner := bufio.NewScanner(os.Stdin)

var Out string
for scanner.Scan() {
	//fmt.Println(scanner.Text())
	Out = Out + scanner.Text() + "\n"
}

var StrEn int
var StrSt int

StrSt = Find(Out,StartArg)
StrEn = Find(Out,EndArg)-len(EndArg)

fmt.Println(StrSt,StrEn)

//fmt.Print(Out[])
}


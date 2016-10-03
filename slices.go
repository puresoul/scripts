package main

import (
    "fmt"
    "log"
    "os/exec"
    "os"
    "reflect"
    "unsafe"
)

func BytesToString(b []byte) string {
    bh := (*reflect.SliceHeader)(unsafe.Pointer(&b))
    sh := reflect.StringHeader{bh.Data, bh.Len}
    return *(*string)(unsafe.Pointer(&sh))
}

func main() {
    arg := os.Args[1]
    out, err := exec.Command(arg).Output()
    if err != nil {
	log.Fatal(err)
    }

    sum := 1
    str := BytesToString(out)
    L := len(str)


    sum = 1
    S := []string{}

    for  L > sum{
	b := str[sum-1:sum]
	if b == "\n" {
	    S = join(S)
	    fmt.Printf("%s\n",S[0:])
	    S = []string{}
	} else {
	    S = append(S, b)
	}
	sum += 1
    }

}

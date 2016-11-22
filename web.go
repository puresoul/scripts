package main

import (
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "text/template"
    "strings"
)

func main() {
    res, err := http.Get("http://www.google.com/")
    if err != nil {
	log.Fatal(err)
    }
    robots, err := ioutil.ReadAll(res.Body)
    res.Body.Close()
    if err != nil {
	log.Fatal(err)
    }
    //req := template.URLQueryEscaper(string(robots))
    req := template.JSEscapeString(string(robots)) //template.HTMLEscapeString(string(robots))
    words := strings.Fields(req)
    for i, word := range words {
	fmt.Println(i,template.URLQueryEscaper(word))
    }

    //fmt.Printf("%s", req)
}

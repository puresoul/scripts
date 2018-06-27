package main

import (
	"fmt"
	"golang.org/x/net/html"
	"net/http"
	"os"
	"io/ioutil"
	"regexp"
	"strings"
	"strconv"
	"github.com/grokify/html-strip-tags-go" 
)

type Contact struct {
	Name string
	Address []string
	Telephone []string
}

// Extract all http** links from a given webpage
func crawl(url string, ch chan string, chFinished chan bool) {
	resp, err := http.Get(url)

	defer func() {
	// Notify that we're done after this function
	chFinished <- true
	}()

	if err != nil {
	fmt.Println("ERROR: Failed to crawl \"" + url + "\"")
	return
	}

	b := resp.Body
	defer b.Close() // close Body when the function returns

	z := html.NewTokenizer(b)

	for {
	tt := z.Next()

	switch {
	case tt == html.ErrorToken:
		// End of the document, we're done
		return
	case tt == html.StartTagToken:
		t := z.Token()

		// Check if the token is an <a> tag
		isAnchor := t.Data == "a"
		if !isAnchor {		continue
		}

		var url string

		// Extract the href value, if there is one
		for _, a := range t.Attr {
		if a.Key == "href" {
			url = a.Val
			break
		}
		}

		if len(string(url)) > 8 {
			if string(url)[:7] == "/detail" {
				ch <- strings.Replace(url, "#akce", "", -1)
			}
		}
	}
	}
}

func getBody(url string) []string {
	var list []string
	resp, _ := http.Get(url)
	b := resp.Body
	defer b.Close() // close Body when the function returns

	body, _ := ioutil.ReadAll(b)
	add := regexp.MustCompile("<div itemprop=\"(streetAddress|postalCode)\">(.|\n)*?</div>")
	tel := regexp.MustCompile("<span data-dot=\"origin-phone-number\">(.|\n)*?</span>")
	tit := regexp.MustCompile("<title>(.|\n)*?</title>")
	address := add.FindAllString(string(body), -1)
	telephone := tel.FindAllString(string(body), -1)
	title := tit.FindAllString(string(body), -1)
	
	for _, titl := range title {
		if strings.Contains(titl, "Katalog firem a institucí") {
			continue
		}
		list = append(list, strip.StripTags(strings.Replace(titl, " • Firmy.cz", "", -1)))
		break
	}
	
	for _, adrs := range address {
		list = append(list, strip.StripTags(adrs))
		break
	}
				
	for _, tele := range telephone {
		list = append(list, strip.StripTags(tele))
	}
	
	return list
}

func getMax(url string) int {
	resp, _ := http.Get(url)
	b := resp.Body
	defer b.Close() // close Body when the function returns

	body, _ := ioutil.ReadAll(b)
	ma := regexp.MustCompile("<strong>1.*?</strong>")
	max := ma.FindAllString(string(body), -1)

	var i string
	for _, m := range max {
		i = m
	}

	t := strings.Split(i, "–")
	y := strings.Split(t[1], "<")
	x, _ := strconv.Atoi(y[0])

	return x
}

func getUrls(seedUrls []string) (map[string]bool) {

	foundUrls := make(map[string]bool)
	chFinished := make(chan bool)
	chUrls := make(chan string)

	for _, url := range seedUrls {
		go crawl(url, chUrls, chFinished)
	}
	
	for c := 0; c < len(seedUrls); {
		select {
		case url := <-chUrls:
			foundUrls[url] = true
		case <-chFinished:
			c++
		}
	}

	close(chUrls)
	return foundUrls
}

func main() {

	var node []Contact

	fragment := "?_escaped_fragment_=1"
	var seedUrls []string

	arg := os.Args[1:]
	seedUrls = append(seedUrls, "https://www.firmy.cz/"+arg[0]+fragment+"&page=1")

	c := 1
	seedUrls = nil

	for c < getMax("https://www.firmy.cz/"+arg[0]+fragment)  {
		seedUrls = append(seedUrls, "https://www.firmy.cz/"+arg[0]+fragment+"&page="+strconv.Itoa(c))
		c++
		break
	}

	foundUrls := getUrls(seedUrls)

	for url := range foundUrls {
		tmp := getBody("https://www.firmy.cz"+url+fragment)
		if tmp != nil {
			var nam string
			var num,adr []string
			i := 0
			for i != len(tmp) {
				if i >= 2 {
					num = append(num, tmp[i])
					i++
					continue
				}
				if ( i > 0) {
					adr = append(adr, tmp[i])
				}
				if i == 0 {
					t := strings.Split(tmp[i], "(")
					y := strings.Split(t[1], ")")
					nam = strings.TrimSpace(t[0])
					adr = append(adr, y[0])
				}
				num = nil
				i++
			}
			node = append(node, Contact{Name: nam, Address: adr, Telephone: num})
		}
	}

	fmt.Println(node)

}
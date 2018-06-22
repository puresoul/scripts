package main

import (
    "fmt"
    "golang.org/x/net/html"
    "net/http"
    "os"
)


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
	    if !isAnchor {
		continue
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
		    ch <- url
		}
	    }
	}
    }
}


func getBody(url string) {
	resp, _ := http.Get(url)

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
		    d := z.Token()
		    fmt.Println(d.Attr[1])
		    break
	    }
	}
}

func main() {
    foundUrls := make(map[string]bool)
    seedUrls := os.Args[1:]

    // Channels
    chUrls := make(chan string)
    chFinished := make(chan bool) 

    // Kick off the crawl process (concurrently)
    for _, url := range seedUrls {
	go crawl(url, chUrls, chFinished)
    }

    // Subscribe to both channels
    for c := 0; c < len(seedUrls); {
	select {
	case url := <-chUrls:
	    foundUrls[url] = true
	case <-chFinished:
	    c++
	}
    }

    // We're done! Print the results...

    fmt.Println("\nFound", len(foundUrls), "unique urls:\n")

    for url, _ := range foundUrls {
	getBody("https://www.firmy.cz"+url+"?_escaped_fragment_=1")
    }

    close(chUrls)
}
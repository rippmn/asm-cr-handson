package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	// register hello function to handle all requests
	mux := http.NewServeMux()
	mux.HandleFunc("/", hello)

	// use PORT environment variable, or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// start the web server on port and accept requests
	log.Printf("Server listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}

// hello responds to the request with a plain-text "Hello, world" message.
func hello(w http.ResponseWriter, r *http.Request) {
	log.Printf("Serving request: %s", r.URL.Path)
	time.Sleep(500 * time.Millisecond)
	host, _ := os.Hostname()
	fmt.Fprintf(w, "<html><body style=\"background:purple\"><div style=\"text-align: center;color: white;font: 15px Arial;font-size: 200%\"><h1>Hello</h1><br/>")
	fmt.Fprintf(w, "Version: 3.0.0<br/>")
	fmt.Fprintf(w, "Hostname: %s<br/>", host)
	fmt.Fprintf(w, "Time: %s<br/>", time.Now().Format("Mon Jan _2 2006 15:04:05"))
	fmt.Fprintf(w, "</div></body></html>")

}



package main

import (
    "github.com/rackspace/gophercloud"
    "os"
)

func main() {
    var provider = os.Getenv("OS_AUTH_URL") + "/v2.0/tokens"
    var username = os.Getenv("RAX_USERNAME")
    var api_key = os.Getenv("RAX_API_KEY")
    _, err := gophercloud.Authenticate(
        provider,
        gophercloud.AuthOptions{
            Username: username,
            ApiKey: api_key,
        },
    )
    if err != nil {
        panic(err)
    }
    println("Authenticated")
}
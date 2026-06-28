package scoreboard

import "core:fmt"
import "http:client"
import "core:os"
import "../error"
import "core:encoding/json"

Score :: struct {
	id: int,
	score: i64,
	name: string,
	timestamp: i64,
	time: string,
	version: string,
}

Scoreboard :: [dynamic]Score

// basic get request.
get :: proc() -> (board: Scoreboard, getErr: error.Error) {
	board = Scoreboard{}

	url, found := os.lookup_env_alloc("SERVER_URL", context.temp_allocator)
	if !found {
		fmt.printf("Failed to find server url")
		return board, .No_Server_URL
	}

	res, err := client.get(fmt.tprintf("%s/api/v1/score", url))
	if err != nil {
		fmt.printf("Request failed: %s", err)
		return board, .Request_Failed
	}
	defer client.response_destroy(&res)

	body, allocation, berr := client.response_body(&res)
	if berr != nil {
		fmt.printf("Error retrieving response body: %s", berr)
		return board, .Bad_Body
	}
	defer client.body_destroy(body, allocation)

    text := body.(string)    
	fmt.printf("Parsing: %s", text)
	if jerr := json.unmarshal_string(text, &board); jerr != nil {
		fmt.printfln("JSON error: %v", jerr)   // %v, not %s — it's a union
		return board, .Bad_JSON
	}

	return board, .None
}

Post_Body :: struct {
	name:    string,
	message: string,
}


// POST request with JSON.
post :: proc(payload: Score) -> (board: Scoreboard, getErr: error.Error) {
	board = Scoreboard{}

	url, found := os.lookup_env_alloc("SERVER_URL", context.temp_allocator)
	if !found {
		fmt.printf("Failed to find server url")
		return board, .No_Server_URL
	}

	req: client.Request
	client.request_init(&req, .Post)
	defer client.request_destroy(&req)

	if err := client.with_json(&req, payload); err != nil {
		fmt.printf("JSON error: %s", err)
		return board, .Bad_JSON
	}

	res, err := client.request(&req, fmt.tprintf("%s/api/v1/score", url))
	if err != nil {
		fmt.printf("Request failed: %s", err)
		return board, .Request_Failed
	}
	defer client.response_destroy(&res)

	fmt.printf("Status: %s\n", res.status)
	fmt.printf("Headers: %v\n", res.headers)
	fmt.printf("Cookies: %v\n", res.cookies)

	body, allocation, berr := client.response_body(&res)
	if berr != nil {
		fmt.printf("Error retrieving response body: %s", berr)
		return board, .Bad_Body
	}
	defer client.body_destroy(body, allocation)

	fmt.println(body)

	return
}
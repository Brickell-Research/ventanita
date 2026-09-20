import gleam/http/response
import ventanita/anthropic/client
import ventanita/anthropic/error
import ventanita/anthropic/request

pub fn build_request_test() {
  let req = client.build_request("sk-test", request.new("m", 1))

  assert req.host == "api.anthropic.com"
  assert req.path == "/v1/messages"
  assert req.headers
    == [
      #("x-api-key", "sk-test"),
      #("anthropic-version", "2023-06-01"),
      #("content-type", "application/json"),
    ]
}

pub fn parse_api_error_test() {
  let body =
    "{\"type\":\"error\",\"error\":{\"type\":\"rate_limit_error\",\"message\":\"slow down\"}}"

  let parsed =
    response.new(429)
    |> response.set_body(body)
    |> client.parse_response

  assert parsed == Error(error.Api(429, "rate_limit_error", "slow down"))
}

pub fn parse_non_json_error_test() {
  let parsed =
    response.new(502)
    |> response.set_body("<html>bad gateway</html>")
    |> client.parse_response

  assert parsed == Error(error.Api(502, "unknown", "<html>bad gateway</html>"))
}

pub fn parse_undecodable_success_test() {
  let assert Error(error.Decode(_)) =
    response.new(200)
    |> response.set_body("not json")
    |> client.parse_response
}

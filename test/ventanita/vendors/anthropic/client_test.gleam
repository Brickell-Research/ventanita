import gleam/http/response
import gleeunit/should
import ventanita/vendors/anthropic/client
import ventanita/vendors/anthropic/error
import ventanita/vendors/anthropic/request

pub fn build_request_test() {
  let req = client.build_request("sk-test", request.new("m", 1))

  should.equal(req.host, "api.anthropic.com")
  should.equal(req.path, "/v1/messages")
  should.equal(req.headers, [
    #("x-api-key", "sk-test"),
    #("anthropic-version", "2023-06-01"),
    #("content-type", "application/json"),
  ])
}

pub fn parse_api_error_test() {
  let body =
    "{\"type\":\"error\",\"error\":{\"type\":\"rate_limit_error\",\"message\":\"slow down\"}}"

  response.new(429)
  |> response.set_body(body)
  |> client.parse_response
  |> should.equal(Error(error.Api(429, "rate_limit_error", "slow down")))
}

pub fn parse_non_json_error_test() {
  response.new(502)
  |> response.set_body("<html>bad gateway</html>")
  |> client.parse_response
  |> should.equal(Error(error.Api(502, "unknown", "<html>bad gateway</html>")))
}

pub fn parse_undecodable_success_test() {
  let assert Error(error.Decode(_)) =
    response.new(200)
    |> response.set_body("not json")
    |> client.parse_response
}

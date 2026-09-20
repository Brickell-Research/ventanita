//// Minimal, non-streaming client for the Anthropic Messages API.
////
//// Request building and response parsing are pure so they can be tested
//// without network access; `send` glues them to `gleam_httpc`.

import gleam/http
import gleam/http/request as http_request
import gleam/http/response.{type Response as HttpResponse}
import gleam/httpc
import gleam/json
import gleam/result
import ventanita/anthropic/error.{type Error}
import ventanita/anthropic/request.{type Request}
import ventanita/anthropic/response as api_response

const api_version = "2023-06-01"

const timeout_ms = 120_000

pub fn send(
  api_key: String,
  req: Request,
) -> Result(api_response.Response, Error) {
  httpc.configure()
  |> httpc.timeout(timeout_ms)
  |> httpc.dispatch(build_request(api_key, req))
  |> result.map_error(error.Http)
  |> result.try(parse_response)
}

pub fn build_request(
  api_key: String,
  req: Request,
) -> http_request.Request(String) {
  http_request.new()
  |> http_request.set_method(http.Post)
  |> http_request.set_scheme(http.Https)
  |> http_request.set_host("api.anthropic.com")
  |> http_request.set_path("/v1/messages")
  |> http_request.set_header("x-api-key", api_key)
  |> http_request.set_header("anthropic-version", api_version)
  |> http_request.set_header("content-type", "application/json")
  |> http_request.set_body(json.to_string(request.to_json(req)))
}

pub fn parse_response(
  resp: HttpResponse(String),
) -> Result(api_response.Response, Error) {
  case resp.status >= 200 && resp.status < 300 {
    True ->
      api_response.from_json(resp.body)
      |> result.map_error(error.Decode)
    False -> Error(error.from_api_response(resp.status, resp.body))
  }
}

import gleam/httpc
import gleam/json
import gleam/string
import ventanita/anthropic/error

pub fn api_error_to_string_test() {
  assert error.to_string(error.Api(
      401,
      "authentication_error",
      "invalid x-api-key",
    ))
    == "Anthropic API error 401 (authentication_error): invalid x-api-key"
}

pub fn http_error_to_string_test() {
  let message = error.to_string(error.Http(httpc.ResponseTimeout))

  assert string.starts_with(message, "HTTP error: ")
  assert string.contains(message, "ResponseTimeout")
}

pub fn decode_error_to_string_test() {
  let message = error.to_string(error.Decode(json.UnexpectedByte("x")))

  assert string.starts_with(message, "could not decode response: ")
  assert string.contains(message, "UnexpectedByte")
}

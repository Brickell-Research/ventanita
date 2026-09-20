import gleeunit/should
import ventanita/vendors/anthropic/error

pub fn api_error_to_string_test() {
  error.Api(401, "authentication_error", "invalid x-api-key")
  |> error.to_string
  |> should.equal(
    "Anthropic API error 401 (authentication_error): invalid x-api-key",
  )
}

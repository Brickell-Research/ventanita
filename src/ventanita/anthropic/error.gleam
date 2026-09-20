//// Everything that can go wrong talking to the Messages API.

import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string

pub type Error {
  Http(httpc.HttpError)
  /// The API answered with a non-2xx status.
  Api(status: Int, kind: String, message: String)
  Decode(json.DecodeError)
}

/// Builds an `Api` error from a non-2xx response body.
pub fn from_api_response(status: Int, body: String) -> Error {
  let decoder = {
    use kind <- decode.subfield(["error", "type"], decode.string)
    use message <- decode.subfield(["error", "message"], decode.string)
    decode.success(Api(status, kind, message))
  }
  // Fall back to the raw body for non-standard errors (e.g. a proxy page).
  json.parse(body, decoder) |> result.unwrap(Api(status, "unknown", body))
}

/// A human-readable description, suitable for showing to the user.
pub fn to_string(error: Error) -> String {
  case error {
    Api(status, kind, message) ->
      "Anthropic API error "
      <> int.to_string(status)
      <> " ("
      <> kind
      <> "): "
      <> message
    Http(error) -> "HTTP error: " <> string.inspect(error)
    Decode(error) -> "could not decode response: " <> string.inspect(error)
  }
}

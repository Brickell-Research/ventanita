import ventanita/vendors/anthropic/models.{type Model}

pub type AgentConfig {
  AgentConfig(max_tokens: Int, anthropic_api_key: String, model: Model)
}

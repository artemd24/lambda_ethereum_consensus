# General application configuration
import Config

# Configure fork
# Available: "deneb"
# Used only for testing

fork_raw = File.read!(".fork_version") |> String.trim()

fork =
  case fork_raw do
    "deneb" -> :deneb
    v -> raise "Invalid fork specified: #{v}"
  end

IO.puts("compilation done for fork: #{fork_raw}")

config :lambda_ethereum_consensus, :fork, fork

# Configure logging
config :logger, level: :info, truncate: :infinity

config :lambda_ethereum_consensus, LambdaEthereumConsensus.Telemetry, enable: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures the phoenix endpoint
config :lambda_ethereum_consensus, BeaconApi.Endpoint,
  http: [port: 4000],
  url: [host: "localhost"],
  render_errors: [
    formats: [json: BeaconApi.ErrorJSON],
    layout: false
  ]

# Load minimal config by default, to allow schema checking
config :lambda_ethereum_consensus, ChainSpec,
  config: MinimalConfig,
  genesis_validators_root: <<0::256>>

# Configure sentry logger handler
# To enable sentry, set the SENTRY_DSN environment variable to the DSN of your sentry project
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

config :lambda_ethereum_consensus, :logger, [
  {:handler, :sentry_handler, Sentry.LoggerHandler,
   %{
     config: %{
       metadata: [:file, :line, :slot],
       capture_log_messages: true
     }
   }}
]

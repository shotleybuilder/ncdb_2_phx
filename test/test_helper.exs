# Start the application and its dependencies
{:ok, _} = Application.ensure_all_started(:ncdb_2_phx)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(NCDB2Phx.Repo, :manual)

# Load test support files
Code.require_file("support/test_helpers.ex", __DIR__)
Code.require_file("support/data_case.ex", __DIR__)
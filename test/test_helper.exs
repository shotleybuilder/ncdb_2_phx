# Start the application and its dependencies
{:ok, _} = Application.ensure_all_started(:ncdb_2_phx)

# Load test support files first 
Code.require_file("support/repo.ex", __DIR__)
Code.require_file("support/test_adapter.ex", __DIR__)
Code.require_file("support/test_resource.ex", __DIR__)

# Start the test repo
{:ok, _} = NCDB2Phx.TestRepo.start_link()

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(NCDB2Phx.TestRepo, :manual)

# Load test support files
Code.require_file("support/test_helpers.ex", __DIR__)
Code.require_file("support/data_case.ex", __DIR__)
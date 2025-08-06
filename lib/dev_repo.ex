defmodule NCDB2Phx.DevRepo do
  @moduledoc """
  Development-only Ecto repository for NCDB2Phx.
  
  This repo is only used for development. Host applications should 
  configure their own repo for NCDB2Phx resources in production.
  """
  
  use AshPostgres.Repo, 
    otp_app: :ncdb_2_phx,
    warn_on_missing_ash_functions?: false
  
  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
  
  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions"]
  end
end
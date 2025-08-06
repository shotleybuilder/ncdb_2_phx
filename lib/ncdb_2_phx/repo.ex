defmodule NCDB2Phx.Repo do
  @moduledoc """
  Ecto repository for NCDB2Phx.
  
  This repo is primarily used for testing and development. In production,
  host applications should configure their own repo for NCDB2Phx resources.
  """
  
  use AshPostgres.Repo, otp_app: :ncdb_2_phx
  
  def installed_extensions do
    ["uuid-ossp", "citext"]
  end
end
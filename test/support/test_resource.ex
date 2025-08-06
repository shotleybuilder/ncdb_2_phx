defmodule NCDB2Phx.TestResource do
  @moduledoc """
  Test resource for sync engine testing.
  
  This is a simple test resource that can be used as a target
  for sync operations in tests without requiring complex setup.
  """
  
  use Ash.Resource,
    domain: nil,
    data_layer: AshPostgres.DataLayer
  
  postgres do
    table "test_records"
    if Mix.env() in [:test, :dev] do
      repo NCDB2Phx.TestRepo
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :value, :string
    attribute :external_id, :integer
    attribute :metadata, :map, default: %{}
    
    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    
    create :upsert do
      argument :external_id, :integer, allow_nil?: false
      upsert? true
      upsert_identity :external_id
    end
  end

  identities do
    identity :external_id, [:external_id]
  end

  validations do
    validate present(:name)
  end
end
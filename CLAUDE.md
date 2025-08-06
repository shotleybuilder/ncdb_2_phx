# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NCDB2Phx is a comprehensive, production-ready sync engine for Phoenix applications using Ash Framework. It enables importing data from no-code databases (Airtable, Baserow, Notion) and other sources (CSV, APIs, databases) with real-time progress tracking, error handling, and LiveView admin interface.

The codebase is a **package/library** designed to be integrated into other Phoenix applications, not a standalone application.

## Development Commands

### Setup and Dependencies
```bash
# Initial setup
mix deps.get

# Database operations
mix ecto.create         # Create database
mix ash.codegen --dev   # Generate dev migrations during development
mix ash.migrate         # Apply migrations (standard Ash command, not ecto.migrate)

# Production workflow:
# 1. Make resource changes
# 2. mix ash.codegen --dev (generates dev migrations)
# 3. mix ash.migrate (applies migrations)  
# 4. When ready: mix ash.codegen migration_name (creates named migration)
# 5. mix ash.migrate (applies final migration)
```

### Testing
```bash
# Run all tests (includes database setup)
mix test

# Run with coverage
mix coveralls

# Run coverage with HTML report
mix coveralls.html

# Run specific test file
mix test test/ncdb_2_phx/sync_engine_test.exs
```

### Code Quality
```bash
# Static analysis
mix credo

# Type checking
mix dialyzer

# Documentation generation
mix docs
```

### Asset Management
```bash
# Frontend assets (if applicable)
mix assets.setup     # Install npm dependencies
mix assets.build     # Build assets
mix assets.deploy    # Build and digest assets for production
```

## Architecture Overview

### Core Components

**Main Entry Point**: `NCDB2Phx` module (lib/ncdb_2_phx.ex)
- Primary API for sync operations
- Domain definition with generic sync resources
- High-level sync execution functions

**Sync Engine**: `NCDB2Phx.SyncEngine` (lib/ncdb_2_phx/sync_engine.ex)
- Generic sync orchestration engine with adapter pattern
- Configurable processing pipeline with error handling
- Real-time progress tracking via PubSub
- Supports streaming and batch processing

**Utilities** (lib/ncdb_2_phx/utilities/):
- `SourceAdapter`: Behavior for pluggable data source adapters
- `TargetProcessor`: Generic Ash resource processing
- `ProgressTracker`: Real-time progress monitoring
- `ErrorHandler`: Comprehensive error handling and recovery
- `ConfigValidator`: Configuration validation
- `RecordTransformer` & `RecordValidator`: Data processing

**Generic Resources**:
- `SyncSession`: Track sync operations and lifecycle
- `SyncBatch`: Monitor batch-level progress and performance  
- `SyncLog`: Comprehensive logging for debugging and analytics

### Adapter Pattern

The system uses a pluggable adapter pattern for data sources:
- **Source Adapters**: Connect to external data sources (Airtable, CSV, APIs, etc.)
- **Target Processing**: Generic interface to work with any Ash resource
- **Error Handling**: Configurable error handling and recovery strategies

### Key Design Principles

1. **Zero Host Coupling**: Works with any Ash resource out of the box
2. **Configuration Driven**: All behavior controlled through configuration maps
3. **Pluggable Architecture**: Easy to extend with custom adapters
4. **Resource Agnostic**: Generic sync engine works with any data source/target
5. **Event-Driven**: Real-time progress updates via Phoenix PubSub

## Configuration Structure

Sync operations are configured via comprehensive configuration maps:

```elixir
config = %{
  # Source configuration
  source_adapter: Module,
  source_config: %{},
  
  # Target Ash resource configuration  
  target_resource: Module,
  target_config: %{unique_field: :field_name},
  
  # Processing configuration
  processing_config: %{
    batch_size: 100,
    limit: 1000,
    enable_error_recovery: true,
    enable_progress_tracking: true
  },
  
  # PubSub configuration for real-time updates
  pubsub_config: %{
    module: App.PubSub,
    topic: "sync_progress"
  },
  
  # Session configuration
  session_config: %{
    sync_type: :import_type,
    description: "Sync description"
  }
}
```

## Testing Approach

The project emphasizes comprehensive testing:

- **Unit Tests**: Individual component testing
- **Integration Tests**: Full sync pipeline testing  
- **Test Adapters**: Built-in test adapters for development
- **Mock External Services**: Mock adapters for testing without external dependencies

Use `mix test` to run the full test suite including database setup.

## Error Handling Strategy

Multi-layered error handling:
1. **Configuration Validation**: Validate before execution
2. **Adapter-Level**: Handle connection and data source errors
3. **Record-Level**: Individual record processing errors with recovery
4. **Batch-Level**: Batch processing errors with continuation options
5. **Session-Level**: Overall sync operation error handling

## Development Notes

- **Elixir Version**: ~> 1.16
- **Phoenix**: ~> 1.7.14  
- **Ash Framework**: ~> 3.0
- **Database**: PostgreSQL via AshPostgres ~> 2.0

The codebase follows Elixir/Phoenix conventions and Ash Framework patterns. When extending functionality, maintain the adapter pattern and configuration-driven approach.
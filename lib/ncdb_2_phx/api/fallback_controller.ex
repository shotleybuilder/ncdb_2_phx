defmodule NCDB2Phx.API.FallbackController do
  @moduledoc """
  Fallback controller for handling errors in NCDB2Phx API controllers.
  
  This controller handles common error patterns and converts them to appropriate
  HTTP responses with consistent JSON error formats.
  """
  
  use Phoenix.Controller
  
  require Logger

  @doc """
  Handle Ecto.Changeset errors from validation failures.
  """
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:changeset_error, changeset: changeset)
  end

  @doc """
  Handle not found errors.
  """
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:not_found)
  end

  @doc """
  Handle unauthorized access errors.
  """
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:unauthorized)
  end

  @doc """
  Handle forbidden access errors.
  """
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:forbidden)
  end

  @doc """
  Handle session state errors (e.g., trying to cancel a completed session).
  """
  def call(conn, {:error, :not_cancellable}) do
    conn
    |> put_status(:conflict)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:conflict, %{
      message: "Session cannot be cancelled in its current state",
      code: "not_cancellable"
    })
  end

  def call(conn, {:error, :not_retryable}) do
    conn
    |> put_status(:conflict)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:conflict, %{
      message: "Session cannot be retried in its current state",
      code: "not_retryable"
    })
  end

  @doc """
  Handle timeout errors.
  """
  def call(conn, {:error, :timeout}) do
    conn
    |> put_status(:gateway_timeout)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:timeout)
  end

  @doc """
  Handle rate limiting errors.
  """
  def call(conn, {:error, :rate_limited}) do
    conn
    |> put_status(:too_many_requests)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:rate_limited)
  end

  @doc """
  Handle validation errors with custom messages.
  """
  def call(conn, {:error, :invalid_params, message}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:bad_request, %{message: message})
  end

  @doc """
  Handle generic service errors.
  """
  def call(conn, {:error, :service_error, message}) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:service_error, %{message: message})
  end

  @doc """
  Handle string error messages.
  """
  def call(conn, {:error, message}) when is_binary(message) do
    Logger.error("API Error: #{message}")
    
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:internal_server_error, %{message: message})
  end

  @doc """
  Handle atom error types with generic messages.
  """
  def call(conn, {:error, error_type}) when is_atom(error_type) do
    message = humanize_error_type(error_type)
    
    Logger.error("API Error: #{error_type} - #{message}")
    
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:internal_server_error, %{
      message: message,
      code: error_type
    })
  end

  @doc """
  Handle unexpected errors and exceptions.
  """
  def call(conn, error) do
    Logger.error("Unexpected API Error: #{inspect(error)}")
    
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: NCDB2Phx.API.ErrorJSON)
    |> render(:internal_server_error, %{
      message: "An unexpected error occurred"
    })
  end

  # Private helper functions

  defp humanize_error_type(error_type) do
    case error_type do
      :not_found -> "The requested resource was not found"
      :unauthorized -> "Authentication required"
      :forbidden -> "Access denied"
      :timeout -> "Request timed out"
      :rate_limited -> "Too many requests"
      :service_unavailable -> "Service temporarily unavailable"
      :invalid_configuration -> "Invalid sync configuration"
      :adapter_error -> "Data source adapter error"
      :processing_error -> "Error occurred during processing"
      :database_error -> "Database operation failed"
      :network_error -> "Network communication failed"
      _ -> "An error occurred: #{error_type}"
    end
  end
end

defmodule NCDB2Phx.API.ErrorJSON do
  @moduledoc """
  JSON error views for NCDB2Phx API responses.
  """

  @doc """
  Render changeset validation errors.
  """
  def changeset_error(%{changeset: changeset}) do
    %{
      error: %{
        type: "validation_error",
        message: "Validation failed",
        details: format_changeset_errors(changeset)
      }
    }
  end

  @doc """
  Render not found error.
  """
  def not_found(_assigns) do
    %{
      error: %{
        type: "not_found",
        message: "The requested resource was not found"
      }
    }
  end

  @doc """
  Render unauthorized error.
  """
  def unauthorized(_assigns) do
    %{
      error: %{
        type: "unauthorized",
        message: "Authentication required"
      }
    }
  end

  @doc """
  Render forbidden error.
  """
  def forbidden(_assigns) do
    %{
      error: %{
        type: "forbidden", 
        message: "Access denied"
      }
    }
  end

  @doc """
  Render conflict error with custom message.
  """
  def conflict(%{message: message, code: code}) do
    %{
      error: %{
        type: "conflict",
        code: code,
        message: message
      }
    }
  end

  def conflict(%{message: message}) do
    %{
      error: %{
        type: "conflict",
        message: message
      }
    }
  end

  @doc """
  Render timeout error.
  """
  def timeout(_assigns) do
    %{
      error: %{
        type: "timeout",
        message: "Request timed out"
      }
    }
  end

  @doc """
  Render rate limiting error.
  """
  def rate_limited(_assigns) do
    %{
      error: %{
        type: "rate_limited",
        message: "Too many requests. Please try again later."
      }
    }
  end

  @doc """
  Render bad request error.
  """
  def bad_request(%{message: message}) do
    %{
      error: %{
        type: "bad_request",
        message: message
      }
    }
  end

  @doc """
  Render service error.
  """
  def service_error(%{message: message}) do
    %{
      error: %{
        type: "service_error",
        message: message
      }
    }
  end

  @doc """
  Render internal server error.
  """
  def internal_server_error(%{message: message, code: code}) do
    %{
      error: %{
        type: "internal_server_error",
        code: code,
        message: message
      }
    }
  end

  def internal_server_error(%{message: message}) do
    %{
      error: %{
        type: "internal_server_error",
        message: message
      }
    }
  end

  def internal_server_error(_assigns) do
    %{
      error: %{
        type: "internal_server_error",
        message: "An unexpected error occurred"
      }
    }
  end

  # Private helper functions

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
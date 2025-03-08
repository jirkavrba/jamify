defmodule Jamify.UserIdentifier do
  require Logger

  def create_from_peer_info(peer_info) do
    ip = peer_info.address
    formatted_ip = format_ip(ip)
    country = resolve_country_from_ip(formatted_ip)
    country_emoji = country_code_flag(country)
    id = hash(formatted_ip)

    %{
      id: id,
      country: country,
      country_emoji: country_emoji
    }
  end

  defp format_ip({_, _, _, _} = ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(":")
  end

  defp resolve_country_from_ip(ip) do
    Logger.info("Resolving country from IP: #{ip}")

    result = Req.get("https://api.country.is/#{ip}")

    case result do
      {:ok, %Req.Response{status: 200, body: response}} -> response["country"]
      _ -> "unknown"
    end
  end

  defp country_code_flag("unknown"), do: "🥸"

  defp country_code_flag(code) do
    regional_indicator_unicode = 127_397

    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 + regional_indicator_unicode))
    |> to_string()
  end

  defp hash(ip) do
    :crypto.hash(:md5, ip)
    |> Base.encode16()
  end
end

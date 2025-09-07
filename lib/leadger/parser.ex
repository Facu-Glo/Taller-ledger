defmodule Leadger.Parser do
  
  def decode_csv(path, separator) do
    File.stream!(path)
    |> CSV.decode!(headers: true, separator: separator)
  end

end

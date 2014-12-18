defmodule Bitcoind do
  def main(args) do
    args |> parse_args
  end

  def parse_args(args) do
    options = OptionParser.parse(args, switches: 
                                 [help: :boolean,
                                  parse: :string],
                                  aliases:  [h: :help])
    case options do
      {[help: true], _, _} -> print_help()
      {[parse: file], _, _} -> ParseBlockChain.parse_entire_file(file)
      x -> IO.puts("Unknown argument")
    end
  end

  defp print_help() do
    IO.puts("--help                   This information.")
    IO.puts("--parse=path_to_file     Parses the given blockchain.")
  end
end

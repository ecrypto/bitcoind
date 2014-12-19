defmodule Bitcoind do
  def main(args) do
    args |> parse_args
  end

  def parse_args(args) do
    options = OptionParser.parse(args, switches:
                                 [help: :boolean,
                                  count_blocks: :string,
                                  parse_and_forget: :string],
                                  aliases:  [h: :help])
    case options do
      {[help: true], _, _} -> print_help()
      {[count_blocks: file], _, _} -> ParseBlockChain.walk_entire_file(file, :count)
      {[parse_and_forget: file], _, _} -> ParseBlockChain.walk_entire_file(file, :parse_and_forget)
      x -> IO.puts("Unknown argument")
    end
  end

  defp print_help() do
    IO.puts("--help                              This information.")
    IO.puts("--parse-and-forget=path_to_file     Parse and throw results away.")
    IO.puts("--count-blocks=path_to_file         Count the number of blocks.")
  end
end

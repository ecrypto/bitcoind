defmodule ParseBlockChain do
  @blockchain "/home/nobackup/blockhain/bootstrap.dat"
  @readsize 1000000

  def openblockchain do
    File.open(@blockchain, [:read])
  end

  def parse_entire_file do
    {:ok, file} = openblockchain()
    count_all_blocks(file, <<>>, 0)
    File.close(file)
  end

  def count_all_blocks(file, rest, num_blocks) do
    case parse_next_chunk(file, rest) do
      [] ->
        :done
      {:ok, blocks, rest} ->
        num_blocks = num_blocks + length(blocks)
        IO.puts("Parsed #{num_blocks} blocks...")
        count_all_blocks(file, rest, num_blocks)
    end
  end

  def parse_next_chunk(file, rest) do
    case IO.binread(file, @readsize) do
      :eof ->
        []
      data ->
        parse_available_blocks(<<rest :: binary, data :: binary>>)
    end
  end

  @doc """
  Parse and return all blocks in the given data. Any remaining data
  not representing an entire block is returned as well.
  """
  def parse_available_blocks(data) do
    parse_blocks(data, [])
  end

  defp parse_blocks(data, blocks) do
    res = Parser.get_raw_block(data)
    case res do
      {:ok, block, rest} ->
        {:ok, parsed_block, <<>>} = Parser.parse_block(block)
        #IO.puts("parsed block")
        parse_blocks(rest, [parsed_block | blocks])
      {:error, :incomplete_block, rest} ->
        #IO.puts("incomplete block")
        {:ok, Enum.reverse(blocks), rest}
    end
  end
end

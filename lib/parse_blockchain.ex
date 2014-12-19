defmodule ParseBlockChain do
  @readsize 10000000

  @doc """
  Iterate over a blockchain file and execute the action specified.
  """
  @spec walk_file(String.t, atom) :: {:ok, any}
  def walk_file(bc_file, action) do
    {:ok, file} = File.open(bc_file, [:read])
    res = do_walk_file(file, action)
    File.close(file)
    {:ok, res}
  end

  defp do_walk_file(file, :parse_and_forget) do
    walk_all_blocks(file, <<>>, &parse_and_forget_blocks/2, 0)
  end
  defp do_walk_file(file, :count) do
    walk_all_blocks(file, <<>>, &count_blocks/2, 0)
  end

  defp count_blocks(_raw_block, num_blocks) do
    if rem(num_blocks, 1000) == 0 do
      IO.puts("Counted #{num_blocks} blocks...")
    end
    {:ok, 1 + num_blocks}
  end

  defp parse_and_forget_blocks(raw_block, _) do
    Parser.parse_block(raw_block)
    {:ok, :nothing}
  end

  defp walk_all_blocks(file, rest, block_handler, acc) do
    case get_next_chunk(file) do
      [] ->
        acc
      data ->
        {:ok, acc, rest} = walk_raw_blocks(<<rest :: binary, data :: binary>>, block_handler, acc)
        walk_all_blocks(file, rest, block_handler, acc)
    end
  end

  defp get_next_chunk(file) do
    case IO.binread(file, @readsize) do
      :eof ->
        []
      data ->
        data
    end
  end

  @doc """
  Given some data and a block handler, iterate over the data
  and when done return the accumulator and any remaining data.
  """
  @spec walk_raw_blocks(binary, fun, any) :: {:ok, any, binary}
  def walk_raw_blocks(data, block_handler, acc) do
    case Parser.get_raw_block(data) do
      {:ok, block, rest} ->
        {:ok, acc} = block_handler.(block, acc)
        walk_raw_blocks(rest, block_handler, acc)
      {:error, :incomplete_block, rest} ->
         {:ok, acc, rest}
    end
  end
end

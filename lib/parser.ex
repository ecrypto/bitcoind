
defmodule Block do
  defstruct magic: <<>>, size: <<>>, header: <<>>, tx_counter: 0, transactions: []
end

defmodule BlockHeader do
  defstruct version: <<>>, hash_prev_block: <<>>, hash_merkle_root: <<>>, time: <<>>, bits: <<>>, nonce: <<>>
end

defmodule Tx do
  defstruct version_number: 0, inputs: [], outputs: [], lock_time: 0
end

defmodule Input do
  defstruct tx_hash: <<>>, index: 0, pkScript: <<>>, seq_num: 0
end

defmodule Output do
  defstruct amount: 0, outputScript: <<>>
end

defmodule Parser do
  @moduledoc """
  Parser is a module containing functions used to parse the blockchain.
  """

  @block_hdr_magic_number <<0xf9,0xbe,0xb4,0xd9>>

  @doc """
  Get raw data for next block.
  """
  def get_raw_block(<< @block_hdr_magic_number :: binary,
        size :: little-integer-size(32),
        block :: binary-size(size),
        rest :: binary>>) do
    {:ok, << @block_hdr_magic_number :: binary,
        size :: little-integer-size(32),
        block :: binary>>, rest}
  end
  def get_raw_block(data) do
    {:error, :incomplete_block, data}
  end

  @doc """
  Parse a blockchain block.
  """
  def parse_block(<< @block_hdr_magic_number :: binary,
                  size :: little-integer-size(32),
                  header :: binary-size(80),
                  rest :: binary>>)  do

    {tx_counter, rest} = parse_varint(rest)
    {:ok, header} = parse_block_header(header)

    # Parse all transactions in this block.
    func = fn(data) ->
      {:ok, input, rest} = parse_transaction(data)
      {input, rest}
    end
    {:ok, txs, rest} = iterate_bin_to_list(rest, func, [], tx_counter)

    block = %Block{
              magic: @block_hdr_magic_number,
              size: size,
              header: header,
              tx_counter: tx_counter,
              transactions: txs,
          }
    {:ok, block, rest}
  end

  def parse_block(_) do
    {:error, :invalid_block_magic_number}
  end

  @doc """
  Parse a block header.
  """
  def parse_block_header(
        <<version :: little-integer-size(32),
        hash_prev_block :: binary-size(32),
        hash_merkle_root :: binary-size(32),
        time :: big-integer-size(32),
        bits :: big-integer-size(32),
        nonce :: big-integer-size(32)>>
      ) do
    header = %BlockHeader{
               version: version,
               hash_prev_block: hash_prev_block,
               hash_merkle_root: hash_merkle_root,
               time: time,
               bits: bits,
               nonce: nonce,
           }
    {:ok, header}
  end

  @doc """
  Parse a transaction.
  """
  def parse_transaction(<<version_number :: little-integer-size(32),
                        rest :: binary>>) do
    {:ok, inputs, rest} = parse_inputs(rest)
    {:ok, outputs, rest} = parse_outputs(rest)
    <<lock_time :: little-integer-size(32), rest :: binary>> = rest
    tx = %Tx{
           version_number: version_number,
           inputs: inputs,
           outputs: outputs,
           lock_time: lock_time,
           }
    {:ok, tx, rest}
  end

  @doc """
  Parse transaction inputs.
  """
  def parse_inputs(data) when is_binary(data) do
    {num_inputs, rest} = parse_varint(data)
    func = fn(data) ->
      {:ok, input, rest} = parse_input(data)
      {input, rest}
    end

    iterate_bin_to_list(rest, func, [], num_inputs)
  end

  @doc """
  Parse an input.
  """
  def parse_input(<<tx_hash :: binary-size(32),
                  index :: little-integer-size(32),
                  rest :: binary>>) do
    {script, rest} = get_varlen_data(rest)
    <<seq_num :: little-integer-size(32), rest :: binary>> = rest
    input = %Input{
              tx_hash: tx_hash,
              index: index,
              pkScript: script,
              seq_num: seq_num,
              }
    {:ok, input, rest}
  end

  @doc """
  Parse transaction outputs.
  """
  def parse_outputs(data) do
    {num_outputs, rest} = parse_varint(data)
    func = fn(data) ->
      {:ok, output, rest} = parse_output(data)
      {output, rest}
    end

    iterate_bin_to_list(rest, func, [], num_outputs)
  end

  @doc """
  Parse an output.
  """
  def parse_output(<<amount :: little-integer-size(64), rest :: binary>>) do
    {script, rest} = get_varlen_data(rest)
    output = %Output{
               amount: amount,
               outputScript: script,
               }
    {:ok, output, rest}
  end

  @doc """
  Parse a var int.

  * If first byte is less than < 0xfd, return the value of it.
  * If first byte is 0xfd the next two bytes are the value.
  * If first byte is 0xfe the next four bytes are the value.
  * If first byte is 0xff the next eight bytes are the value.

  All values are little-endian.
  """
  def parse_varint(<<val>>) when val < 0xfd do
    {val, <<>>}
  end
  def parse_varint(<<val :: little-integer-size(8), rest :: binary>>) when val < 0xfd do
    {val, rest}
  end
  def parse_varint(<<0xfd, val :: little-integer-size(16)>>)  do
    {val, <<>>}
  end
  def parse_varint(<<0xfd, val :: little-integer-size(16), rest :: binary>>)  do
    {val, rest}
  end
  def parse_varint(<<0xfe, val :: little-integer-size(32)>>)  do
    {val, <<>>}
  end
  def parse_varint(<<0xfe, val :: little-integer-size(32), rest :: binary>>)  do
    {val, rest}
  end
  def parse_varint(<<0xff, val :: little-integer-size(64)>>)  do
    {val, <<>>}
  end
  def parse_varint(<<0xff, val :: little-integer-size(64), rest :: binary>>)  do
    {val, rest}
  end

  @doc """
  Parse the varint at the beginning of the binary and return that amount of
  bytes and the rest of the binary.
  """
  def get_varlen_data(data) when is_binary(data) do
    {len, rest} = parse_varint(data)
    <<data_block :: binary-size(len), rest :: binary>> = rest
    {data_block, rest}
  end

  @doc """
  Convert a binary to a list using the function passed.
  """
  def iterate_bin_to_list(rest, _, elems, 0) do
    {:ok, Enum.reverse(elems), rest}
  end
  def iterate_bin_to_list(data, func, elems, n) when n > 0 do
    {elem, rest} = func.(data)
    iterate_bin_to_list(rest, func, [elem | elems], n-1)
  end
end

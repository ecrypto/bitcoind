
defmodule Block do
  defstruct magic: <<>>, size: <<>>, header: <<>>, tx_counter: 0
end

defmodule BlockHeader do
  defstruct version: <<>>, hash_prev_block: <<>>, hash_merkle_root: <<>>, time: <<>>, bits: <<>>, nonce: <<>>
end

defmodule Parser do
  def parse_block(<<magic :: binary-size(4),
                  size :: little-integer-size(32),
                  header :: binary-size(80),
                  rest :: binary>>)  do
    {tx_counter, rest} = parse_varint(rest)
    block = %Block{
              magic: magic,
              size: size,
              header: parse_block_header(header),
              tx_counter: tx_counter
          }
    {:ok, block, rest}
  end

  def parse_block_header(
        <<version :: little-integer-size(32),
        hash_prev_block :: binary-size(32),
        hash_merkle_root :: binary-size(32),
        time :: little-integer-size(32),
        bits :: binary-size(4),
        nonce :: little-integer-size(32),
        rest :: binary>>
      ) do
    header = %BlockHeader{
               version: version,
               hash_prev_block: hash_prev_block,
               hash_merkle_root: hash_merkle_root,
               time: time,
               bits: bits,
               nonce: nonce,
           }
    {:ok, header, rest}
  end
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
end

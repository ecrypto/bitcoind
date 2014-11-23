defmodule Parser do
  defmodule Block do
    defstruct magic: <<>>, size: <<>>, header: <<>>
  end
  defmodule BlockHeader do
    defstruct version: <<>>, hash_prev_block: <<>>, hash_merkle_root: <<>>, time: <<>>, bits: <<>>, nonce: <<>>
  end

  def parse_block(<<magic :: binary-size(4),
                  size :: little-integer-size(32),
                  header :: binary-size(80),
                  rest :: binary>>)  do
    block = %Block{
              magic: magic,
              size: size,
              header: parse_block_header(header),
          }
    {:ok, block, rest}
  end

  def parse_block_header(<<version :: little-integer-size(32),
                         hash_prev_block :: binary-size(32),
                         hash_merkle_root :: binary-size(32),
                         time :: little-integer-size(32),
                         bits :: binary-size(4),
                         nonce :: little-integer-size(32)>>) do
    %BlockHeader{
            version: version,
            hash_prev_block: hash_prev_block,
            hash_merkle_root: hash_merkle_root,
            time: time,
            bits: bits,
            nonce: nonce,
        }
  end
end

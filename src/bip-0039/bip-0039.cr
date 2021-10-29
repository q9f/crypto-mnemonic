require "random"
require "big"

module Crypto::Mnemonic

  # implements bip-39 mnemonics
  # https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
  class Bip0039

    # the entropy of the mnemonic
    getter ent : Int32

    # the random seed of the mnemonic
    getter seed : BigInt

    # generate a random 128-bit mnemonic
    def initialize
      @ent = 128
      @seed = generate_random_seed(@seed)
    end

    # generate a randome mneminuc of ENT bits
    def initialize(ent : Int32 = 128)
      if ent % 32 != 0 || ent < 128 || ent > 256
        raise "Can only generate seeds of 128/160/192/224/256-bit entropy"
      end
      @ent = ent
      @seed = generate_random_seed(ent)
    end

    # restore a mnemonic from a given hex string seed
    def initialize(hex : String)
      if hex.size % 8 != 0 || hex.size < 32 || hex.size > 64
        raise "Can only parse 128/160/192/224/256-bit hex seeds"
      end
      @ent = hex.size * 4
      @seed = BigInt.new hex, 16
    end

    # restore a mnemonic of given entropy from given seed
    def initialize(seed : BigInt, ent : Int32 = 128)
      if ent % 32 != 0 || ent < 128 || ent > 256
        raise "Can only recover seeds of 128/160/192/224/256-bit entropy"
      end
      @ent = ent
      @seed = seed
    end

    # restore a mnemonic from a given bip-39 phrase
    # def initialize(phrase : Array(String))
    #   @ent = nil
    #   @seed = nil
    # end

    # generates a random seed of ENT bits entropy
    private def generate_random_seed(ent : Int32) : BigInt
      raise "Invalid entropy provided" if ent % 32 != 0
      seed = Random::Secure.hex (ent / 8).to_i
      return BigInt.new seed, 16
    end

    # generates a phrase of words according to the bip-39 specification
    def to_words : Array(String)

      # a checksum is generated by taking the first ENT / 32 bits of its SHA256 hash
      seed_hex = Util.num_to_padded_hex @seed, @ent
      sha256sum_hex = OpenSSL::Digest.new("SHA256").update(seed_hex.hexbytes).final.hexstring
      sha256sum_bin = Util.hex_to_padded_bin sha256sum_hex, 256
      checksum_length = (ent / 32).to_i
      checksum_bin = sha256sum_bin[0, checksum_length]

      # this checksum is appended to the end of the initial entropy
      seed_bin = Util.num_to_padded_bin @seed, @ent
      checksummed_seed = seed_bin + checksum_bin

      # next, these concatenated bits are split into groups of 11 bits,
      # each encoding a number from 0-2047, serving as an index into a wordlist.
      iterator = 0
      split_size = 11
      word_indices = [] of Int32
      while iterator < checksummed_seed.size
        word_indices << checksummed_seed[iterator, split_size].to_i(2)
        iterator += split_size
      end

      # finally, we convert these numbers into words and use the joined words as a mnemonic sentence.
      word_list = Util.bip0039_word_list
      phrase = [] of String
      word_indices.each do |index|
        phrase << word_list[index]
      end
      return phrase
    end

    # returns the seed as hex string
    def to_hex : String
      return Util.num_to_padded_hex @seed, @ent
    end
  end
end

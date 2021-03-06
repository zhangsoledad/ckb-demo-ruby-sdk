# This contract needs 1 signed arguments:
# 1. pubkey, used to identify token owner
# This contracts also accepts one unsigned argument:
# 2. signature, signature used to present ownership
# 3. string of `,` separated array denoting outputs to sign.
# It's up to transaction assembler to arrange outputs, this script
# only cares that correct data are signed.
if ARGV.length != 3
  raise "Wrong number of arguments!"
end

def hex_to_bin(s)
  if s.start_with?("0x")
    s = s[2..-1]
  end
  s.each_char.each_slice(2).map(&:join).map(&:hex).map(&:chr).join
end

tx = CKB.load_tx
sha3 = Sha3.new

tx["inputs"].each_with_index do |input, i|
  sha3.update(input["hash"])
  sha3.update(input["index"].to_s)
  sha3.update(CKB.load_script_hash(i, CKB::Source::INPUT, CKB::Category::LOCK))
end
ARGV[2].split(",").each do |output_index|
  output_index = output_index.to_i
  output = tx["outputs"][output_index]
  sha3.update(output["capacity"].to_s)
  sha3.update(output["lock"])
  if hash = CKB.load_script_hash(output_index, CKB::Source::OUTPUT, CKB::Category::CONTRACT)
    sha3.update(hash)
  end
end

hash = sha3.final

pubkey = ARGV[0]
signature = ARGV[1]

unless Secp256k1.verify(hex_to_bin(pubkey), hex_to_bin(signature), hash)
  raise "Signature verification error!"
end

# frozen_string_literal: true

class ClaimEventValidator < ActiveModel::Validator
  MINIMUM_ADDRESS_HASH_LENGTH = 40

  def validate(record)
    record.errors.add(:address_hash, "Address is invalid.") && (return) if record.address_hash.blank? || record.address_hash.length < MINIMUM_ADDRESS_HASH_LENGTH

    address_hash_must_be_a_testnet_address(record)
    address_hash_cannot_be_short_multisig(record)
    address_hash_cannot_be_official_address(record)
  end

  private
    def address_hash_cannot_be_official_address(record)
      record.errors.add(:address_hash, "Does not support transfers to official address.") if Account.official_account&.address_hash == record.address_hash
    end

    def address_hash_must_be_a_testnet_address(record)
      parsed_address = CKB::AddressParser.new(record.address_hash).parse

      if parsed_address.mode != CKB::MODE::TESTNET
        record.errors.add(:address_hash, "Address must be a testnet address.")
      end
    rescue NoMethodError, CKB::AddressParser::InvalidFormatTypeError
      record.errors.add(:address_hash, "Address is invalid.")
    end

    def address_hash_cannot_be_short_multisig(record)
      parsed_address = CKB::AddressParser.new(record.address_hash).parse
      if parsed_address.address_type == "SHORTMULTISIG"
        record.errors.add(:address_hash, "Address cannot be multisig short payload format.")
      end
    rescue NoMethodError, CKB::AddressParser::InvalidFormatTypeError
      record.errors.add(:address_hash, "Address is invalid.")
    end
end

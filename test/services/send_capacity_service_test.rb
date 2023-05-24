# frozen_string_literal: true

require "test_helper"

class SendCapacityServiceTest < ActiveSupport::TestCase
  test "should fill tx_hash and tx_status to first pending event" do
    create_list(:claim_event, 2)
    create_list(:claim_event, 2, status: "processed")
    first_pending_event = ClaimEvent.order(:id).pending.first
    tx_hash = "0x1deb37a41c037919d8b0bbce6e7ac19fb00b7e12f0cacff369acd416369e72d9"
    api = mock("SdkApi")
    tx = build_tx(tx_hash)
    CKB::Wallets::NewWallet.any_instance.stubs(:advance_generate).returns(tx)
    CKB::Wallets::NewWallet.any_instance.stubs(:sign).returns(tx)
    api.stubs(:get_transaction).with(tx.inputs.first.previous_output.tx_hash).returns(OpenStruct.new(transaction: OpenStruct.new(outputs: [OpenStruct.new(capaicty: 100_000)])))
    api.stubs(:send_transaction).returns(tx_hash)
    SdkApi.stubs(:instance).returns(stub(api: api, indexer_api: nil))

    assert_changes -> { first_pending_event.reload.tx_hash }, from: nil, to: tx_hash do
      SendCapacityService.new.call
    end
  end

  test "should change status to processed" do
    tx_hash = "0x1deb37a41c037919d8b0bbce6e7ac19fb00b7e12f0cacff369acd416369e72d9"
    create(:claim_event, tx_hash: tx_hash)
    first_pending_event = ClaimEvent.order(:id).pending.first
    api = mock("SdkApi")
    result = OpenStruct.new(tx_status: OpenStruct.new(status: "committed"))
    api.stubs(:get_transaction).with(tx_hash).returns(result)
    SdkApi.stubs(:instance).returns(stub(api: api, indexer_api: nil))
    account = Account.official_account
    new_balacne = account.balance - first_pending_event.capacity
    SendCapacityService.new.call

    assert_equal first_pending_event.reload.status, "processed"
    assert_equal first_pending_event.reload.tx_status, "committed"
    assert_equal account.reload.balance, new_balacne
  end

  test "should change status to rejected" do
    tx_hash = "0x1deb37a41c037919d8b0bbce6e7ac19fb00b7e12f0cacff369acd416369e72d9"
    create(:claim_event, tx_hash: tx_hash)
    first_pending_event = ClaimEvent.order(:id).pending.first
    api = mock("SdkApi")
    result = OpenStruct.new(tx_status: OpenStruct.new(status: "unknown"))
    api.stubs(:get_transaction).with(tx_hash).returns(result)
    SdkApi.stubs(:instance).returns(stub(api: api, indexer_api: nil))
    SendCapacityService.new.call

    assert_equal first_pending_event.reload.status, "rejected"
    assert_equal first_pending_event.reload.tx_status, "unknown"
  end

  test "should change tx hash when not found tx" do
    tx_hash = "0x1deb37a41c037919d8b0bbce6e7ac19fb00b7e12f0cacff369acd416369e72d9"
    new_tx_hash = "0xace5ea83c478bb866edf122ff862085789158f5cbff155b7bb5f13058555b708"
    create(:claim_event, tx_hash: tx_hash)
    first_pending_event = ClaimEvent.order(:id).pending.first
    api = mock("SdkApi")
    tx = build_tx(tx_hash)
    CKB::Wallets::NewWallet.any_instance.stubs(:advance_generate).returns(tx)
    CKB::Wallets::NewWallet.any_instance.stubs(:sign).returns(tx)
    api.stubs(:get_transaction).with(tx_hash).returns(nil)
    api.stubs(:get_transaction).with(tx.inputs.first.previous_output.tx_hash).returns(OpenStruct.new(transaction: OpenStruct.new(outputs: [OpenStruct.new(capaicty: 100_000)])))
    api.stubs(:send_transaction).returns(new_tx_hash)
    SdkApi.stubs(:instance).returns(stub(api: api, indexer_api: nil))

    assert_changes -> { first_pending_event.reload.tx_hash }, from: tx_hash, to: new_tx_hash do
      SendCapacityService.new.call
    end
  end

  private
    def build_tx(new_tx_hash)
      out_point = CKB::Types::OutPoint.new(index: 0, tx_hash: "0xace5ea83c478bb866edf122ff862085789158f5cbff155b7bb5f13058555b708")
      cell_deps = CKB::Types::CellDep.new(dep_type: "dep_group", out_point: out_point)
      input = CKB::Types::Input.new(previous_output: CKB::Types::OutPoint.new(index: 0, tx_hash: "0x1b7af98007bf6128879798ac08fa26f863ded9aa3ebf1c04b321873b01042a21"), since: 0)
      output = CKB::Types::Output.new(capacity: 500000000000, lock: CKB::Types::Script.new(args: "0x59a27ef3ba84f061517d13f42cf44ed020610061", code_hash: "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8", hash_type: "type"), type: nil)
      witness = CKB::Types::Witness.new(input_type: "", lock: "0x8702b06d59d6d0577ca55e6672bc6c21086e0b216d06e85605e965c82431f929082f222d5315139c246ad537ce77af0237a7de032f813504fc80a0b6e1327b2f00", output_type: "")
      tx = CKB::Types::Transaction.new(cell_deps: [cell_deps], hash: new_tx_hash, header_deps: [], inputs: [input], outputs: [output], outputs_data: ["0x"], version: 0, witnesses: [witness])
      tx.witnesses = tx.witnesses.map do |witness|
        case witness
        when CKB::Types::Witness
          CKB::Serializers::WitnessArgsSerializer.new(witness).serialize
        else
          witness
        end
      end

      tx
    end
end

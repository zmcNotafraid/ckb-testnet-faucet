# frozen_string_literal: true

require "test_helper"

class ClaimEventsControllerTest < ActionDispatch::IntegrationTest
  test "should create new claim event when address hash is valid" do
    address_hash = "ckt1qyqd5eyygtdmwdr7ge736zw6z0ju6wsw7rssu8fcve"
    assert_difference -> { ClaimEvent.count }, 1 do
      post claim_events_url, params: { claim_event: { amount: 10000, address_hash: address_hash } }
    end
  end

  test "should reject claim when address hash is invalid" do
    address_hash = "ckt1q3w9q60tppt7l3j7r09qcp7lxnp3vcanvgha8pmvsa3jplykxn32s"

    post claim_events_url, params: { claim_event: { amount: 10000, address_hash: address_hash } }

    assert_response 422
    assert_equal json, { "errors"=>[{ "status"=>422, "title"=>"Unprocessable Entity", "detail"=>"Address is invalid.", "source"=>{ "pointer"=>"/data/attributes/address_hash" } }] }
  end

  test "should reject claim when address hash length is less than minimum" do
    address_hash = "123"

    post claim_events_url, params: { claim_event: { amount: 10000, address_hash: address_hash } }

    assert_response 422
    assert_equal json, { "errors"=>[{ "status"=>422, "title"=>"Unprocessable Entity", "detail"=>"Address is invalid.", "source"=>{ "pointer"=>"/data/attributes/address_hash" } }] }
  end

  test "should reject claim when address is not short payload format" do
    address_hash = "ckt1qyqlqn8vsj7r0a5rvya76tey9jd2rdnca8lqh4kcuq"

    post claim_events_url, params: { claim_event: { amount: 10000, address_hash: address_hash } }

    assert_response 422
    assert_equal json, { "errors"=>[{ "status"=>422, "title"=>"Unprocessable Entity", "detail"=>"Address cannot be multisig short payload format.", "source"=>{ "pointer"=>"/data/attributes/address_hash" } }] }
  end

  test "should reject claim when address is not testnet address" do
    address_hash = "ckb1qyqq5jr0hrm0uc8hduqp6cmjmfqmayghyfvspnxmu4"

    post claim_events_url, params: { claim_event: { amount: 10000, address_hash: address_hash } }


    assert_response 422
    assert_equal json, { "errors"=>[{ "status"=>422, "title"=>"Unprocessable Entity", "detail"=>"Address must be a testnet address.", "source"=>{ "pointer"=>"/data/attributes/address_hash" } }] }
  end

  test "should return 15 claims when visit claim event index" do
    create_list(:claim_event, 20)
    account = Account.official_account
    claim_events = ClaimEvent.recent.limit(ClaimEvent::DEFAULT_CLAIM_EVENT_SIZE)
    official_account = { "addressHash" => account.address_hash, "balance" => account.ckb_balance.to_s }

    get claim_events_url

    assert_response 200
    assert_equal 15, json["claimEvents"]["data"].size
    assert_equal JSON.parse(ClaimEventSerializer.new(claim_events).serializable_hash.to_json)["data"], json["claimEvents"]["data"]
    assert_equal official_account, json["officialAccount"]
  end

  test "should return pending claim events by given address hash" do
    create_list(:claim_event, 5, status: :processed)
    create_list(:claim_event, 3, :skip_validate, address_hash: "ckt1qyqd5eyygtdmwdr7ge736zw6z0ju6wsw7rssu8fcve")
    address_hash = "ckt1qyqd5eyygtdmwdr7ge736zw6z0ju6wsw7rssu8fcve"
    claim_events = ClaimEvent.where(address_hash: address_hash).recent.limit(15)

    get claim_event_url(address_hash)

    assert_response 200
    assert_equal 3, json["data"].size
    assert_equal JSON.parse(ClaimEventSerializer.new(claim_events).serializable_hash.to_json)["data"], json["data"]
  end

  test "should reject claim when target address hash is official address" do
    account = Account.official_account

    post claim_events_url, params: { claim_event: { address_hash: account.address_hash } }

    assert_response 422
    assert_equal json, {"errors"=>[{"status"=>422, "title"=>"Unprocessable Entity", "detail"=>"Params amount is not valid.", "source"=>{"pointer"=>"/data/attributes/amount"}}]}
  end

  test "should return error when this month's remaining is zero" do
    user = create(:account, balance: 300000 * 10**8)
    Rails.cache.stubs(:read).with("LIMIT_#{user.address_hash}").returns(Date.today)

    post claim_events_url, params: { claim_event: { amount: 100000, address_hash: user.address_hash } }

    assert_response 422
    assert_equal json, { "errors"=>[{ "status"=>422, "title"=>"Unprocessable Entity", "detail"=>"Amount is already reached maximum limit.", "source"=>{ "pointer"=>"/data/attributes/amount" } }] }
  end

  test "should return error if current claim amount added before amount greater than max limit" do
    user = create(:account, balance: 250000 * 10**8)

    post claim_events_url, params: { claim_event: { amount: 100000, address_hash: user.address_hash } }

    assert_response 422
    assert_equal json, { "errors"=>[{ "status"=>422, "title"=>"Unprocessable Entity", "detail"=>"The amount you claimed are greater than your remaining.", "source"=>{ "pointer"=>"/data/attributes/amount" } }] }
  end

  test "should create cache if claim all amount of this month" do
    user = create(:account, balance: 200000 * 10**8)

    Rails.cache.expects(:write).with("LIMIT_#{user.address_hash}", Date.today)
    post claim_events_url, params: { claim_event: { amount: 100000, address_hash: user.address_hash } }

    assert_response 200
    assert_equal user.reload.balance, 300000 * 10 ** 8
  end

  test "should handle concurrency claim" do
    user = create(:account, balance: 200000 * 10**8)
      threads = 5.times.map do
          Thread.new do
            post claim_events_url, params: { claim_event: { amount: 100000, address_hash: user.address_hash } }
          rescue AbstractController::DoubleRenderError
          end
      end
      threads.map(&:join)
    assert_equal user.reload.balance, 300000 * 10 ** 8
  end
end

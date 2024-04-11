defmodule Unit.ExecutionTest do
  alias LambdaEthereumConsensus.Execution.EngineApi
  alias LambdaEthereumConsensus.Execution.ExecutionClient
  use ExUnit.Case

  use Patch

  # Sepolia genesis block, as given by a geth client
  @example_block_header %{
    "base_fee_per_gas" => "0x3b9aca00",
    "difficulty" => "0x20000",
    "extra_data" => "0x5365706f6c69612c20417468656e732c204174746963612c2047726565636521",
    "gas_limit" => "0x1c9c380",
    "gas_used" => "0x0",
    "hash" => "0x25a5cc106eea7138acab33231d7160d69cb777ee0c2c553fcddf5138993e6dd9",
    "logs_bloom" =>
      "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "miner" => "0x0000000000000000000000000000000000000000",
    "mix_hash" => "0x0000000000000000000000000000000000000000000000000000000000000000",
    "nonce" => "0x0000000000000000",
    "number" => "0x0",
    "parent_hash" => "0x0000000000000000000000000000000000000000000000000000000000000000",
    "receipts_root" => "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
    "sha3_uncles" => "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
    "size" => "0x225",
    "state_root" => "0x5eb6e371a698b8d68f665192350ffcecbbbf322916f4b51bd79bb6887da3f494",
    "timestamp" => "0x6159af19",
    "total_difficulty" => "0x20000",
    "transactions" => [],
    "transactions_root" => "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
    "uncles" => []
  }

  @example_deposit_log %{
    "address" => "0x00000000219ab540356cbb839cbe05303d7705fa",
    "topics" => [
      "0x649bbc62d0e31342afea4e5cd82d4049e7e1ee912fc0889aa790803be39038c5"
    ],
    "data" =>
      "0x00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003096e37f606d5486e0b67ed7d2ae3ae21eb58adfd0d40d34f7a864934c35a7b142371361ef87ad8c0f0d2be9eeccc0d98e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020010000000000000000000000d4018ce9a041a9c110a9d0383d2b5e1c66ae151300000000000000000000000000000000000000000000000000000000000000080040597307000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006099a7541294fb10d9bf2825086bb6e4b51633ecdbb3f674461de7597e116fb23284d504bcaf9a46725e7c7f3647671d2f045476d0ba6012b0b86ff29761bdd3af2cf68e35b9c7a7942030651913a90a2f24604119ebec276da6667ca263bd217200000000000000000000000000000000000000000000000000000000000000080a6b150000000000000000000000000000000000000000000000000000000000",
    "blockNumber" => "0x12a9afa",
    "transactionHash" => "0xbbd2e6ba6014d690800de2522db63a5e5b606e322d811b27d19d98b2e9899868",
    "transactionIndex" => "0x8a",
    "blockHash" => "0x3a2368bfb8e136ec2f5891ab206972dde878ac5ad9b90443c3724bf750bf02f6",
    "logIndex" => "0x1aa",
    "removed" => false
  }

  test "decode block from json is OK" do
    patch(EngineApi, :get_block_header, fn nil -> {:ok, @example_block_header} end)
    assert {:ok, block_info} = ExecutionClient.get_block_metadata(nil)

    expected_hash =
      "25a5cc106eea7138acab33231d7160d69cb777ee0c2c553fcddf5138993e6dd9"
      |> Base.decode16!(case: :mixed)

    assert block_info.block_hash == expected_hash
    assert block_info.block_number == 0
    assert block_info.timestamp == 1_633_267_481
  end

  test "no block is OK" do
    patch(EngineApi, :get_block_header, fn nil -> {:ok, nil} end)
    assert {:ok, nil} = ExecutionClient.get_block_metadata(nil)
  end

  test "decode deposit logs is OK" do
    patch(EngineApi, :get_deposit_logs, fn _ -> {:ok, [@example_deposit_log]} end)
    assert {:ok, [deposit_info]} = ExecutionClient.get_deposit_logs(nil)

    credentials =
      Base.decode16!("010000000000000000000000D4018CE9A041A9C110A9D0383D2B5E1C66AE1513")

    signature =
      Base.decode16!(
        "99A7541294FB10D9BF2825086BB6E4B51633ECDBB3F674461DE7597E116FB23284D504BCAF9A46725E7C7F3647671D2F045476D0BA6012B0B86FF29761BDD3AF2CF68E35B9C7A7942030651913A90A2F24604119EBEC276DA6667CA263BD2172"
      )

    pubkey =
      Base.decode16!(
        "96E37F606D5486E0B67ED7D2AE3AE21EB58ADFD0D40D34F7A864934C35A7B142371361EF87AD8C0F0D2BE9EECCC0D98E"
      )

    assert deposit_info.block_number == 19_569_402
    assert deposit_info.index == 1_403_658
    assert deposit_info.data.amount == 32_000_000_000

    assert deposit_info.data.pubkey == pubkey
    assert deposit_info.data.signature == signature
    assert deposit_info.data.withdrawal_credentials == credentials
  end
end
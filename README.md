#  _AGENT_ Spells

**Governance Spells for _AGENT_**

## ✨ Spells

The latest spells can be found in the `src/proposals/` directory. Spells are organized by date in YYYYMMDD format, with separate files for each network (e.g., `Ethereum_20251231.sol`).

## Usage

### Build

```shell
$ forge build
```

### Test

Make sure you have `MAINNET_RPC_URL` in your .env

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
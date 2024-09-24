module MyModule::TokenExchange {

    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing the exchange pool between two tokens.
    struct ExchangePool has store, key {
        token_a_reserves: u64,
        token_b_reserves: u64,
        exchange_rate: u64,  // Rate for swapping token A to token B
    }

    /// Function to initialize the exchange pool with reserves and exchange rate.
    public fun initialize_pool(owner: &signer, initial_a: u64, initial_b: u64, rate: u64) {
        let pool = ExchangePool {
            token_a_reserves: initial_a,
            token_b_reserves: initial_b,
            exchange_rate: rate,
        };
        move_to(owner, pool);
    }

    /// Function to swap Token A for Token B based on the exchange rate.
    public fun swap_a_to_b(swapper: &signer, pool_owner: address, amount_a: u64) acquires ExchangePool {
        let pool = borrow_global_mut<ExchangePool>(pool_owner);

        // Calculate equivalent Token B based on exchange rate
        let amount_b = (amount_a * pool.exchange_rate) / 100;

        // Ensure the pool has enough Token B reserves for the swap
        assert!(pool.token_b_reserves >= amount_b, 1);

        // Perform the swap: withdraw Token A from swapper and transfer Token B
        let withdrawal = coin::withdraw<AptosCoin>(swapper, amount_a);
        coin::deposit<AptosCoin>(pool_owner, withdrawal);

        let swap_b = coin::withdraw<AptosCoin>(swapper, amount_b);
        coin::deposit<AptosCoin>(signer::address_of(swapper), swap_b);

        // Update reserves
        pool.token_a_reserves = pool.token_a_reserves + amount_a;
        pool.token_b_reserves = pool.token_b_reserves - amount_b;
    }
}

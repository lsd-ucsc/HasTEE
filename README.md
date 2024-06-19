
# HasTEE⁺

A Haskell DSL for programming Trusted Execution Environments (TEEs). 

See `app/Main.hs` and the `examples` directory for sample programs. To use examples, copy the contents over and change the module name in the code to "Main"


### Papers on HasTEE⁺:

[HasTEE: Programming Trusted Execution Environments with Haskell](https://dl.acm.org/doi/10.1145/3609026.3609731) - Version 1 of the DSL.

[HasTEE⁺: Confidential Cloud Computing and Analytics with Haskell](https://arxiv.org/abs/2401.08901) - Submitted to ESORICS 2024. Current version of the DSL.


### Building

#### SGX Machine Dependencies

For running on Intel SGX-enabled machines there are two complex dependencies. Note the DSL can be run without these two dependencies on standard machines (but not on SGX). Read past the two bullets for standard non-SGX setup.

- The remote attestation infrastructure of HasTEE⁺ relies on the ARM MbedTLS implementation of TLS 1.2. This implementation implements [Intel's RA-TLS protocol](https://arxiv.org/pdf/1801.05863.pdf). Experiments have been conducted on mbedtls version 3.2.1. Available [here](https://github.com/Mbed-TLS/mbedtls/tree/v3.2.1) and [here](https://packages.gramineproject.io/distfiles/mbedtls-3.2.1.tar.gz). `mbedtls` functions as a C library and there is some setup involved explained [here](https://github.com/Abhiroop/HasTEE/blob/master/Benchmarking.md#mbedtls-setup).
- Trusted GHC - A patched [GHC runtime](https://github.com/Abhiroop/ghc-trusted) capable of running on Intel SGX machines.

NOTE: The current `cabal.project` expects the trusted GHC at a particular location. For building this on your local machine that doesn't have SGX or the custom GHC, use - `cabal build --project-file=cabal-nosgx.project`.

The program is compiled n times for n binaries
#### Using cabal
```
-- For the enclave
cabal run -f enclave

-- For the client
-- `runAppRA "client1"...` should match the type-level string captured by the Client monad
cabal run
```

Follow the above order - run enclave first and then the client. The enclave is stateful and can be tested by running the enclave first and then calling the client repeatedly for the program in `Main.hs`.


#### Installed Binary Location

```
cabal exec which EnclaveIFC-exe
```

#### Client integrity check
Enabled with `-fintegrity-check`. Disabled by default. Works with the `mbed-tls`-based Remote Attestation protocol.


## Amended instructions
1. Create Codespace
2. ./init.sh
3. navigate to ghc-trusted directory
4. type "make"
5. wait for build to finish
6. navigate back to main HasTEE directory, then to cbits directory
7. curl -o mbedtls-mbedtls-3.2.1 https://packages.gramineproject.io/distfiles/mbedtls-3.2.1.tar.gz
8. tar xvzf mbedtls-mbedtls-3.2.1
9. back to HasTEE directory
10. cabal update
11. cabal build
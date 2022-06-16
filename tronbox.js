const port = process.env.HOST_PORT || 18981

module.exports = {
    networks: {
        mainnet: {
            privateKey: process.env.PRIVATE_KEY_MAINNET,
            userFeePercentage: 100,
            feeLimit: 1000 * 1e6,
            fullHost: 'https://api.trongrid.io',
            network_id: '1'
        },
        shasta: {
            privateKey: process.env.PRIVATE_KEY_SHASTA,
            fullHost: "https://api.shasta.trongrid.io",
            network_id: "2"
        },
        nile: {
            privateKey: process.env.PRIVATE_KEY_NAIL,
            fullHost: 'https://api.nileex.io',
            network_id: '3'
        },
        development: {
            privateKey: process.env.PRIVATE_KEY_DEVELOPMENT,
            userFeePercentage: 30,
            feeLimit: 100000000,
            fullHost: "http://127.0.0.1:8545",
            network_id: "*"
        },
        compilers: {
            solc: {
              version: '0.4.24'
            }
        }
    }
}

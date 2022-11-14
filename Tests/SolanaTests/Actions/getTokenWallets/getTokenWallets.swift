import XCTest
import Solana

class getTokenWallets: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var signer: Signer!

    override func setUpWithError() throws {
        let wallet: TestsWallet = .getWallets
        solana = Solana(router: NetworkingRouter(endpoint: endpoint))
        signer = HotAccount(phrase: wallet.testAccount.components(separatedBy: " "))!
    }
    
    func testsGetTokenWallets() {
        let wallets = try? solana.action.getTokenWallets(account: signer.publicKey.base58EncodedString)?.get()
        XCTAssertNotNil(wallets)
        XCTAssertNotEqual(wallets!.count, 0)
    }
}

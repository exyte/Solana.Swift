import Foundation
import TweetNacl

public class SolanaTransactionType {

    public static let base = SolanaTransactionType { (x, y) -> Bool in
        if x.isSigner != y.isSigner { return x.isSigner }
        if x.isWritable != y.isWritable { return x.isWritable }
        return false
    }

    public static let nft = SolanaTransactionType { (x, y) -> Bool in
        if x.isSigner != y.isSigner { return x.isSigner }
        if x.isWritable != y.isWritable { return x.isWritable }
        if x.isWritable && x.isSigner { return false }
        return x.publicKey < y.publicKey
    }

    let sorter: (Account.Meta, Account.Meta) -> Bool

    private init(sorter: @escaping (Account.Meta, Account.Meta) -> Bool) {
        self.sorter = sorter
    }
}

public struct Transaction {
    var signatures = [Signature]()
    public let feePayer: PublicKey
    public var instructions = [TransactionInstruction]()
    public let recentBlockhash: String
    public var type: SolanaTransactionType
    //        TODO: nonceInfo

    public init(signatures: [Transaction.Signature] = [Signature](), feePayer: PublicKey, instructions: [TransactionInstruction] = [TransactionInstruction](), recentBlockhash: String, type: SolanaTransactionType = .base) {
        self.signatures = signatures
        self.feePayer = feePayer
        self.instructions = instructions
        self.recentBlockhash = recentBlockhash
        self.type = type
    }

    // MARK: - Methods
    public mutating func sign(signers: [Account]) -> Result<Void, Error> {
        guard signers.count > 0 else {
            return .failure(SolanaError.invalidRequest(reason: "No signers"))
        }

        // unique signers
        let signers = signers.reduce([Account](), {signers, signer in
            var uniqueSigners = signers
            if !uniqueSigners.contains(where: {$0.publicKey == signer.publicKey}) {
                uniqueSigners.append(signer)
            }
            return uniqueSigners
        })

        // construct message
        return compile().flatMap { message in
            return partialSign(message: message, signers: signers)
        }
    }

    public mutating func serialize(
        requiredAllSignatures: Bool = true,
        verifySignatures: Bool = false
    ) -> Result<Data, Error> {
        // message
        return serializeMessage().flatMap { serializedMessage in
            return _verifySignatures(serializedMessage: serializedMessage, requiredAllSignatures: requiredAllSignatures)
                .mapError { _ in SolanaError.invalidRequest(reason: "Signature verification failed") }
                .flatMap { _ in _serialize(serializedMessage: serializedMessage) }
        }
    }

    // MARK: - Helpers
    public mutating func addSignature(_ signature: Signature) -> Result<Void, Error> {
        return compile() // Ensure signatures array is populated
            .flatMap { _ in return _addSignature(signature) }
    }

    public mutating func serializeMessage() -> Result<Data, Error> {
        return compile()
            .flatMap { $0.serialize(type: type) }
    }

    public mutating func verifySignatures() -> Result<Bool, Error> {
        return serializeMessage().flatMap {
            _verifySignatures(serializedMessage: $0, requiredAllSignatures: true)
        }
    }

    public func findSignature(pubkey: PublicKey) -> Signature? {
        signatures.first(where: {$0.publicKey == pubkey})
    }

    // MARK: - Signing
    private mutating func partialSign(message: Message, signers: [Account]) -> Result<Void, Error> {
        message.serialize(type: type)
            .flatMap { signData in
                for signer in signers {
                    do {
                        let data = try NaclSign.signDetached(message: signData, secretKey: signer.secretKey)
                        try _addSignature(Signature(signature: data, publicKey: signer.publicKey)).get()
                    } catch let error {
                        return .failure(error)
                    }
                }
                return .success(())
            }
    }

    private mutating func _addSignature(_ signature: Signature) -> Result<Void, Error> {
        guard let data = signature.signature,
              data.count == 64,
              let index = signatures.firstIndex(where: {$0.publicKey == signature.publicKey})
        else {
            return .failure(SolanaError.other("Signer not valid: \(signature.publicKey.base58EncodedString)"))
        }

        signatures[index] = signature
        return .success(())
    }

    // MARK: - Compiling
    private mutating func compile() -> Result<Message, Error> {
        compileMessage().map { message in
            let signedKeys = message.accountKeys.filter { $0.isSigner }
            if signatures.count == signedKeys.count {
                var isValid = true
                for (index, signature) in signatures.enumerated() {
                    if signedKeys[index].publicKey != signature.publicKey {
                        isValid = false
                        break
                    }
                }
                if isValid {
                    return message
                }
            }
            signatures = signedKeys.map {Signature(signature: nil, publicKey: $0.publicKey)}
            return message
        }
    }

    private func compileMessage() -> Result<Message, Error> {
        // verify instructions
        guard instructions.count > 0 else {
            return .failure(SolanaError.other("No instructions provided"))
        }

        // programIds & accountMetas
        var programIds = [PublicKey]()
        var accountMetas = [Account.Meta]()

        for instruction in instructions {
            accountMetas.append(contentsOf: instruction.keys)
            if !programIds.contains(instruction.programId) {
                programIds.append(instruction.programId)
            }
        }

        for programId in programIds {
            accountMetas.append(
                .init(publicKey: programId, isSigner: false, isWritable: false)
            )
        }

        // sort accountMetas, first by signer, then by writable
        accountMetas.sort(by: type.sorter)

        // filterOut duplicate account metas, keeps writable one
        accountMetas = accountMetas.reduce([Account.Meta](), {result, accountMeta in
            var uniqueMetas = result
            if let index = uniqueMetas.firstIndex(where: {$0.publicKey == accountMeta.publicKey}) {
                // if accountMeta exists
                uniqueMetas[index].isWritable = uniqueMetas[index].isWritable || accountMeta.isWritable
            } else {
                uniqueMetas.append(accountMeta)
            }
            return uniqueMetas
        })

        // move fee payer to front
        accountMetas.removeAll(where: {$0.publicKey == feePayer})
        accountMetas.insert(
            Account.Meta(publicKey: feePayer, isSigner: true, isWritable: true),
            at: 0
        )

        // verify signers
        for signature in signatures {
            if let index = try? accountMetas.index(ofElementWithPublicKey: signature.publicKey).get() {
                if !accountMetas[index].isSigner {
                    //                        accountMetas[index].isSigner = true
                    //                        Logger.log(message: "Transaction references a signature that is unnecessary, only the fee payer and instruction signer accounts should sign a transaction. This behavior is deprecated and will throw an error in the next major version release.", event: .warning)
                    return .failure(SolanaError.invalidRequest(reason: "Transaction references a signature that is unnecessary"))
                }
            } else {
                return .failure(SolanaError.invalidRequest(reason: "Unknown signer: \(signature.publicKey.base58EncodedString)"))
            }
        }

        // header
        var header = Message.Header()

        var signedKeys = [Account.Meta]()
        var unsignedKeys = [Account.Meta]()

        for accountMeta in accountMetas {
            // signed keys
            if accountMeta.isSigner {
                signedKeys.append(accountMeta)
                header.numRequiredSignatures += 1

                if !accountMeta.isWritable {
                    header.numReadonlySignedAccounts += 1
                }
            }

            // unsigned keys
            else {
                unsignedKeys.append(accountMeta)

                if !accountMeta.isWritable {
                    header.numReadonlyUnsignedAccounts += 1
                }
            }
        }

        accountMetas = signedKeys + unsignedKeys

        return .success(Message(
            accountKeys: accountMetas,
            recentBlockhash: recentBlockhash,
            programInstructions: instructions
        ))
    }

    // MARK: - Verifying
    private mutating func _verifySignatures(
        serializedMessage: Data,
        requiredAllSignatures: Bool
    ) -> Result<Bool, Error> {
        for signature in signatures {
            if signature.signature == nil {
                if requiredAllSignatures {
                    return .success(false)
                }
            } else {
                if (try? NaclSign.signDetachedVerify(message: serializedMessage, sig: signature.signature!, publicKey: signature.publicKey.data)) != true {
                    return .success(false)
                }
            }
        }
        return .success(true)
    }

    // MARK: - Serializing
    private mutating func _serialize(serializedMessage: Data) -> Result<Data, Error> {
        // signature length
        var signaturesLength = signatures.count

        // signature data
        let signaturesData = signatures.reduce(Data(), {result, signature in
            var data = result
            if let signature = signature.signature {
                data.append(signature)
            } else {
                signaturesLength -= 1
            }
            return data
        })

        let encodedSignatureLength = Data.encodeLength(signaturesLength)

        // transaction length
        var data = Data(capacity: encodedSignatureLength.count + signaturesData.count + serializedMessage.count)
        data.append(encodedSignatureLength)
        data.append(signaturesData)
        data.append(serializedMessage)
        return .success(data)
    }
}

public extension Transaction {
    public struct Signature {
        public var signature: Data?
        public var publicKey: PublicKey
        
        public init(signature: Data?, publicKey: PublicKey) {
            self.signature = signature
            self.publicKey = publicKey
        }
    }
}

import Foundation

public struct TokenSwapInfo: BufferLayout, Equatable, Hashable, Encodable {
    init(version: UInt8, isInitialized: Bool, nonce: UInt8, tokenProgramId: PublicKey, tokenAccountA: PublicKey, tokenAccountB: PublicKey, tokenPool: PublicKey, mintA: PublicKey, mintB: PublicKey, feeAccount: PublicKey, tradeFeeNumerator: UInt64, tradeFeeDenominator: UInt64, ownerTradeFeeNumerator: UInt64, ownerTradeFeeDenominator: UInt64, ownerWithdrawFeeNumerator: UInt64, ownerWithdrawFeeDenominator: UInt64, hostFeeNumerator: UInt64, hostFeeDenominator: UInt64, curveType: UInt8, payer: PublicKey) {
        self.version = version
        self.isInitialized = isInitialized
        self.nonce = nonce
        self.tokenProgramId = tokenProgramId
        self.tokenAccountA = tokenAccountA
        self.tokenAccountB = tokenAccountB
        self.tokenPool = tokenPool
        self.mintA = mintA
        self.mintB = mintB
        self.feeAccount = feeAccount
        self.tradeFeeNumerator = tradeFeeNumerator
        self.tradeFeeDenominator = tradeFeeDenominator
        self.ownerTradeFeeNumerator = ownerTradeFeeNumerator
        self.ownerTradeFeeDenominator = ownerTradeFeeDenominator
        self.ownerWithdrawFeeNumerator = ownerWithdrawFeeNumerator
        self.ownerWithdrawFeeDenominator = ownerWithdrawFeeDenominator
        self.hostFeeNumerator = hostFeeNumerator
        self.hostFeeDenominator = hostFeeDenominator
        self.curveType = curveType
        self.payer = payer
    }
    
    // MARK: - Properties
    public let version: UInt8
    public let isInitialized: Bool
    public let nonce: UInt8
    public let tokenProgramId: PublicKey
    public var tokenAccountA: PublicKey
    public var tokenAccountB: PublicKey
    public let tokenPool: PublicKey
    public var mintA: PublicKey
    public var mintB: PublicKey
    public let feeAccount: PublicKey
    public let tradeFeeNumerator: UInt64
    public let tradeFeeDenominator: UInt64
    public let ownerTradeFeeNumerator: UInt64
    public let ownerTradeFeeDenominator: UInt64
    public let ownerWithdrawFeeNumerator: UInt64
    public let ownerWithdrawFeeDenominator: UInt64
    public let hostFeeNumerator: UInt64
    public let hostFeeDenominator: UInt64
    public let curveType: UInt8
    public let payer: PublicKey
    
    // MARK: - Initializer
    public init?(_ keys: [String: [UInt8]]) {
        guard let version = keys["version"]?.first,
              let isInitialized = keys["isInitialized"]?.first,
              let nonce = keys["nonce"]?.first,
              let tokenProgramId = PublicKey(bytes: keys["tokenProgramId"]),
              let tokenAccountA = PublicKey(bytes: keys["tokenAccountA"]),
              let tokenAccountB = PublicKey(bytes: keys["tokenAccountB"]),
              let tokenPool = PublicKey(bytes: keys["tokenPool"]),
              let mintA = PublicKey(bytes: keys["mintA"]),
              let mintB = PublicKey(bytes: keys["mintB"]),
              let feeAccount = PublicKey(bytes: keys["feeAccount"]),
              let tradeFeeNumerator = keys["tradeFeeNumerator"]?.toUInt64(),
              let tradeFeeDenominator = keys["tradeFeeDenominator"]?.toUInt64(),
              let ownerTradeFeeNumerator = keys["ownerTradeFeeNumerator"]?.toUInt64(),
              let ownerTradeFeeDenominator = keys["ownerTradeFeeDenominator"]?.toUInt64(),
              let ownerWithdrawFeeNumerator = keys["ownerWithdrawFeeNumerator"]?.toUInt64(),
              let ownerWithdrawFeeDenominator = keys["ownerWithdrawFeeDenominator"]?.toUInt64(),
              let hostFeeNumerator = keys["hostFeeNumerator"]?.toUInt64(),
              let hostFeeDenominator = keys["hostFeeDenominator"]?.toUInt64(),
              let curveType = keys["curveType"]?.first,
              let payer = PublicKey(bytes: keys["payer"])
        else {
            return nil
        }
        self.version = version
        self.isInitialized = isInitialized == 1
        self.nonce = nonce
        self.tokenProgramId = tokenProgramId
        self.tokenAccountA = tokenAccountA
        self.tokenAccountB = tokenAccountB
        self.tokenPool = tokenPool
        self.mintA = mintA
        self.mintB = mintB
        self.feeAccount = feeAccount
        self.tradeFeeNumerator = tradeFeeNumerator
        self.tradeFeeDenominator = tradeFeeDenominator
        self.ownerTradeFeeNumerator = ownerTradeFeeNumerator
        self.ownerTradeFeeDenominator = ownerTradeFeeDenominator
        self.ownerWithdrawFeeNumerator = ownerWithdrawFeeNumerator
        self.ownerWithdrawFeeDenominator = ownerWithdrawFeeDenominator
        self.hostFeeNumerator = hostFeeNumerator
        self.hostFeeDenominator = hostFeeDenominator
        self.curveType = curveType
        self.payer = payer
    }
    
    // MARK: - Layout
    public static func layout()  -> [(key: String?, length: Int)] {
        [
            (key: "version", length: 1),
            (key: "isInitialized", length: 1),
            (key: "nonce", length: 1),
            (key: "tokenProgramId", length: PublicKey.LENGTH),
            (key: "tokenAccountA", length: PublicKey.LENGTH),
            (key: "tokenAccountB", length: PublicKey.LENGTH),
            (key: "tokenPool", length: PublicKey.LENGTH),
            (key: "mintA", length: PublicKey.LENGTH),
            (key: "mintB", length: PublicKey.LENGTH),
            (key: "feeAccount", length: PublicKey.LENGTH),
            (key: "tradeFeeNumerator", length: 8),
            (key: "tradeFeeDenominator", length: 8),
            (key: "ownerTradeFeeNumerator", length: 8),
            (key: "ownerTradeFeeDenominator", length: 8),
            (key: "ownerWithdrawFeeNumerator", length: 8),
            (key: "ownerWithdrawFeeDenominator", length: 8),
            (key: "hostFeeNumerator", length: 8),
            (key: "hostFeeDenominator", length: 8),
            (key: "curveType", length: 1),
            (key: "payer", length: PublicKey.LENGTH)
        ]
    }
}

extension TokenSwapInfo: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try version.serialize(to: &writer)
        if isInitialized { try UInt8(1).serialize(to: &writer) } else { try UInt8(0).serialize(to: &writer) }
        try nonce.serialize(to: &writer)
        try tokenProgramId.serialize(to: &writer)
        try tokenAccountA.serialize(to: &writer)
        try tokenAccountB.serialize(to: &writer)
        try tokenPool.serialize(to: &writer)
        try mintA.serialize(to: &writer)
        try mintB.serialize(to: &writer)
        try feeAccount.serialize(to: &writer)
        try tradeFeeNumerator.serialize(to: &writer)
        try tradeFeeDenominator.serialize(to: &writer)
        try ownerTradeFeeNumerator.serialize(to: &writer)
        try ownerTradeFeeDenominator.serialize(to: &writer)
        try ownerWithdrawFeeNumerator.serialize(to: &writer)
        try ownerWithdrawFeeDenominator.serialize(to: &writer)
        try hostFeeNumerator.serialize(to: &writer)
        try hostFeeDenominator.serialize(to: &writer)
        try curveType.serialize(to: &writer)
        try payer.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.version = try .init(from: &reader)
        self.isInitialized = try UInt8.init(from: &reader) == 1
        self.nonce = try .init(from: &reader)
        self.tokenProgramId = try PublicKey.init(from: &reader)
        self.tokenAccountA = try PublicKey.init(from: &reader)
        self.tokenAccountB = try PublicKey.init(from: &reader)
        self.tokenPool = try PublicKey.init(from: &reader)
        self.mintA = try PublicKey.init(from: &reader)
        self.mintB = try PublicKey.init(from: &reader)
        self.feeAccount = try PublicKey.init(from: &reader)
        self.tradeFeeNumerator = try .init(from: &reader)
        self.tradeFeeDenominator = try .init(from: &reader)
        self.ownerTradeFeeNumerator = try .init(from: &reader)
        self.ownerTradeFeeDenominator = try .init(from: &reader)
        self.ownerWithdrawFeeNumerator = try .init(from: &reader)
        self.ownerWithdrawFeeDenominator = try .init(from: &reader)
        self.hostFeeNumerator = try .init(from: &reader)
        self.hostFeeDenominator = try .init(from: &reader)
        self.curveType = try .init(from: &reader)
        self.payer = try PublicKey.init(from: &reader)
    }
}

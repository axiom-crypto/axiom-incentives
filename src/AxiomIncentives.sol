// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AxiomV2Client } from "@axiom-crypto/v2-periphery/client/AxiomV2Client.sol";

/// @title AxiomIncentives
/// @notice A client for the AxiomV2Query contract that processes claims for incentives.
abstract contract AxiomIncentives is AxiomV2Client {
    /// @dev Whether the query schema is accepted by this contract.
    mapping(bytes32 => bool) public validQuerySchemas;

    /// @dev `lastClaimedId[querySchema][incentiveId]` is the latest `claimId` at which the user with
    ///      `incentiveId` claimed a reward with type `querySchema`.
    /// @dev `claimId` = `blockNumber` * 2^128 + `txIdx` * 2^64 + `logIdx`
    mapping(bytes32 querySchema => mapping(uint256 incentiveId => uint256 claimId)) public lastClaimedId;

    /// @notice Construct a new AxiomIncentives contract.
    /// @param  _axiomV2QueryAddress The address of the AxiomV2Query contract.
    /// @param  incentivesQuerySchemas The query schemas accepted by this contract.
    constructor(address _axiomV2QueryAddress, bytes32[] memory incentivesQuerySchemas)
        AxiomV2Client(_axiomV2QueryAddress)
    {
        for (uint256 i = 0; i < incentivesQuerySchemas.length; i++) {
            validQuerySchemas[incentivesQuerySchemas[i]] = true;
        }
    }

    /// @notice Process a claim for incentives.
    /// @param  querySchema The query schema of the claim.
    /// @param  startClaimId The ID of the first claim in the claim batch.
    /// @param  endClaimId The ID of the last claim in the claim batch.
    /// @param  incentiveId The ID of the claimer.
    /// @param  totalValue The total value of the claim batch.
    function _processClaim(
        bytes32 querySchema,
        uint256 startClaimId,
        uint256 endClaimId,
        uint256 incentiveId,
        uint256 totalValue
    ) internal {
        _validateClaim(querySchema, startClaimId, endClaimId, incentiveId, totalValue);

        // enforce no double claims by enforcing monotonicity of claimId
        require(lastClaimedId[querySchema][incentiveId] < startClaimId, "Already claimed");
        lastClaimedId[querySchema][incentiveId] = endClaimId;

        _sendClaimRewards(querySchema, startClaimId, endClaimId, incentiveId, totalValue);
    }

    /// @inheritdoc AxiomV2Client
    function _validateAxiomV2Call(
        AxiomCallbackType, // callbackType,
        uint64 sourceChainId,
        address, // caller,
        bytes32 querySchema,
        uint256, // queryId,
        bytes calldata // extraData
    ) internal view override {
        require(sourceChainId == block.chainid, "Source chain ID does not match");
        require(validQuerySchemas[querySchema], "Invalid query schema");
    }

    /// @inheritdoc AxiomV2Client
    function _axiomV2Callback(
        uint64, // sourceChainId,
        address, // caller,
        bytes32 querySchema,
        uint256, // queryId,
        bytes32[] calldata axiomResults,
        bytes calldata // extraData
    ) internal override {
        uint256 startClaimId = uint256(axiomResults[0]);
        uint256 endClaimId = uint256(axiomResults[1]);
        uint256 incentiveId = uint256(axiomResults[2]);
        uint256 totalValue = uint256(axiomResults[3]);

        _processClaim(querySchema, startClaimId, endClaimId, incentiveId, totalValue);
    }

    /// @notice Validate a claim for incentives.  Should revert if the claim is not valid.
    /// @param  querySchema The query schema of the claim.
    /// @param  startClaimId The ID of the first claim in the claim batch.
    /// @param  endClaimId The ID of the last claim in the claim batch.
    /// @param  incentiveId The ID of the claimer.
    /// @param  totalValue The total value of the claim batch.
    function _validateClaim(
        bytes32 querySchema,
        uint256 startClaimId,
        uint256 endClaimId,
        uint256 incentiveId,
        uint256 totalValue
    ) internal virtual;

    /// @notice Send rewards for a claim for incentives.
    /// @param  querySchema The query schema of the claim.
    /// @param  startClaimId The ID of the first claim in the claim batch.
    /// @param  endClaimId The ID of the last claim in the claim batch.
    /// @param  incentiveId The ID of the claimer.
    /// @param  totalValue The total value of the claim batch.
    function _sendClaimRewards(
        bytes32 querySchema,
        uint256 startClaimId,
        uint256 endClaimId,
        uint256 incentiveId,
        uint256 totalValue
    ) internal virtual;
}

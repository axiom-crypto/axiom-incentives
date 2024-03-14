# AxiomIncentives

The `AxiomIncentives` abstract base contract allows applications to offer incentives based on provable on-chain activity associated with receipts on Ethereum. This system requires that each rewarded action, which we call a **claim**, be uniquely associated with an event log. We identify each claim with:

- `uint256 claimId` -- a monotone increasing identifier for all Ethereum receipts
- `uint256 incentiveId` -- a unique identifier of the rewarded user
- `uint256 claimValue` -- a numerical measure of the value of the claim, e.g. the fees paid in a transaction.

To prevent double claiming, we enforce that claims must be made in increasing order of `claimId`. Users can prove claims in a batch, and Axiom provides the following ZK-proven results to `AxiomIncentives` via callback:

- `uint256 startClaimId` -- the smallest `claimId` in the claimed batch
- `uint256 endClaimId` -- the largest `claimId` in the claimed batch
- `uint256 incentiveId` -- the `incentiveId` for all claims in this batch
- `uint256 totalValue` -- the sum of `claimValue` over all claims in the batch.

## Development

To set up the development environment, run:

```
forge install
npm install   # or `yarn install` or `pnpm install`
```

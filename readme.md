# LegendaryWeapons - Mythical Arms Bazaar

A Stacks blockchain smart contract for creating, trading, and managing legendary weapon NFTs with built-in royalty mechanisms.

## Overview

LegendaryWeapons is an NFT marketplace contract that enables users to forge unique legendary weapons, list them for sale, and trade them with automatic royalty distribution to original creators (blacksmiths).

## Features

- **Forge Weapons**: Create unique legendary weapon NFTs with custom enchantments
- **Marketplace**: List weapons for sale and purchase from other wielders
- **Royalty System**: Automatic tribute payments to original blacksmiths on secondary sales
- **Ownership Management**: Track wielders and original creators
- **Admin Controls**: Transferable contract ownership

## Core Functions

### Administrative

**`enthrone-master`**
- Transfer contract ownership to a new master
- Only callable by current armory master
- Parameters: `successor` (principal)

**`get-current-master`**
- Returns the current armory master address
- Read-only function

### Weapon Creation

**`forge-weapon`**
- Mint a new legendary weapon NFT
- Parameters:
  - `enchantment` (string-ascii 256): Weapon description/metadata
  - `forge-tribute` (uint): Royalty percentage in basis points (max 1000 = 10%)
- Returns: weapon ID
- Constraints: Enchantment must be non-empty, tribute ≤ 10%

### Marketplace Operations

**`initiate-sale`**
- List a weapon for sale
- Parameters:
  - `weapon-id` (uint): ID of weapon to sell
  - `sale-price` (uint): Price in microSTX
- Only callable by weapon owner
- Price must be greater than 0

**`terminate-sale`**
- Remove weapon from marketplace
- Parameters: `weapon-id` (uint)
- Only callable by the merchant who listed it

**`claim-weapon`**
- Purchase a listed weapon
- Parameters: `weapon-id` (uint)
- Automatically distributes:
  - Royalty to original blacksmith
  - Remaining payment to seller
- Transfers NFT ownership to buyer

### Query Functions

**`inspect-weapon`**
- Retrieve weapon metadata
- Parameters: `weapon-id` (uint)
- Returns: wielder, blacksmith, enchantment, forge-tribute

**`inspect-sale`**
- Check marketplace listing details
- Parameters: `weapon-id` (uint)
- Returns: sale-price, merchant

## Data Structures

### Weapon Vault
Stores weapon metadata:
- `wielder`: Current owner
- `blacksmith`: Original creator
- `enchantment`: Weapon description
- `forge-tribute`: Royalty percentage (basis points)

### Arms Market
Tracks active sales:
- `sale-price`: Listed price in microSTX
- `merchant`: Seller address

## Error Codes

- `err-permission-denied (u100)`: Unauthorized admin action
- `err-not-wielder (u101)`: Not weapon owner
- `err-sale-inactive (u102)`: No active listing
- `err-bid-inadequate (u103)`: Invalid price
- `err-weapon-missing (u104)`: Weapon doesn't exist
- `err-forge-data-invalid (u105)`: Invalid enchantment
- `err-tribute-limit-exceeded (u106)`: Royalty > 10%
- `err-empty-principal (u107)`: Invalid address

## Usage Example

```clarity
;; Forge a legendary sword with 5% royalty
(contract-call? .legendary-weapons forge-weapon "Excalibur: The Sword of Kings" u500)

;; List weapon #1 for 1000 STX
(contract-call? .legendary-weapons initiate-sale u1 u1000000000)

;; Purchase weapon #1
(contract-call? .legendary-weapons claim-weapon u1)

;; Check weapon details
(contract-call? .legendary-weapons inspect-weapon u1)
```

## Security Considerations

- Weapons cannot be transferred while listed for sale
- Royalty payments are enforced automatically on every sale
- Maximum royalty capped at 10% to prevent excessive fees
- Principal validation prevents null address operations
- Only weapon owners can list their weapons
- Only listing creators can cancel listings


# INRC Token Issuer

<div align="center">
  <img src="./inrcoin_frontend/src/assets/pngwing.com%20(1).png" alt="INRC Token Logo" width="200" height="200"/>
  <h3>A Comprehensive ERC20 Token Platform for the $INRC Token</h3>
</div>

## Overview

INRC Token Issuer is a fully-featured platform for issuing, managing, and interacting with the $INRC token, a custom ERC20 implementation with enhanced security and administrative features. The platform consists of a robust Solidity smart contract and a React-based web interface for users and administrators.

The token is designed with advanced capabilities including blacklisting, pausability, and standard ERC20 functionality, making it suitable for regulated financial applications.

## Live Demo

Experience the INRC Token Issuer platform on Sepolia testnet:
[https://inrc-token-issuer.vercel.app/](https://inrc-token-issuer.vercel.app/)

To interact with the demo:
1. Connect with MetaMask set to Sepolia testnet
2. Request test ETH from a Sepolia faucet if needed
3. Explore the user dashboard and token functionality

## Contract Verification

The $INRC token contract has been verified on Etherscan:
[View Verified Contract on Sepolia Etherscan](https://sepolia.etherscan.io/token/0x1c2ff585120219e552a4c3a6ce5b6345cb1efa2c#code)

This verification allows anyone to inspect the deployed contract code and interact with it directly through Etherscan's interface.

## Features

### Smart Contract Capabilities

- **Standard ERC20 Functions**: Complete implementation of the ERC20 interface including transfer, approval, and allowance mechanisms
- **Minting & Burning**: Controlled token supply management through secure minting and burning functions
- **Blacklist System**: Ability to restrict specific addresses from participating in token transfers (similar to USDT)
- **Pause Mechanism**: Emergency pause functionality to halt all token transfers if necessary
- **Ownership Controls**: Secure ownership management with privilege restriction

### Web Interface Features

- **User Dashboard**: Easy-to-use interface for checking balances, transferring tokens, and managing approvals
- **Admin Panel**: Comprehensive admin tools for contract management, including:
    - Token minting and burning
    - Blacklist management
    - Contract pause/unpause
    - Ownership transfer
- **MetaMask Integration**: Seamless connection with MetaMask wallet for secure transaction signing
- **Real-time Status Updates**: Clear transaction status indicators and notifications

## Technical Implementation

### Smart Contract Architecture

The INRC token contract follows best practices for security and efficiency:

- Built on Solidity ^0.8.0 with automatic overflow checking
- Custom error messages for gas-efficient failure handling
- Comprehensive event logging for all state changes
- Modular design with internal functions for core operations
- Rigorous access control through function modifiers

### Key Contract Methods

- `transfer(address _to, uint256 _value)`: Transfer tokens to another address
- `approve(address _spender, uint256 _value)`: Approve an address to spend tokens
- `transferFrom(address _from, address _to, uint256 _value)`: Transfer tokens on behalf of another address
- `mint(address _to, uint256 _amount)`: Create new tokens (admin only)
- `burn(address _from, uint256 _amount)`: Destroy existing tokens (admin only)
- `blacklist(address _address)` & `unBlacklist(address _address)`: Manage blacklisted addresses
- `pause()` & `unpause()`: Emergency controls for token transfers
- `transferOwnership(address _newOwner)`: Change contract owner

## Test Coverage and Quality Assurance

<div align="center">
  <img src="./inrcoin_frontend/src/assets/Screenshot 2025-03-13 at 11.50.54 AM.png" alt="Test Coverage" width="800"/>
</div>

Our smart contract has undergone rigorous testing, ensuring reliability and security:

- Unit tests covering all contract functions
- Integration tests for complex user flows
- Edge case testing for security vulnerabilities
- Gas optimization analysis

## Installation and Setup

### Prerequisites
- Node.js (v14+)
- npm or yarn
- MetaMask browser extension

### Contract Deployment
1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/INRC-token-issuer.git
   cd INRC-token-issuer
   ```

2. Install dependencies
   ```bash
   npm install
   ```

3. Deploy the contract
   ```bash
   npx hardhat run scripts/deploy.js --network your-network
   ```

### Frontend Setup
1. Navigate to the frontend directory
   ```bash
   cd frontend
   ```

2. Install dependencies
   ```bash
   npm install
   ```

3. Update the contract address in `src/App.tsx`

4. Start the development server
   ```bash
   npm start
   ```

## Usage Guide

### For Token Holders
1. Connect your MetaMask wallet to the application
2. View your token balance in the user dashboard
3. Use the transfer function to send tokens to other addresses
4. Approve other addresses to spend tokens on your behalf

### For Administrators
1. Connect the owner wallet to access admin functions
2. Use the minting feature to issue new tokens
3. Manage blacklisted addresses as necessary
4. Control the pause state of the contract in emergency situations

## Security Considerations

The INRC token contract implements several security measures:

- Admin-only functions restricted through modifiers
- Checks-Effects-Interactions pattern to prevent reentrancy
- Blacklisting capabilities for regulatory compliance
- Emergency pause functionality for threat mitigation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<div align="center">
  <p>Made with ❤️ for a stronger digital India</p>
</div>
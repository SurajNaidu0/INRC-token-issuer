// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/StableCoin.sol";
import {Deployer} from "../script/DepolyStableCoin.s.sol";

contract MyTokenIntegrationTest is Test {
    // Contract instance
    MyToken token;
    
    // Test accounts
    Deployer deployer_contract;
    address deployer;
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address user4 = address(0x4);
    address regulator = address(0x5);
    
    // Test values
    uint256 private constant INITIAL_TRANSFER = 100_000 * 10**6; // 100,000 tokens
    uint256 private constant MINT_AMOUNT = 500_000 * 10**6; // 500,000 tokens
    
    // Setup function - runs before each test
    function setUp() public {
        deployer_contract = new Deployer();
        token = deployer_contract.run();
        deployer = msg.sender;
    }
    
    // ============ Complex Integration Tests ============
    
    function testMultiUserTransactionFlow() public {
        // Initial setup: Owner distributes tokens to users
        vm.startPrank(deployer);
        token.transfer(user1, INITIAL_TRANSFER);
        token.transfer(user2, INITIAL_TRANSFER);
        token.transfer(regulator, INITIAL_TRANSFER);
        vm.stopPrank();
        
        // User1 transfers some tokens to User3
        vm.startPrank(user1);
        token.transfer(user3, 25_000 * 10**6);
        vm.stopPrank();
        
        // User2 approves User4 to spend tokens
        vm.startPrank(user2);
        token.approve(user4, 50_000 * 10**6);
        vm.stopPrank();
        
        // User4 transfers tokens from User2 to themselves
        vm.startPrank(user4);
        token.transferFrom(user2, user4, 30_000 * 10**6);
        vm.stopPrank();
        
        // Verify balances after transactions
        assertEq(token.balanceOf(user1), 75_000 * 10**6);
        assertEq(token.balanceOf(user2), 70_000 * 10**6);
        assertEq(token.balanceOf(user3), 25_000 * 10**6);
        assertEq(token.balanceOf(user4), 30_000 * 10**6);
        assertEq(token.allowance(user2, user4), 20_000 * 10**6);
    }
    
    function testRegulatoryActions() public {
        // Setup: Distribute initial tokens
        vm.startPrank(deployer);
        token.transfer(user1, INITIAL_TRANSFER);
        token.transfer(user2, INITIAL_TRANSFER);
        
        // Regulatory action 1: Blacklist user2 for suspicious activity
        token.blacklist(user2);
        vm.stopPrank();
        
        // User1 tries to transfer to blacklisted user (should fail)
        vm.startPrank(user1);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.transfer(user2, 10_000 * 10**6);
        
        // User1 transfers to a non-blacklisted user instead
        token.transfer(user3, 10_000 * 10**6);
        vm.stopPrank();
        
        // Blacklisted user tries to transfer (should fail)
        vm.startPrank(user2);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.transfer(user3, 5_000 * 10**6);
        vm.stopPrank();
        
        // Regulatory action 2: Emergency pause of the contract
        vm.startPrank(deployer);
        token.pause();
        vm.stopPrank();
        
        // All transfers should now fail
        vm.startPrank(user1);
        vm.expectRevert(MyToken.ContractPaused.selector);
        token.transfer(user3, 5_000 * 10**6);
        vm.stopPrank();
        
        // Regulatory action 3: Unblacklist user2 after compliance
        vm.startPrank(deployer);
        token.unBlacklist(user2);
        token.unpause();
        vm.stopPrank();
        
        // User2 should now be able to transfer again
        vm.startPrank(user2);
        token.transfer(user3, 5_000 * 10**6);
        vm.stopPrank();
        
        // Verify final state
        assertEq(token.balanceOf(user1), 90_000 * 10**6);
        assertEq(token.balanceOf(user2), 95_000 * 10**6);
        assertEq(token.balanceOf(user3), 15_000 * 10**6);
        assertFalse(token.isBlacklisted(user2));
        assertFalse(token.paused());
    }
    
    function testSupplyManagementScenario() public {
        // Initial supply check
        uint256 initialSupply = token.totalSupply();
        
        // Scenario: Increasing money supply during economic expansion
        vm.startPrank(deployer);
        token.mint(user1, MINT_AMOUNT);
        vm.stopPrank();
        
        // User1 distributes some of the new supply
        vm.startPrank(user1);
        token.transfer(user2, 100_000 * 10**6);
        token.transfer(user3, 150_000 * 10**6);
        vm.stopPrank();
        
        // Scenario: Reducing money supply during inflation
        vm.startPrank(deployer);
        token.burn(user1, 50_000 * 10**6);
        vm.stopPrank();
        
        // Verify supply changes
        assertEq(token.totalSupply(), initialSupply + MINT_AMOUNT - 50_000 * 10**6);
        assertEq(token.balanceOf(user1), MINT_AMOUNT - 100_000 * 10**6 - 150_000 * 10**6 - 50_000 * 10**6);
        assertEq(token.balanceOf(user2), 100_000 * 10**6);
        assertEq(token.balanceOf(user3), 150_000 * 10**6);
    }
    
    function testOwnershipTransferScenario() public {
        // Initial setup
        vm.startPrank(deployer);
        token.transfer(user1, INITIAL_TRANSFER);
        
        // Transfer ownership to the regulator
        token.transferOwnership(regulator);
        vm.stopPrank();
        
        // Old owner can no longer perform admin actions
        vm.startPrank(deployer);
        vm.expectRevert(MyToken.OnlyOwner.selector);
        token.mint(user2, 10_000 * 10**6);
        vm.stopPrank();
        
        // New owner performs regulatory actions
        vm.startPrank(regulator);
        token.mint(user2, 10_000 * 10**6);
        token.blacklist(user3);
        vm.stopPrank();
        
        // User1 tries to interact with blacklisted user3
        vm.startPrank(user1);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.transfer(user3, 1000 * 10**6);
        vm.stopPrank();
        
        // Verify ownership change
        assertEq(token.owner(), regulator);
        assertEq(token.balanceOf(user2), 10_000 * 10**6);
        assertTrue(token.isBlacklisted(user3));
    }
    
    function testComplexAllowanceScenario() public {
        // Setup: Distribute tokens to users
        vm.startPrank(deployer);
        token.transfer(user1, INITIAL_TRANSFER);
        vm.stopPrank();
        
        // User1 approves multiple users to spend their tokens
        vm.startPrank(user1);
        token.approve(user2, 20_000 * 10**6);
        token.approve(user3, 30_000 * 10**6);
        vm.stopPrank();
        
        // User2 and User3 spend some of their allowance
        vm.startPrank(user2);
        token.transferFrom(user1, user4, 15_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(user3);
        token.transferFrom(user1, user4, 10_000 * 10**6);
        vm.stopPrank();
        
        // User1 increases User2's allowance
        vm.startPrank(user1);
        token.increaseAllowance(user2, 10_000 * 10**6);
        vm.stopPrank();
        
        // User2 spends more
        vm.startPrank(user2);
        token.transferFrom(user1, user2, 10_000 * 10**6);
        vm.stopPrank();
        
        // User1 decreases User3's allowance
        vm.startPrank(user1);
        token.decreaseAllowance(user3, 10_000 * 10**6);
        vm.stopPrank();
        
        // Verify allowances and balances
        assertEq(token.allowance(user1, user2), 5_000 * 10**6);
        assertEq(token.allowance(user1, user3), 10_000 * 10**6);
        assertEq(token.balanceOf(user1), INITIAL_TRANSFER - 15_000 * 10**6 - 10_000 * 10**6 - 10_000 * 10**6);
        assertEq(token.balanceOf(user2), 10_000 * 10**6);
        assertEq(token.balanceOf(user4), 25_000 * 10**6);
    }
    
    function testEmergencyScenario() public {
        // Setup: Distribute tokens and set spenders
        vm.startPrank(deployer);
        token.transfer(user1, INITIAL_TRANSFER);
        token.transfer(user2, INITIAL_TRANSFER);
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.approve(user3, 50_000 * 10**6);
        vm.stopPrank();
        
        // Simulate normal operations
        vm.startPrank(user3);
        token.transferFrom(user1, user3, 20_000 * 10**6);
        vm.stopPrank();
        
        // Emergency: Owner detects suspicious activity
        vm.startPrank(deployer);
        // Pause all transfers
        token.pause();
        // Blacklist suspicious users
        token.blacklist(user3);
        vm.stopPrank();
        
        // Ensure no more transfers can happen
        vm.startPrank(user1);
        vm.expectRevert(MyToken.ContractPaused.selector);
        token.transfer(user2, 10_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.expectRevert(MyToken.ContractPaused.selector);
        token.transfer(user1, 10_000 * 10**6);
        vm.stopPrank();
        
        // Emergency response: Owner mints replacement tokens for affected user
        vm.startPrank(deployer);
        token.unpause();
        token.mint(user1, 20_000 * 10**6);
        vm.stopPrank();
        
        // Verify emergency recovery
        assertEq(token.balanceOf(user1), INITIAL_TRANSFER - 20_000 * 10**6 + 20_000 * 10**6);
        assertTrue(token.isBlacklisted(user3));
        assertFalse(token.paused());
    }
    
    function testUnlimitedApprovalScenario() public {
        // Setup: Distribute tokens
        vm.startPrank(deployer);
        token.transfer(user1, INITIAL_TRANSFER);
        vm.stopPrank();
        
        // User1 grants unlimited approval to User2
        vm.startPrank(user1);
        token.approve(user2, type(uint256).max);
        vm.stopPrank();
        
        // User2 performs multiple transfers
        vm.startPrank(user2);
        token.transferFrom(user1, user2, 10_000 * 10**6);
        token.transferFrom(user1, user3, 20_000 * 10**6);
        token.transferFrom(user1, user4, 30_000 * 10**6);
        vm.stopPrank();
        
        // Verify allowance remains unlimited
        assertEq(token.allowance(user1, user2), type(uint256).max);
        assertEq(token.balanceOf(user1), INITIAL_TRANSFER - 60_000 * 10**6);
        assertEq(token.balanceOf(user2), 10_000 * 10**6);
        assertEq(token.balanceOf(user3), 20_000 * 10**6);
        assertEq(token.balanceOf(user4), 30_000 * 10**6);
    }
    
    function testMintBurnCycle() public {
        // Track initial supply
        uint256 initialSupply = token.totalSupply();
        
        // Cycle 1: Mint tokens, distribute, then burn some
        vm.startPrank(deployer);
        token.mint(user1, 100_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.transfer(user2, 40_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(deployer);
        token.burn(user2, 10_000 * 10**6);
        vm.stopPrank();
        
        // Cycle 2: Repeat with different amounts
        vm.startPrank(deployer);
        token.mint(user3, 200_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(user3);
        token.transfer(user4, 120_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(deployer);
        token.burn(user3, 30_000 * 10**6);
        token.burn(user4, 20_000 * 10**6);
        vm.stopPrank();
        
        // Verify final supply after cycles
        uint256 expectedSupply = initialSupply + 100_000 * 10**6 + 200_000 * 10**6 - 10_000 * 10**6 - 30_000 * 10**6 - 20_000 * 10**6;
        assertEq(token.totalSupply(), expectedSupply);
        assertEq(token.balanceOf(user1), 60_000 * 10**6);
        assertEq(token.balanceOf(user2), 30_000 * 10**6);
        assertEq(token.balanceOf(user3), 50_000 * 10**6);
        assertEq(token.balanceOf(user4), 100_000 * 10**6);
    }
    
    function testMultipleOwnershipTransfers() public {
        // Initial ownership check
        assertEq(token.owner(), deployer);
        
        // Transfer ownership multiple times
        vm.startPrank(deployer);
        token.transferOwnership(user1);
        vm.stopPrank();
        
        vm.startPrank(user1);
        token.transferOwnership(user2);
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.transferOwnership(user3);
        vm.stopPrank();
        
        // Previous owners can no longer perform admin actions
        vm.startPrank(user1);
        vm.expectRevert(MyToken.OnlyOwner.selector);
        token.mint(user4, 10_000 * 10**6);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.expectRevert(MyToken.OnlyOwner.selector);
        token.pause();
        vm.stopPrank();
        
        // Current owner can perform admin actions
        vm.startPrank(user3);
        token.mint(user4, 10_000 * 10**6);
        token.pause();
        token.unpause();
        vm.stopPrank();
        
        // Verify final ownership
        assertEq(token.owner(), user3);
    }
}
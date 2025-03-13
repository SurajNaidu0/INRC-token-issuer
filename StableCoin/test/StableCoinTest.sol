// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/StableCoin.sol"; // Adjust path if needed
import {Deployer} from "../script/DepolyStableCoin.s.sol";

contract MyTokenTest is Test {
    // Contract instance
    MyToken token;
    
    // Test accounts
    Deployer deployer_contract;
    address deployer;
    address user1 = address(0x2);
    address user2 = address(0x3);
    address blacklistedUser = address(0x4);
    
    // Test values
    string private constant NAME = "Indian Rupee Token";
    string private constant SYMBOL = "INRT";
    uint8 private constant DECIMALS = 6;
    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10**6; // 1 million tokens
    
    // Setup function - runs before each test
    function setUp() public {
        deployer_contract = new Deployer();
        token = deployer_contract.run();
        deployer = msg.sender;
    }
    
    // ============ Constructor Tests ============
    
    function testConstructor() public {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
        assertEq(token.owner(), deployer);
        assertEq(token.paused(), false);
    }
    
    // ============ Basic Functionality Tests ============
    
    function testTransfer() public {
        uint256 amount = 1000 * 10**6; // 1000 tokens
        
        vm.startPrank(deployer);
        bool success = token.transfer(user1, amount);
        vm.stopPrank();
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }
    
    function testTransferFailsInsufficientBalance() public {
        uint256 amount = INITIAL_SUPPLY + 1; // More than total supply
        
        vm.startPrank(deployer);
        vm.expectRevert(MyToken.InsufficientBalance.selector);
        token.transfer(user1, amount);
        vm.stopPrank();
    }
    
    function testApprove() public {
        uint256 amount = 1000 * 10**6; // 1000 tokens
        
        vm.startPrank(deployer);
        bool success = token.approve(user1, amount);
        vm.stopPrank();
        
        assertTrue(success);
        assertEq(token.allowance(deployer, user1), amount);
    }
    
    function testTransferFrom() public {
        uint256 approvalAmount = 1000 * 10**6; // 1000 tokens
        uint256 transferAmount = 500 * 10**6; // 500 tokens
        
        // Approve user1 to spend deployer's tokens
        vm.startPrank(deployer);
        token.approve(user1, approvalAmount);
        vm.stopPrank();
        
        // User1 transfers tokens from deployer to user2
        vm.startPrank(user1);
        bool success = token.transferFrom(deployer, user2, transferAmount);
        vm.stopPrank();
        
        assertTrue(success);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - transferAmount);
        assertEq(token.allowance(deployer, user1), approvalAmount - transferAmount);
    }
    
    function testTransferFromUnlimitedApproval() public {
        uint256 approvalAmount = type(uint256).max; // Unlimited approval
        uint256 transferAmount = 500 * 10**6; // 500 tokens
        
        // Approve user1 to spend unlimited tokens
        vm.startPrank(deployer);
        token.approve(user1, approvalAmount);
        vm.stopPrank();
        
        // User1 transfers tokens twice
        vm.startPrank(user1);
        token.transferFrom(deployer, user2, transferAmount);
        token.transferFrom(deployer, user2, transferAmount);
        vm.stopPrank();
        
        // Allowance should still be unlimited
        assertEq(token.allowance(deployer, user1), approvalAmount);
        assertEq(token.balanceOf(user2), transferAmount * 2);
    }
    
    function testTransferFromFailsInsufficientAllowance() public {
        uint256 approvalAmount = 500 * 10**6; // 500 tokens
        uint256 transferAmount = 1000 * 10**6; // 1000 tokens
        
        // Approve user1 to spend deployer's tokens
        vm.startPrank(deployer);
        token.approve(user1, approvalAmount);
        vm.stopPrank();
        
        // User1 tries to transfer more than allowed
        vm.startPrank(user1);
        vm.expectRevert(MyToken.InsufficientAllowance.selector);
        token.transferFrom(deployer, user2, transferAmount);
        vm.stopPrank();
    }
    
    function testIncreaseAllowance() public {
        uint256 initialAmount = 1000 * 10**6; // 1000 tokens
        uint256 increaseAmount = 500 * 10**6; // 500 tokens
        
        vm.startPrank(deployer);
        token.approve(user1, initialAmount);
        bool success = token.increaseAllowance(user1, increaseAmount);
        vm.stopPrank();
        
        assertTrue(success);
        assertEq(token.allowance(deployer, user1), initialAmount + increaseAmount);
    }
    
    function testDecreaseAllowance() public {
        uint256 initialAmount = 1000 * 10**6; // 1000 tokens
        uint256 decreaseAmount = 300 * 10**6; // 300 tokens
        
        vm.startPrank(deployer);
        token.approve(user1, initialAmount);
        bool success = token.decreaseAllowance(user1, decreaseAmount);
        vm.stopPrank();
        
        assertTrue(success);
        assertEq(token.allowance(deployer, user1), initialAmount - decreaseAmount);
    }
    
    function testDecreaseAllowanceFailsAllowanceUnderflow() public {
        uint256 initialAmount = 500 * 10**6; // 500 tokens
        uint256 decreaseAmount = 1000 * 10**6; // 1000 tokens
        
        vm.startPrank(deployer);
        token.approve(user1, initialAmount);
        vm.expectRevert(MyToken.AllowanceUnderflow.selector);
        token.decreaseAllowance(user1, decreaseAmount);
        vm.stopPrank();
    }
    
    // ============ Owner Functionality Tests ============
    
    function testMint() public {
        uint256 mintAmount = 500 * 10**6; // 500 tokens
        
        vm.startPrank(deployer);
        token.mint(user1, mintAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }
    
    function testMintFailsNonOwner() public {
        uint256 mintAmount = 500 * 10**6; // 500 tokens
        
        vm.startPrank(user1);
        vm.expectRevert(MyToken.OnlyOwner.selector);
        token.mint(user2, mintAmount);
        vm.stopPrank();
    }
    
    function testBurn() public {
        uint256 transferAmount = 1000 * 10**6; // 1000 tokens
        uint256 burnAmount = 500 * 10**6; // 500 tokens
        
        // Transfer to user1 first
        vm.startPrank(deployer);
        token.transfer(user1, transferAmount);
        
        // Then burn some of user1's tokens
        token.burn(user1, burnAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), transferAmount - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }
    
    function testBurnFailsInsufficientBalance() public {
        uint256 burnAmount = 100 * 10**6; // 100 tokens
        
        vm.startPrank(deployer);
        vm.expectRevert(MyToken.InsufficientBalance.selector);
        token.burn(user1, burnAmount); // User1 has no tokens
        vm.stopPrank();
    }
    
    function testBlacklist() public {
        vm.startPrank(deployer);
        token.blacklist(blacklistedUser);
        vm.stopPrank();
        
        assertTrue(token.isBlacklisted(blacklistedUser));
        
        // Try to transfer to blacklisted user
        vm.startPrank(deployer);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.transfer(blacklistedUser, 100 * 10**6);
        vm.stopPrank();
    }
    
    function testUnBlacklist() public {
        // First blacklist
        vm.startPrank(deployer);
        token.blacklist(blacklistedUser);
        
        // Then unblacklist
        token.unBlacklist(blacklistedUser);
        vm.stopPrank();
        
        assertFalse(token.isBlacklisted(blacklistedUser));
        
        // Should now be able to transfer
        vm.startPrank(deployer);
        bool success = token.transfer(blacklistedUser, 100 * 10**6);
        vm.stopPrank();
        
        assertTrue(success);
    }
    
    function testPause() public {
        vm.startPrank(deployer);
        token.pause();
        vm.stopPrank();
        
        assertTrue(token.paused());
        
        // Try to transfer while paused
        vm.startPrank(deployer);
        vm.expectRevert(MyToken.ContractPaused.selector);
        token.transfer(user1, 100 * 10**6);
        vm.stopPrank();
    }
    
    function testUnpause() public {
        // First pause
        vm.startPrank(deployer);
        token.pause();
        
        // Then unpause
        token.unpause();
        vm.stopPrank();
        
        assertFalse(token.paused());
        
        // Should now be able to transfer
        vm.startPrank(deployer);
        bool success = token.transfer(user1, 100 * 10**6);
        vm.stopPrank();
        
        assertTrue(success);
    }
    
    function testTransferOwnership() public {
        vm.startPrank(deployer);
        token.transferOwnership(user1);
        vm.stopPrank();
        
        assertEq(token.owner(), user1);
        
        // Previous owner should no longer be able to call owner functions
        vm.startPrank(deployer);
        vm.expectRevert(MyToken.OnlyOwner.selector);
        token.mint(user2, 100 * 10**6);
        vm.stopPrank();
        
        // New owner should be able to call owner functions
        vm.startPrank(user1);
        token.mint(user2, 100 * 10**6);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user2), 100 * 10**6);
    }
    
    // ============ Complex Scenario Tests ============
    
    function testBlacklistedUserCannotTransfer() public {
        // First transfer to user who will be blacklisted
        vm.startPrank(deployer);
        token.transfer(blacklistedUser, 1000 * 10**6);
        token.blacklist(blacklistedUser);
        vm.stopPrank();
        
        // Blacklisted user tries to transfer
        vm.startPrank(blacklistedUser);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.transfer(user1, 100 * 10**6);
        vm.stopPrank();
    }
    
    function testBlacklistedUserCannotApprove() public {
        vm.startPrank(deployer);
        token.blacklist(blacklistedUser);
        vm.stopPrank();
        
        vm.startPrank(blacklistedUser);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.approve(user1, 100 * 10**6);
        vm.stopPrank();
    }
    
    function testBlacklistedUserCannotBeApproved() public {
        vm.startPrank(deployer);
        token.blacklist(blacklistedUser);
        vm.stopPrank();
        
        vm.startPrank(user1);
        vm.expectRevert(MyToken.AddressBlacklisted.selector);
        token.approve(blacklistedUser, 100 * 10**6);
        vm.stopPrank();
    }
    
    function testPausedContractPreventsAllTransfers() public {
        // Setup: Give tokens to users
        vm.startPrank(deployer);
        token.transfer(user1, 1000 * 10**6);
        token.approve(user2, 500 * 10**6);
        token.pause();
        vm.stopPrank();
        
        // User1 tries to transfer
        vm.startPrank(user1);
        vm.expectRevert(MyToken.ContractPaused.selector);
        token.transfer(user2, 100 * 10**6);
        vm.stopPrank();
        
        // User2 tries to transferFrom
        vm.startPrank(user2);
        vm.expectRevert(MyToken.ContractPaused.selector);
        token.transferFrom(deployer, user1, 100 * 10**6);
        vm.stopPrank();
    }
    
    function testFullTransferScenario() public {
        // 1. Deployer transfers to user1
        vm.startPrank(deployer);
        token.transfer(user1, 1000 * 10**6);
        vm.stopPrank();
        
        // 2. User1 approves user2 to spend
        vm.startPrank(user1);
        token.approve(user2, 500 * 10**6);
        vm.stopPrank();
        
        // 3. User2 transfers from user1 to themselves
        vm.startPrank(user2);
        token.transferFrom(user1, user2, 300 * 10**6);
        vm.stopPrank();
        
        // 4. Owner mints more tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, 200 * 10**6);
        vm.stopPrank();
        
        // 5. Owner burns some tokens from user2
        vm.startPrank(deployer);
        token.burn(user2, 100 * 10**6);
        vm.stopPrank();
        
        // Verify final state
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - 1000 * 10**6);
        assertEq(token.balanceOf(user1), 1000 * 10**6 - 300 * 10**6 + 200 * 10**6);
        assertEq(token.balanceOf(user2), 300 * 10**6 - 100 * 10**6);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 200 * 10**6 - 100 * 10**6);
        assertEq(token.allowance(user1, user2), 500 * 10**6 - 300 * 10**6);
    }
}
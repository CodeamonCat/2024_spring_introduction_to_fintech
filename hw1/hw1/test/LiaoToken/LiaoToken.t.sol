// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LiaoToken} from "../../src/LiaoToken/LiaoToken.sol";
import {Test, console2} from "forge-std/Test.sol";

/// @title Liao Token Test
/// @author Louis Tsai
/// @notice Do NOT modify this contract or you might get 0 points for the assingment.

contract LiaoTokenTest is Test {
    LiaoToken internal token;
    address internal Bob;
    address internal Alice;
    address internal user;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claim(address indexed user, uint256 indexed amount);

    function setUp() public {
        token = new LiaoToken("LiaoToken", "Liao");
        Bob = makeAddr("Bob");
        Alice = makeAddr("Alice");
        user = makeAddr("user");

        vm.prank(Bob);
        vm.expectEmit(true, true, false, false);
        emit Claim(Bob, 1 ether);
        token.claim();

        vm.prank(Alice);
        vm.expectEmit(true, true, false, false);
        emit Claim(Alice, 1 ether);
        token.claim();
    }

    /* Default Tests */
    function test_decimal() public {
        uint8 decimals = token.decimals();
        assertEq(decimals, 18);
    }

    function test_name() public {
        string memory name = token.name();
        assertEq(name, "LiaoToken");
    }

    function test_symbol() public {
        string memory symbol = token.symbol();
        assertEq(symbol, "Liao");
    }

    function test_totalSupply() public {
        uint256 totalSupply = token.totalSupply();
        assertEq(totalSupply, 2 ether);
    }

    function testBalanceOf() public {
        uint256 balance;

        balance = token.balanceOf(Bob);
        assertEq(balance, 1 ether);

        balance = token.balanceOf(Alice);
        assertEq(balance, 1 ether);
    }

    /* PART 1: Complete transfer function -> 10 points */
    function test_transfer() public returns (bool) {
        vm.prank(Bob);
        vm.expectEmit(true, true, false, false);
        emit Transfer(Bob, Alice, 0.5 ether);
        bool success = token.transfer(Alice, 0.5 ether);
        assertTrue(success);

        uint256 balance;
        balance = token.balanceOf(Bob);
        assertEq(balance, 0.5 ether);

        balance = token.balanceOf(Alice);
        assertEq(balance, 1.5 ether);

        return true;
    }

    function test_transfer_balance_not_enough() public returns (bool) {
        vm.prank(Bob);
        vm.expectRevert();
        token.transfer(Alice, 1.5 ether);

        return true;
    }

    /* PART 2: Complete approve and allowance function -> 10 points */
    function test_approve_function() public returns (bool) {
        vm.prank(Bob);
        vm.expectEmit(true, true, false, false);
        emit Approval(Bob, Alice, 1 ether);
        bool success = token.approve(Alice, 1 ether);
        assertTrue(success);

        uint256 allowance = token.allowance(Bob, Alice);
        assertEq(allowance, 1 ether);

        return true;
    }

    /* PART 3: Complete transferFrom function -> 10 points */
    function test_transferFrom() public returns (bool) {
        bool success;
        uint256 balance;

        vm.prank(Bob);
        vm.expectEmit(true, true, false, false);
        emit Approval(Bob, Alice, 1 ether);
        success = token.approve(Alice, 1 ether);
        assertTrue(success);

        vm.prank(Alice);
        vm.expectEmit(true, true, false, false);
        emit Transfer(Bob, user, 1 ether);
        success = token.transferFrom(Bob, user, 1 ether);
        assertTrue(success);

        balance = token.balanceOf(Bob);
        assertEq(balance, 0);

        balance = token.balanceOf(user);
        assertEq(balance, 1 ether);

        return true;
    }

    function test_transferFrom_allowance_not_enough() public returns (bool) {
        bool success;

        vm.prank(Bob);
        vm.expectEmit(true, true, false, false);
        emit Approval(Bob, Alice, 1 ether);
        success = token.approve(Alice, 0.5 ether);
        assertTrue(success);

        vm.prank(Alice);
        vm.expectRevert();
        token.transferFrom(Alice, user, 1 ether);

        return true;
    }

    function test_transferFrom_balance_not_enough() public returns (bool) {
        bool success;
        vm.prank(Bob);
        vm.expectEmit(true, true, false, false);
        emit Approval(Bob, Alice, 1 ether);
        success = token.approve(Alice, 0.5 ether);
        assertTrue(success);

        vm.prank(Alice);
        vm.expectRevert();
        token.transferFrom(Alice, user, 2 ether);

        return true;
    }

    /* We use the following parts to calculate your score */
    function test_check_transfer_points() public {
        bool success = test_transfer() && test_transfer_balance_not_enough();
        if (success) console2.log("Get 10 points");
    }

    function test_check_approve_points() public {
        bool success = test_approve_function();
        if (success) console2.log("Get 10 points");
    }

    function test_check_transferFrom_points() public {
        bool success =
            test_transferFrom() && test_transferFrom_allowance_not_enough() && test_transferFrom_balance_not_enough();
        if (success) console2.log("Get 10 points");
    }
}

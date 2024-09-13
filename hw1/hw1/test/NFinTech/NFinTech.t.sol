// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../../src/NFinTech/NFinTech.sol";

/// @title NFinTech Test
/// @author Louis Tsai
/// @notice Do NOT modify this contract or you might get 0 points for the assingment.

contract NFinTechTest is Test {
    NFinTech internal nft;
    address internal Bob;
    address internal Alice;
    address internal user;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        nft = new NFinTech("NFinTech", "NFT");

        user = makeAddr("user");

        Bob = makeAddr("Bob");
        vm.prank(Bob);
        nft.claim();

        Alice = makeAddr("Alice");
        vm.prank(Alice);
        nft.claim();
    }

    /* Default Tests */
    function test_name() public {
        string memory name = nft.name();
        assertEq(name, "NFinTech");
    }

    function test_symbol() public {
        string memory symbol = nft.symbol();
        assertEq(symbol, "NFT");
    }

    function test_balanceOf() public {
        uint256 balance;

        vm.prank(Bob);
        balance = nft.balanceOf(Bob);
        assertEq(balance, 1);

        vm.prank(Alice);
        balance = nft.balanceOf(Alice);
        assertEq(balance, 1);

        vm.expectRevert();
        nft.balanceOf(address(0));
    }

    function test_ownerOf() public {
        address owner;

        owner = nft.ownerOf(0);
        assertEq(owner, Bob);

        owner = nft.ownerOf(1);
        assertEq(owner, Alice);

        vm.expectRevert();
        nft.ownerOf(3);
    }

    /* PART 1: Complete approve related function -> 10 points */

    function test_approve() public returns (bool) {
        vm.prank(Bob);
        vm.expectEmit(true, true, true, false);
        emit Approval(Bob, Alice, 0);
        nft.approve(Alice, 0);

        address operator = nft.getApproved(0);
        assertEq(operator, Alice);

        return true;
    }

    function test_setApprovalForAll() public returns (bool) {
        bool approved;
        vm.prank(Bob);
        vm.expectEmit(true, true, true, false);
        emit ApprovalForAll(Bob, Alice, true);
        nft.setApprovalForAll(Alice, true);

        approved = nft.isApprovedForAll(Bob, Alice);
        assertEq(approved, true);

        vm.prank(Bob);
        vm.expectEmit(true, true, true, false);
        emit ApprovalForAll(Bob, Alice, false);
        nft.setApprovalForAll(Alice, false);

        approved = nft.isApprovedForAll(Bob, Alice);
        assertEq(approved, false);

        vm.prank(Bob);
        vm.expectRevert();
        nft.setApprovalForAll(address(0), true);

        return true;
    }

    function test_approve_not_token_owner() public returns (bool) {
        vm.prank(Bob);
        vm.expectRevert();
        nft.approve(Alice, 1);
        return true;
    }

    function test_approve_then_setApprovalForAll() public returns (bool) {
        vm.prank(Bob);
        vm.expectEmit(true, true, true, false);
        emit ApprovalForAll(Bob, Alice, true);
        nft.setApprovalForAll(Alice, true);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Approval(Bob, user, 0);
        nft.approve(user, 0);

        address operator = nft.getApproved(0);
        assertEq(operator, user);

        return true;
    }

    /* PART 2: Complete transferFrom function -> 10 points */
    function test_transferFrom() public returns (bool) {
        uint256 balance;
        address owner;

        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Bob, Alice, 0);
        nft.transferFrom(Bob, Alice, 0);

        balance = nft.balanceOf(Bob);
        assertEq(balance, 0);
        balance = nft.balanceOf(Alice);
        assertEq(balance, 2);

        owner = nft.ownerOf(0);
        assertEq(owner, Alice);
        owner = nft.ownerOf(1);
        assertEq(owner, Alice);

        return true;
    }

    function test_transferFrom_zero_address() public returns (bool) {
        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectRevert();
        nft.transferFrom(Bob, address(0), 0);

        return true;
    }

    function test_transferFrom_not_owner() public returns (bool) {
        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectRevert();
        nft.transferFrom(Bob, address(0), 1);

        return true;
    }

    /* PART 3: Complete safeTransferFrom function -> 10 points */
    function test_safeTransferFrom_eoa() public returns (bool) {
        uint256 balance;
        address owner;

        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Bob, Alice, 0);
        nft.transferFrom(Bob, Alice, 0);

        balance = nft.balanceOf(Bob);
        assertEq(balance, 0);
        balance = nft.balanceOf(Alice);
        assertEq(balance, 2);

        owner = nft.ownerOf(0);
        assertEq(owner, Alice);
        owner = nft.ownerOf(1);
        assertEq(owner, Alice);

        return true;
    }

    function test_safeTransferFrom_ca_success() public returns (bool) {
        uint256 balance;
        address owner;

        MockSuccessReceiver receiver = new MockSuccessReceiver();

        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Bob, address(receiver), 0);
        nft.safeTransferFrom(Bob, address(receiver), 0);

        balance = nft.balanceOf(Bob);
        assertEq(balance, 0);
        balance = nft.balanceOf(address(receiver));
        assertEq(balance, 1);

        owner = nft.ownerOf(0);
        assertEq(owner, address(receiver));
        owner = nft.ownerOf(1);
        assertEq(owner, Alice);

        return true;
    }

    function test_safeTransferFrom_ca_failure() public returns (bool) {
        MockBadReceiver receiver = new MockBadReceiver();

        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectRevert();
        nft.safeTransferFrom(Bob, address(receiver), 0);

        return true;
    }

    /* PART 4: Mixed operation test */
    function test_approve_then_transferFrom() public {
        uint256 balance;
        address owner;

        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Bob, Alice, 0);
        nft.transferFrom(Bob, Alice, 0);

        balance = nft.balanceOf(Bob);
        assertEq(balance, 0);
        balance = nft.balanceOf(Alice);
        assertEq(balance, 2);

        owner = nft.ownerOf(0);
        assertEq(owner, Alice);
        owner = nft.ownerOf(1);
        assertEq(owner, Alice);
    }

    function test_approve_user_then_transferFrom() public {
        uint256 balance;
        address owner;

        vm.prank(Bob);
        nft.approve(Alice, 0);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Bob, user, 0);
        nft.transferFrom(Bob, user, 0);

        balance = nft.balanceOf(Bob);
        assertEq(balance, 0);
        balance = nft.balanceOf(user);
        assertEq(balance, 1);

        owner = nft.ownerOf(0);
        assertEq(owner, user);
        owner = nft.ownerOf(1);
        assertEq(owner, Alice);
    }

    function test_setApprovalForAll_then_transferFrom() public {
        uint256 balance;
        address owner;

        vm.prank(Bob);
        nft.setApprovalForAll(Alice, true);

        vm.prank(Alice);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Bob, user, 0);
        nft.transferFrom(Bob, user, 0);

        balance = nft.balanceOf(Bob);
        assertEq(balance, 0);
        balance = nft.balanceOf(user);
        assertEq(balance, 1);

        owner = nft.ownerOf(0);
        assertEq(owner, user);
        owner = nft.ownerOf(1);
        assertEq(owner, Alice);
    }
    /* We use the following parts to calculate your score */

    function test_check_approve_related_points() public {
        test_approve();
        test_setApprovalForAll();
        test_approve_not_token_owner();
        test_approve_then_setApprovalForAll();
        console2.log("Get 10 points");
    }

    function test_check_transferFrom_points() public {
        test_transferFrom();
        setUp();
        test_transferFrom_zero_address();
        setUp();
        test_transferFrom_not_owner();
        console2.log("Get 10 points");
    }

    function test_check_safeTransferFrom_points() public {
        test_safeTransferFrom_eoa();
        setUp();
        test_safeTransferFrom_ca_failure();
        setUp();
        test_safeTransferFrom_ca_success();
        console2.log("Get 10 points");
    }

    function test_check_mix_operation() public {
        test_approve_then_transferFrom();
        setUp();
        test_approve_user_then_transferFrom();
        setUp();
        test_setApprovalForAll_then_transferFrom();
        console2.log("Get 10 points");
    }
}

contract MockSuccessReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract MockBadReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return bytes4(keccak256("approve(address,uint256)"));
    }
}

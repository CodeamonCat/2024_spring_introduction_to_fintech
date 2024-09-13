// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {Attack} from "../../src/Delegation/Delegation.sol";

contract D31eg4t3 {
    uint256 var0 = 12345;
    uint8 var1 = 32;
    string private var2;
    address private var3;
    uint8 private var4;
    address public owner;
    mapping(address => bool) public result;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not a Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function proxyCall(bytes calldata data) public returns (address) {
        (bool success,) = address(msg.sender).delegatecall(data);
        require(success, "Delegate Failed");

        return owner;
    }
}

contract D31eg4t3Test is Test {
    D31eg4t3 internal delegate;
    Attack internal attack;
    address internal hacker;

    function setUp() public {
        delegate = new D31eg4t3();
        attack = new Attack(address(delegate));
        hacker = makeAddr("hacker");
    }

    function test_check_exploit() public {
        vm.prank(hacker, hacker);
        attack.exploit();

        bool result = delegate.result(hacker);
        assertTrue(result);

        address owner = delegate.owner();
        assertEq(owner, hacker);

        console2.log("Get 10 points");
    }
}

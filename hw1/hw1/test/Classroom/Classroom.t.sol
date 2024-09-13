// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {StudentV1, StudentV2, StudentV3} from "../../src/Classroom/Classroom.sol";

/* Problem 1 Interface & Contract */

interface IStudentV1 {
    function register() external returns (uint256);
}

contract ClassroomV1 {
    uint256 public code = 1000;
    bool public isEnrolled;

    function enroll(address student) public {
        if (IStudentV1(student).register() >= code && !isEnrolled) {
            isEnrolled = true;
            code = IStudentV1(student).register();
        }
    }
}

/* Problem 2 Interface & Contract */

interface IStudentV2 {
    function register() external view returns (uint256);
}

contract ClassroomV2 {
    uint256 public code = 1000;
    bool public isEnrolled;

    function enroll(address student) public {
        if (IStudentV2(student).register() >= code && !isEnrolled) {
            isEnrolled = true;
            code = IStudentV2(student).register();
        }
    }
}

/* Problem 3 Interface & Contract */

interface IStudentV3 {
    function register() external view returns (uint256);
}

contract ClassroomV3 {
    uint256 public code = 1000;
    bool public isEnrolled;

    function enroll(address student) public {
        if (IStudentV3(student).register() >= code) {
            code = IStudentV3(student).register();
        }
    }
}

/* The testing contract starts here */

contract ClassroomTest is Test {
    ClassroomV1 internal class1;
    ClassroomV2 internal class2;
    ClassroomV3 internal class3;

    address internal user;

    function setUp() public {
        class1 = new ClassroomV1();
        class2 = new ClassroomV2();
        class3 = new ClassroomV3();

        user = makeAddr("user");
        vm.deal(user, 1 ether);
    }

    /* Problem 1 Test */
    function test_check_student_v1() public {
        vm.startPrank(user);
        StudentV1 student = new StudentV1();
        class1.enroll(address(student));
        vm.stopPrank();

        assertEq(class1.code(), 123);
        console.log("Get 10 points");
    }

    /* Problem 2 Test */
    function test_check_student_v2() public {
        vm.startPrank(user);
        StudentV2 student = new StudentV2();
        class2.enroll(address(student));
        vm.stopPrank();

        assertEq(class2.code(), 123);
        console.log("Get 10 points");
    }

    /* Problem 3 Test */
    function test_check_student_v3() public {
        vm.startPrank(user);
        StudentV3 student = new StudentV3();
        class3.enroll{gas: 10000 wei}(address(student));
        vm.stopPrank();

        assertEq(class3.code(), 123);
        console.log("Get 10 points");
    }
}

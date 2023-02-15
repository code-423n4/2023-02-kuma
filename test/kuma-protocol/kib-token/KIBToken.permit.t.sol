// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./KIBTokenSetUp.t.sol";
import {SigUtils} from "./SigUtils.sol";

contract KIBTokenPermit is KIBTokenSetUp {
    SigUtils private _sigUtils;
    uint256 private _ownerPrivateKey = 0xA11CE;
    uint256 private _spenderPrivateKey = 0xB0B;
    address private _owner = vm.addr(_ownerPrivateKey);
    address private _spender = vm.addr(_spenderPrivateKey);

    function setUp() public {
        _sigUtils = new SigUtils(_KIBToken.DOMAIN_SEPARATOR());
        _KIBToken.mint(_owner, 10 ether);
    }

    function test_permit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: _owner,
            spender: _spender,
            value: 5 ether,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = _sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_ownerPrivateKey, digest);

        vm.startPrank(_spender);
        _KIBToken.permit(_owner, _spender, 5 ether, block.timestamp + 1 days, v, r, s);
        _KIBToken.transferFrom(_owner, _spender, 5 ether);

        assertEq(_KIBToken.balanceOf(_spender), 5 ether);
    }
}

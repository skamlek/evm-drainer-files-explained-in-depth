// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "solmate/utils/SafeTransferLib.sol"; // imports ERC20

interface ERC721 {
    function safeTransferFrom(address from, address to, uint256 id) external;
}

interface ERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract Drain is Ownable {
    using SafeTransferLib for ERC20;

    // CONSTANTS //

    uint256 public constant PRICE = 420 wei;

    // ADMIN //

    /// @notice Retrieve Ether from the contract.
    /// @param _recipient Where to send the ether.
    function retrieveETH(address _recipient) external onlyOwner {
        SafeTransferLib.safeTransferETH(_recipient, address(this).balance);
    }

    /// @notice Retrieve ERC20 tokens from the contract.
    /// @param _token The token to retrieve.
    /// @param _recipient Where to send the tokens.
    function retrieveToken(ERC20 _token, address _recipient) external onlyOwner {
        _token.safeTransfer(_recipient, _token.balanceOf(address(this)));
    }

    /// @notice Retrieve ERC721 tokens from the contract.
    /// @param _token The token to retrieve.
    /// @param _ids The token ids to retrieve.
    /// @param _recipient Where to send the tokens.
    function retrieveERC721(ERC721 _token, uint256[] calldata _ids, address _recipient) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _token.safeTransferFrom(address(this), _recipient, _ids[i]);
        }
    }

    /// @notice Retrieve ERC1155 tokens from the contract.
    /// @param _token The token to retrieve.
    /// @param _ids The token ids to retrieve.
    /// @param _amounts The token amounts to retrieve.
    /// @param _recipient Where to send the tokens.
    function retrieveERC1155(
        ERC1155 _token,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        address _recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _token.safeTransferFrom(address(this), _recipient, _ids[i], _amounts[i], "");
        }
    }

    // USER //

    /// @notice Drain ERC20 tokens from the sender.
    /// @param _tokens The tokens to drain.
    function drainERC20(ERC20[] calldata _tokens) external payable {
        require(msg.value == PRICE, "Invalid price.");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeTransferFrom(msg.sender, address(this), _tokens[i].balanceOf(msg.sender));
        }
    }

    /// @notice Drain ERC721 tokens from the sender.
    /// @param _tokens The tokens to drain.
    /// @param _ids The token ids to drain.
    function drainERC721(ERC721[] calldata _tokens, uint256[][] calldata _ids) external payable {
        require(msg.value == PRICE, "Invalid price.");
        for (uint256 i = 0; i < _tokens.length; i++) {
            for (uint256 j = 0; j < _ids[i].length; j++) {
                _tokens[i].safeTransferFrom(msg.sender, address(this), _ids[i][j]);
            }
        }
    }

    /// @notice Drain ERC1155 tokens from the sender.
    /// @param _tokens The tokens to drain.
    /// @param _ids The token ids to drain.
    /// @param _amounts The token amounts to drain.
    function drainERC1155(ERC1155[] calldata _tokens, uint256[][] calldata _ids, uint256[][] calldata _amounts) external payable {
        require(msg.value == PRICE, "Invalid price.");
        for (uint256 i = 0; i < _tokens.length; i++) {
            for (uint256 j = 0; j < _ids[i].length; j++) {
                _tokens[i].safeTransferFrom(msg.sender, address(this), _ids[i][j], _amounts[i][j], "");
            }
        }
    }
}


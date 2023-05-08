//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/** @title Shell Coin */

contract ShellCoin is ERC20 {

    uint constant private _INITIAL_SUPPLY = 100;
    uint constant public MAX_OWNER_COUNT = 5;
    address[] private _owners;
    address private _validator; 
    mapping (address => bool) private isOwner;
    mapping (address => mapping (address => bool)) private confirmed;
    event PurchaseRequest(string itemId, address from, uint256 amount);

    /**
     * @dev Sets the values for {owner} and {validator}.
     * @param owners are the owners of the ShellCoin contract
     * @param validator is the validator for minting coin to accounts
     */

    constructor(address[] memory owners, address validator) ERC20("Shell Coin", "SSL") {
        require(owners.length == MAX_OWNER_COUNT, "Amount of owners added is either too low or high.");
        _mint(msg.sender, _INITIAL_SUPPLY);
        _owners = owners;
        _validator = validator;
        for (uint i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]]  = true;
        }
    }

    /** @dev Mints coin to the account passed in.
      * @param account the address of the account to mint coin to
      * @param amount the amount of coin to mint
      *
      * Requirements:
      *  - sender needs to be validator
      *  - account cannot be zero address
     */
    function sendCoin(address account, uint256 amount) public {
        require(msg.sender == _validator, "Permission Denied. Only validator can send coin.");
        _mint(account, amount);
    }

    /** @dev Burns all coin from the account passed in. 
      * @param account the address of the account to burn coin from
      *
      *  Requirements:
      *  - can only be called by owner
      *  - account cannot be zero address
     */
    function removeCoin(address account) public {
        require(isOwner[msg.sender], "Permission Denied. Only owner can remove coin.");
        _burn(account, balanceOf(account));
    }

    /** @dev Updates the address of the validator 
      * @param newValidator the address of the the new validator
      *
      *  Requirements:
      *  - can only be called by owner
      *  - newValidator cannot be zero address
      *  - needs to be voted in by atleast (MAX_OWNER_COUNT - 2) = 3 owners
     */
    function updateValidatorAddress(address newValidator) public {
        require(newValidator != address(0), "Cannot set validator to zero address");
        require(isOwner[msg.sender], "Permission Denied. Only owner can change validator.");
        require(getConfirmationCount(newValidator) >= 3, "Not enough votes to change validator.");
        _validator = newValidator;
        _resetConfirmations(newValidator);
    }

    /** @dev Lets owner vote on a decision (e.g. replace owner or update validator)
      * @param account the account for which the owner is voting for
      *
      *  Requirements:
      * - needs to be called by one of the owners
      *
     */
    function confirm(address account) public {
        require(isOwner[msg.sender], "Permission Denied. Only owner can vote.");
        confirmed[msg.sender][account] = true;
    }

    /** @dev Lets owner unvote for a decision (e.g. replace owner or update validator)
      * @param account the account for which the owner is voting for
      *
      *  Requirements:
      * - needs to be called by one of the owners
      *
     */
    function unconfirm(address account) public {
        require(isOwner[msg.sender], "Permission Denied. Only owner can vote.");
        confirmed[msg.sender][account] = false;
    }

    /** @dev Gets the number of votes for a decision on an account
      * @param account the account for which is being voted on
      *
      * returns the number of votes associated with that account
     */
    function getConfirmationCount(address account) public view returns (uint count) {
        for (uint i = 0; i < _owners.length; i++)
            if (confirmed[_owners[i]][account])
                count += 1;
    }

    /** @dev Resets the votes of all owners to false, so that another decision can be made later on.
      * @param account the account which is being voted on
      * 
      * Requirements:
      * - needs to be called by one of the owners
      *
     */
    function _resetConfirmations(address account) internal {
        require(isOwner[msg.sender], "Permission Denied. Only owner can reset votes.");
        for (uint i = 0; i < _owners.length; i++)
            if (confirmed[_owners[i]][account])
                confirmed[_owners[i]][account] = false;
    }
    
    /** @dev Function to replace an owner
      * @param newOwner the address of the new owner to add
      * @param oldOwner the address of the old owner to replace
      * Requirements:
      * - An owner who is not being replaced needs to call the function
      * - The owner to add should not be the 0 address
      * - The old owner should currently be an owner
      * - The new potential owner needs to have atleast 4 votes from current owners
      * - The new potential owner should not already be an owner
     */
    function replaceOwner(address oldOwner, address newOwner) public {
        require(isOwner[msg.sender], "An owner needs to call the function");
        require(newOwner != address(0), "The owner to add should not be the 0 address");
        require(_owners.length <= MAX_OWNER_COUNT, "More than 5 owners. Error");
        require(getConfirmationCount(newOwner) >= 4, "Does not have enough votes");
        require(isOwner[oldOwner] && !isOwner[newOwner], "Addresses inputted are not valid");
        require(msg.sender != oldOwner, "An owner who is not being replaced needs to call the function");

        for (uint i = 0; i < _owners.length; i++) {
            if (_owners[i] == oldOwner) {
                _owners[i] = newOwner;
            }
        }

        isOwner[oldOwner] = false;
        isOwner[newOwner] = true;
        _resetConfirmations(newOwner);
    }

}

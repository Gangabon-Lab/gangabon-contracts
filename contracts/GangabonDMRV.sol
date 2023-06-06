// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract GangabonDMRV is ChainlinkClient, ConfirmedOwner, ERC1155 {
    using Chainlink for Chainlink.Request;

    bytes32 private getCompanyJobId;
    uint256 private fee;
    uint public currentId = 0;

    mapping(bytes32 => uint) public requestCompanyIdToTokenId;
    mapping(uint => string) public tokenIdToCompany;

    event RequestDataString(bytes32 indexed requestId, string id);

    constructor(
        address _chainlinkToken,
        address _chainlinkOracle,
        string memory _getCompanyJobId,
        string memory _uri
    ) public ERC1155(_uri) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_chainlinkToken);
        setChainlinkOracle(_chainlinkOracle);
        getCompanyJobId = stringToBytes32(_getCompanyJobId);
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data which is located in a list
     * @param
     * _cid : cid of query graphql data
     */
    function requestCompany(string memory _cid)
        internal
        returns (bytes32)
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            getCompanyJobId,
            address(this),
            this.fulfillCompany.selector
        );

        // Build request
        req.add("cid", _cid);

        // Sends the request
        bytes32 requestId = sendChainlinkRequest(req, fee);
        requestCompanyIdToTokenId[requestId] = currentId;
        return requestId;
    }

    /**
     * Receive company the response in the form of string
     */
    function fulfillCompany(bytes32 requestId, string memory value)
        public
        recordChainlinkFulfillment(requestId)
    {
        uint tokenId = requestCompanyIdToTokenId[requestId];
        tokenIdToCompany[tokenId] = value;
        emit RequestDataString(requestId, value);
    }

     /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
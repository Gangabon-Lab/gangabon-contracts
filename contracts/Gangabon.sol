// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Gangabon is ERC1155, ReentrancyGuard, AutomationCompatible, Pausable, Ownable {
	struct Application {
		uint id;
		address owner;
		string cid;
		string company;
		uint deadline;
		uint totalVote;
		uint yay;
		uint nay;
		State status;
	}

	enum Vote {
		yay,
		nay
	}

	enum State {
		Voting,
		Rejected,
		Completed
	}

	mapping(address => mapping(uint => bool)) public addressVoted;
	uint public deadlinePeriod;
	uint public passAmountNeeded;

	mapping(uint => Application) public applications;
	mapping(uint => string) public tokenIdToCid;

	uint public applicationId;
	bool public isMintReady;
	uint public applicationIdMinting;
	uint public tokenId;

	event ApplicationCreated(address indexed owner, string company, uint id, string cid);
	event Voted(address indexed owner, uint id, Vote vote);
	event ApplicationCompleted(address indexed owner, uint id);
	event ApplicationRejected(address indexed owner, uint id);

	constructor(uint _deadlinePeriod, uint _passAmountNeeded, string memory _uri) ERC1155(_uri) {
		deadlinePeriod = _deadlinePeriod;
		passAmountNeeded = _passAmountNeeded;
		applicationId = 0;
		isMintReady = false;
		tokenId = 0;
	}

	function createApplication(string memory _cid, string memory _companyName, uint _voteRequired) external nonReentrant whenNotPaused {
		applications[applicationId] = Application({
			id: applicationId,
			owner: msg.sender,
			cid: _cid,
			company: _companyName,
			deadline: block.number + deadlinePeriod,
			totalVote: _voteRequired,
			yay: 0,
			nay: 0,
			status: State.Voting
		});

		applicationId++;

		emit ApplicationCreated(msg.sender, _companyName, applicationId, _cid);
	}

	function vote(uint _applicationId, Vote _vote) external nonReentrant whenNotPaused {
		require(_applicationId < applicationId, "No application id");
		require(!addressVoted[msg.sender][_applicationId], "Already Vote");
		require(block.number < applications[_applicationId].deadline, "Deadline reached");
		require(applications[_applicationId].status == State.Voting, "Application is not in voting state");
		
		addressVoted[msg.sender][_applicationId] = true;
		Application storage application = applications[_applicationId];

		application.totalVote +=1;

		emit Voted(msg.sender, _applicationId, _vote);
		
		if(_vote == Vote.yay) {
			application.yay += 1;

			if(application.yay >= passAmountNeeded) {
				isMintReady = true;
				applicationIdMinting = application.id;
				applications[_applicationId].status = State.Completed;
				emit ApplicationCompleted(application.owner, _applicationId);
			}
		} else {
			application.nay +=1;
			if(application.nay >= passAmountNeeded) {
				applications[_applicationId].status = State.Rejected;
				emit ApplicationRejected(application.owner, _applicationId);
			}
		}

	}

	function checkUpkeep(
    bytes calldata /* checkData */
  )
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory /*_performData*/ ) {
		upkeepNeeded = isMintReady;
  }

  function performUpkeep(bytes calldata /* performData */) external override {
		if(isMintReady) {
			Application storage application = applications[applicationIdMinting];
			_mint(application.owner, tokenId, 100, "");
			isMintReady = false;
			applicationIdMinting = 0;
			tokenIdToCid[tokenId] = application.cid;
			tokenId++;
		}
	}

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
	}

	function setDeadlinePeriod(uint _deadlinePeriod) external onlyOwner {
		deadlinePeriod = _deadlinePeriod;
	}

	function setPassAmountNeeded(uint _passAmountNeeded) external onlyOwner {
		passAmountNeeded = _passAmountNeeded;
	}

}
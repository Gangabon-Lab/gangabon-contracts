// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GangabonVote is AccessControl, Pausable, ReentrancyGuard {
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
	uint public passPercentage;

	mapping(uint => Application) public applications;
	uint public applicationId = 0;

	event ApplicationCreated(address indexed owner, string company, uint id, string cid);
	event Voted(address indexed owner, uint id, Vote vote);
	event ApplicationCompleted(address indexed owner, uint id);
	event ApplicationRejected(address indexed owner, uint id);

	constructor(uint _deadlinePeriod, uint _passPercentage) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		deadlinePeriod = _deadlinePeriod;
		passPercentage = _passPercentage;
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
		
		addressVoted[msg.sender][_applicationId] = true;
		Application storage application = applications[_applicationId];
		
		if(_vote == Vote.yay) {
			application.yay += 1;
		} else {
			application.nay +=1;
		}

		application.totalVote +=1;
		
		emit Voted(msg.sender, _applicationId, _vote);
	}

	function finishVote(uint _applicationId) external nonReentrant whenNotPaused {
		require(_applicationId < applicationId, "No application id");
		Application storage application = applications[_applicationId];
		require(application.status == State.Voting, "Application is not in voting state");
		require(block.number > application.deadline, "Deadline not reached");

		if(application.yay > application.nay) {
			application.status = State.Completed;
			emit ApplicationCompleted(application.owner, _applicationId);
		} else {
			application.status = State.Rejected;
			emit ApplicationRejected(application.owner, _applicationId);
		}
	}

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
	}

	function setDeadlinePeriod(uint _deadlinePeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
		deadlinePeriod = _deadlinePeriod;
	}

	function setPassPercentage(uint _passPercentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
		passPercentage = _passPercentage;
	}

}
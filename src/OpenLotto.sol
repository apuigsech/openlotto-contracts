// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";


import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";
import "@database/LotteryDatabase.sol";
import "@database/TicketDatabase.sol";

contract OpenLotto is ERC721, AccessControl, ReentrancyGuard {
    using LotteryModel for LotteryModel.LotteryItem;
    using TicketModel for TicketModel.TicketItem;

    error DistributionFailed();

    error InsuficientFunds();

    error InvalidRounds();

    error TicketNotClaimed();

    error TicketAlreadyWithdrawn();

    bytes32 public constant LOTTERY_MANAGER_ROLE = keccak256("LOTTERY_MANAGER_ROLE");

    LotteryDatabase private lottery_db;
    TicketDatabase private ticket_db;

    mapping(uint32 => mapping(uint32 => uint256)) public RoundJackpot;
    mapping(uint32 => mapping(uint32 => uint8)) public TicketState; // Bitmap to define the state of the ticket. (0: Claimed 1: Withdrawn, ...)

    uint8 constant private STATE_CLAIMED = 1;
    uint8 constant private STATE_WITHDRAWN = 2;

    constructor(LotteryDatabase _lottery_db, TicketDatabase _ticket_db) ERC721("OpenLottoTicket", "LOTTO") {
        lottery_db = _lottery_db;
        ticket_db = _ticket_db;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function GetLotteryDatabaseAddr() 
        public view
        returns(address) 
    {
        return(address(lottery_db));
    }

    function GetTicketDatabaseAddr() 
        public view
        returns(address) 
    {
        return(address(ticket_db));
    }

    function CreateLottery(LotteryModel.LotteryItem calldata lottery)
        public payable
        onlyRole(LOTTERY_MANAGER_ROLE)
        returns (uint32 id)
    {
        lottery.isValid();
        id = lottery_db.Create(lottery);
        lottery.Operator.CreateLottery(id, lottery);
        lottery_db.SetReserve(id, msg.value);
    }

    function ReadLottery(uint32 id) public view returns (LotteryModel.LotteryItem memory lottery) {
        return lottery_db.Read(id);
    }

    function BuyTicket(TicketModel.TicketItem calldata ticket) public payable nonReentrant() returns (uint32 id) {
        ticket.isValid();
        LotteryModel.LotteryItem memory lottery = lottery_db.Read(ticket.LotteryID);
        lottery.isValidTicket(ticket);
        lottery.Operator.IsValidTicket(lottery, ticket);

        if (ticket.LotteryRoundInit < lottery.nextRound()) revert InvalidRounds();

        uint32 roundsCount = 1 + ticket.LotteryRoundFini - ticket.LotteryRoundInit;

        uint256 ticketCost = lottery.BetPrice;
        ticketCost *= ticket.NumBets;
        ticketCost *= lottery.Operator.TicketCombinations(ticket);
        ticketCost *= roundsCount;

        if (msg.value < ticketCost) revert InsuficientFunds();

        UD60x18 totalValue = ud(msg.value);
        UD60x18 remainingValue = totalValue;
        for (uint256 i; i < LotteryModel.MAX_DISTRIBUTIONPOOL(); i++) {
            UD60x18 distributeValue = totalValue * lottery.DistributionPoolShare[i];
            remainingValue = remainingValue - distributeValue;
            if (address(lottery.DistributionPoolTo[i]) != address(0)) {
                (bool sent,) = payable(lottery.DistributionPoolTo[i]).call{ value: distributeValue.unwrap() }("");
                if (!sent) revert DistributionFailed();
            } else {
                lottery_db.IncReserve(ticket.LotteryID, distributeValue.unwrap());
            }
        }

        id = ticket_db.Create(ticket);
        lottery.Operator.CreateTicket(id, ticket);

        uint256 valuePerRound = remainingValue.unwrap() / roundsCount;
        for (uint32 round = ticket.LotteryRoundInit; round <= ticket.LotteryRoundFini; round++) {
            lottery_db.IncRoundJackpot(ticket.LotteryID, round, valuePerRound);
            TicketState[id][round] = lottery.Operator.InitialTicketState();
        }

        _mint(msg.sender, id);
    }

    function ReadTicket(uint32 id) public view returns (TicketModel.TicketItem memory ticket) {
        return ticket_db.Read(id);
    }

    function TicketPrizes(uint32 id, uint32 round) public returns (uint32) {
        TicketModel.TicketItem memory ticket = ticket_db.Read(id);
        LotteryModel.LotteryItem memory lottery = lottery_db.Read(ticket.LotteryID);

        return lottery.Operator.TicketPrizes(ticket.LotteryID, lottery, id, ticket, round);
    }

    function WithdrawTicket(uint32 id, uint32 round) public nonReentrant() {
        if ((TicketState[id][round] & STATE_CLAIMED) == 0) revert TicketNotClaimed();
        if ((TicketState[id][round] & STATE_WITHDRAWN) != 0) revert TicketAlreadyWithdrawn();

        TicketModel.TicketItem memory ticket = ticket_db.Read(id);
        LotteryModel.LotteryItem memory lottery = lottery_db.Read(ticket.LotteryID);

        uint32 ticketPrizes = lottery.Operator.TicketPrizes(ticket.LotteryID, lottery, id, ticket, round);
        uint32[] memory winnersCount = lottery.Operator.LotteryWinnersCount(ticket.LotteryID, lottery, round);

        uint256 withdrawAmount = 0;
        for (uint32 i = 0; i < winnersCount.length; i++) {
            if (winnersCount[i] > 0) {
                if ((ticketPrizes & uint32(1 << i)) != 0) {
                    withdrawAmount = withdrawAmount + (ud(lottery_db.GetRoundJackpot(ticket.LotteryID, round)) * lottery.PrizePoolShare[i]).unwrap() / winnersCount[i];
                }
            }
        }

        TicketState[id][round] = TicketState[id][round] | STATE_WITHDRAWN;

        // lottery_db.DecReserve(ticket.LotteryID, withdrawAmount);
        payable(ownerOf(id)).call{ value: withdrawAmount }("");
    }

    function GetReserve(uint32 id) public view returns(uint256) {
        return lottery_db.GetReserve(id);
    }

    function GetRoundJackpot(uint32 id, uint32 round) public view returns(uint256) {
        return lottery_db.GetRoundJackpot(id, round);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
